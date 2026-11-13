shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 belt_color : source_color = vec4(0.2, 0.7, 0.65, 1.0);
uniform float direction = 1.0;
void fragment() {
	vec2 uv = UV;
	float stripe = fract(uv.y * 12.0 + TIME * direction * 1.2 + abs(uv.x - 0.5) * 0.7);
	float arrow = step(0.72, stripe) * step(0.08, uv.x) * step(uv.x, 0.92);
	ALBEDO = mix(belt_color.rgb * 0.35, vec3(0.96, 0.88, 0.65), arrow);
}
