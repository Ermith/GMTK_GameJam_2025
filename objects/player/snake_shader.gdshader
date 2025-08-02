shader_type spatial;

void vertex() {

}

void fragment() {
	EMISSION = COLOR.rgb * 0.2;
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * 0.5;
}

