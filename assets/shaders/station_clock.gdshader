shader_type spatial;
render_mode unshaded, cull_disabled;
float segment(vec2 p, vec2 end) {
	float t = clamp(dot(p, end) / dot(end, end), 0.0, 1.0);
	return length(p - end * t);
}
void fragment() {
	vec2 p = (UV - 0.5) * vec2(2.0, -2.0);
	float radius = length(p);
	float angle = atan(p.x, p.y);
	float ticks = step(0.96, cos(angle * 12.0)) * step(0.72, radius) * (1.0 - step(0.85, radius));
	vec2 minute = vec2(sin(TIME * 0.018), cos(TIME * 0.018)) * 0.65;
	vec2 hour = vec2(sin(TIME * 0.0015 + 0.8), cos(TIME * 0.0015 + 0.8)) * 0.43;
	float hand = 1.0 - smoothstep(0.025, 0.04, min(segment(p, minute), segment(p, hour)));
	vec3 face = mix(vec3(0.91, 0.86, 0.69), vec3(0.24, 0.39, 0.41), max(hand, ticks));
	ALBEDO = mix(face, vec3(0.77, 0.57, 0.25), step(0.89, radius));
	ALPHA = 1.0 - step(0.99, radius);
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
