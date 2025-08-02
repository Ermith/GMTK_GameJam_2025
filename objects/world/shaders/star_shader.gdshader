shader_type spatial;

varying flat int id;

void vertex() {
	id = INSTANCE_ID;
	// Called for every vertex the material is visible on.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		MAIN_CAM_INV_VIEW_MATRIX[0],
		MAIN_CAM_INV_VIEW_MATRIX[1],
		MAIN_CAM_INV_VIEW_MATRIX[2],
		MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

// render_mode unshaded, cull_disabled;

uniform vec3 star_color : source_color = vec3(0.0, 0.5, 1.0);
uniform float cross_factor : hint_range(0.0, 100.0) = 40.0;
uniform float cross_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float mid_power : hint_range(0.0, 10.0) = 4.5;
uniform float glow_factor : hint_range(0.0, 10.0) = 0.5;
uniform float intensity : hint_range(0.0, 20.0) = 1.9;
uniform float mid_near_anim_factor : hint_range(0.0, 10.0) = 0.1;
uniform float intensity_anim_factor : hint_range(0.0, 10.0) = 0.4;
uniform float anim_speed_modifier : hint_range(0.0, 100.0) = 10.0;


float rand(vec2 st) {
	return fract(sin(dot(st.xy, vec2(1.0+12.9898,78.233))) * 43758.5453123);
}

// Called for every pixel the material is visible on.
void fragment() {
	float rnd = rand(NODE_POSITION_WORLD.xy);
	float anim_modifier = sin(TIME * anim_speed_modifier + rnd*PI);

	// Multiply by 2, since distance from top to mid is 0.5 -> we want [0,1] range
	// Then, we clamp, since distance from corner to mid is more than 0.5 -> would resuld in > 1.0
	float mid_dist = clamp(distance(UV, vec2(0.5)) * 2.0, 0.0, 1.0);
	float mid_near = 1.0 - mid_dist;
	float mid_near_power = pow(mid_near, mid_power) + anim_modifier * mid_near_anim_factor / 10.0;


	// Calculates distance from 0.5 and inverts it to 'nearness'. [1.0, 0.0]
	vec2 uv = vec2(1.0) - abs(vec2(0.5) - UV) * cross_factor / mid_near;
	float cross_shape = clamp(max(uv.x, uv.y), 0.0, 1.0);

	float shape = cross_shape * mid_near_power;
	float final_shape = mix(shape * cross_intensity, mid_near_power, mid_near_power*glow_factor);
	final_shape = clamp(final_shape, 0.0, 1.0);
	vec3 final_color = mix(star_color, vec3(1.0), final_shape);

	EMISSION = final_color * intensity + anim_modifier * intensity_anim_factor;

	//EMISSION = vec3(1.0);
	ALPHA = final_shape;
}