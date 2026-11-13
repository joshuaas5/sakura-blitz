shader_type spatial;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world_position.xz;
	vec2 cell = abs(fract(p * 4.0) - 0.5);
	float aa = max(length(fwidth(p)) * 4.0, 0.015);
	float seam = smoothstep(0.44 - aa, 0.48, max(cell.x, cell.y));
	float plate = 1.0 - smoothstep(0.02, 0.05, min(abs(fract(p.x / 2.0) - 0.5), abs(fract(p.y / 2.0) - 0.5)));
	ALBEDO = mix(vec3(0.25, 0.36, 0.40), vec3(0.14, 0.23, 0.28), seam * 0.42 + plate * 0.15);
	ROUGHNESS = 0.85;
}
