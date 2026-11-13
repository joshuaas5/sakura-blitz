shader_type spatial;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 cell = floor(world_position.xz * 28.0);
	float grain = fract(sin(dot(cell, vec2(12.9898, 78.233))) * 43758.5453);
	float fade = 1.0 - smoothstep(0.1, 0.7, length(fwidth(world_position.xz)));
	ALBEDO = vec3(0.11, 0.18, 0.22) * mix(1.0, mix(0.92, 1.06, grain), fade);
	ROUGHNESS = 0.96;
}
