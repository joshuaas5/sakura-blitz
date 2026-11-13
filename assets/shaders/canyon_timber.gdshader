shader_type spatial;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float width = max(fwidth(world_pos.z) * 3.8, 0.015);
	float seam = 1.0 - smoothstep(0.025, 0.025 + width, abs(fract(world_pos.z * 3.8) - 0.5));
	float grain = sin(world_pos.x * 15.0 + sin(world_pos.z * 2.3)) * 0.025;
	ALBEDO = mix(vec3(0.44, 0.31, 0.20) + vec3(grain), vec3(0.25, 0.20, 0.15), seam * 0.7);
	ROUGHNESS = 0.9;
}
