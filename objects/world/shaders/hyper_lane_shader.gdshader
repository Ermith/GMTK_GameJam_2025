shader_type spatial;

uniform vec4 color: source_color = vec4(0.5, 0.5, 1.0, 0.3);
uniform vec4 color2: source_color = vec4(0.5, 0.5, 1.0, 0.3);
uniform vec4 color_override: source_color = vec4(1.0, 0.0, 0.0, 0.0);
uniform float intensity: hint_range(0.0, 10.0) = 1.0;
uniform float width_factor: hint_range(0.0, 100.0) = 20.0;

void vertex() {
	// Object position
	vec3 obj_pos = MODEL_MATRIX[3].xyz;

	// Camera position
	vec3 cam_pos = (MAIN_CAM_INV_VIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;

	// Object's current up direction (in world space)
	vec3 up = normalize((MODEL_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz); // or any other vector you define

	// Direction from object to camera
	vec3 to_cam = cam_pos - obj_pos;

	// Project to_cam onto plane perpendicular to up (removes vertical component relative to up)
	vec3 forward = normalize(to_cam - up * dot(to_cam, up));

	// Compute right vector
	vec3 right = normalize(cross(up, forward));

	// Build rotation matrix
	mat4 rot = mat4(
	    vec4(right, 0.0),
	    vec4(up, 0.0),
	    vec4(forward, 0.0),
	    vec4(0.0, 0.0, 0.0, 1.0)
	);

	// Apply the billboard rotation to the object
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
	    rot[0],
	    rot[1],
	    rot[2],
	    MODEL_MATRIX[3] // keep original position
	);

	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
uniform vec3 tube_axis = vec3(1.0, 0.0, 0.0);
vec3 project_onto_plane(vec3 v, vec3 plane_normal) {
    return normalize(v - dot(v, plane_normal) * plane_normal);
}

// Called for every pixel the material is visible on.
void fragment() {
	float t = clamp(UV.y + 0.69, 0.0, 1.0);
	vec4 mixed = mix(color, color2, pow(t, 10.0));
	EMISSION = mixed.rgb * intensity; // glow effect
	EMISSION = mix(EMISSION, color_override.rgb, color_override.a);
	ALPHA = pow(distance(UV.x, 0.5) * 2.0, width_factor);
	float dist_from_end = min(UV.y, 0.5 - UV.y) / 0.5;
	ALPHA *= smoothstep(0.0, 1.0, dist_from_end * 4.0); // fade out towards the ends
	ALPHA *= mixed.a;
}