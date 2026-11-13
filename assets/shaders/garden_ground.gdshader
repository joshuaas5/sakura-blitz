shader_type spatial;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	vec2 p = world_position.xz;
	float longitudinal = min(abs(p.x), abs(abs(p.x) - 32.0));
	float crossing = min(abs(p.y), abs(abs(p.y) - 24.0));
	float path = 1.0 - smoothstep(3.0, 3.3, min(longitudinal, crossing));
	float grain = fract(sin(dot(floor(p * 9.0), vec2(12.9898, 78.233))) * 43758.5453);
	float near = 1.0 - smoothstep(0.1, 0.8, length(fwidth(p)));
	vec2 tile = abs(fract(vec2(p.x + floor(p.y * 1.4) * 0.35, p.y) * 1.4) - 0.5);
	float seam = smoothstep(0.43, 0.49, max(tile.x, tile.y)) * near;
	ALBEDO = mix(vec3(0.31, 0.46, 0.28), mix(vec3(0.72, 0.67, 0.50), vec3(0.61, 0.59, 0.45), seam * 0.5), path) * mix(1.0, 0.95 + grain * 0.1, near);
	ROUGHNESS = 0.95;
}
