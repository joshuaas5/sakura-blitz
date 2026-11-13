shader_type spatial;
render_mode unshaded, cull_disabled;
void fragment() {
	vec2 p = UV * vec2(40.0, 3.55) * 2.8;
	vec2 diagonal = vec2(p.x + p.y, p.x - p.y);
	vec2 distance_to_wire = abs(fract(diagonal + 0.5) - 0.5);
	vec2 thickness = max(vec2(0.035), fwidth(diagonal) * 0.65);
	float wire = 1.0 - step(thickness.x, distance_to_wire.x) * step(thickness.y, distance_to_wire.y);
	ALBEDO = vec3(0.22, 0.37, 0.43);
	ALPHA = wire;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
