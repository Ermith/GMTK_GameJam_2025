shader_type spatial;

uniform float length = 1.0;
uniform float timeOverride = -1.0;
uniform float alphaMult = 1.0;
uniform float saturation = 1.0;
uniform float lengthOffset = 0.0;
uniform float headLength = 1.0;

float time() {
	if (timeOverride >= 0.0) {
		return timeOverride;
	}
	return TIME;
}

float rand(vec2 c){
	return fract(sin(dot(c.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

float noise(vec2 p, float freq ){
	float unit = 1.0 / freq;
	vec2 ij = floor(p/unit);
	vec2 xy = mod(p,unit)/unit;
	//xy = 3.*xy*xy-2.*xy*xy*xy;
	xy = .5*(1.-cos(PI*xy));
	float a = rand((ij+vec2(0.,0.)));
	float b = rand((ij+vec2(1.,0.)));
	float c = rand((ij+vec2(0.,1.)));
	float d = rand((ij+vec2(1.,1.)));
	float x1 = mix(a, b, xy.x);
	float x2 = mix(c, d, xy.x);
	return mix(x1, x2, xy.y);
}

void vertex() {
	vec2 uv = UV;
	uv.y = (uv.y - 0.25) / 0.5;
	float cpos = uv.x * length + lengthOffset;

	float rand = noise(VERTEX.xy, 0.1);
	float rand2 = noise(VERTEX.xy + vec2(134.54, 12.45), 0.05);

	VERTEX += NORMAL * (0.02 + sin(time() * (0.2 + 0.8 * rand) * 30.0) * (0.015 + 0.015 * rand2));
}

float smoothstep2( float x )
{
  return (x<0.5) ?
  2.0*x*x: 
  2.0*x*(2.0-x)-1.0;
}

vec4 base_color(vec2 uv) {
	float cpos = uv.x * length + lengthOffset;
	float sinarg = uv.y * 30.0 + sin(cpos * 5.0) * 15.0;
	float timefreq = noise(vec2(cpos, time()), 0.02);
	sinarg += noise(vec2(time() * 5.0 * timefreq, cpos) + vec2(45.78, 12.781), 0.1) * 50.0;
	float v = sin(sinarg);
	int lane = int((sinarg + PI / 2.0) / (2.0 * PI));
	float rand = noise(vec2(float(lane) * 10000.0 + time(), cpos), 0.1) +
		noise(vec2(float(lane) * 10000.0 + time(), cpos) + vec2(123.45, 98.545), 0.1 * 2.0) / 2.0 +
		noise(vec2(float(lane) * 10000.0 + time(), cpos) + vec2(543.21, 67.89), 0.1 * 4.0) / 4.0;
	rand /= 2.0;
	v = 0.5 + 0.5 * v;
	v = v * v * v;
	float distance_from_head = (length + lengthOffset) - cpos;
	float headfactor = smoothstep(0.0, 1.0, 1.0 - clamp(distance_from_head / headLength, 0.0, 1.0));
	rand = clamp(rand + headfactor, 0.0, 1.0);

	float dimming = pow(rand, 0.95);

	float pulse = 0.5 + sin(distance_from_head * 0.2 - time() * 5.0) * 0.5;
	pulse -= 0.01;
	pulse = clamp(pulse, 0.0, 1.0);
	pulse = pow(pulse, 50.0) * 0.5;
	dimming += pulse;

	dimming = clamp(dimming, 0.0, 1.0);
	v *= dimming;
	v = smoothstep2(v);
	v = smoothstep2(v);
	v = smoothstep2(v);

	v = clamp(v, 0.0, 1.0);
	vec3 pink = vec3(0.5, 0.2, 0.7);
	vec3 lightblue = vec3(0.0, 0.5, 1.0);
	vec3 darkpurple = vec3(0.3, 0.1, 0.4) * 0.3;
	vec3 col = mix(darkpurple, lightblue, v);
	// col = lightblue;
	// col *= sqrt(1.0 - pow((uv.y - 0.5) * 2.0, 2.0));
	col *= pow(uv.y * (1.0 - uv.y) * 4.0, 2.0);
	return vec4(col, v * 0.99 + 0.01);
}

void fragment() {
	vec2 uv = UV;
	uv.y = clamp((uv.y - 0.25) / 0.5, 0.0, 1.0);
	vec4 base_color = base_color(uv);
	vec3 color = mix(base_color.rgb, COLOR.rgb, COLOR.a);
	float avg = (color.r + color.g + color.b) / 3.0;
	color = mix(vec3(avg), color, saturation);
	EMISSION = color;
	ALBEDO = vec3(1, 1, 1);
	ALPHA = base_color.a * alphaMult;
}

