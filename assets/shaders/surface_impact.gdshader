shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 spark_color : source_color = vec4(1.0, 0.8, 0.5, 1.0);
uniform float age = 0.0;
void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float burst = (1.0 - smoothstep(0.82, 1.0, r)) * step(0.72, cos(a * 7.0 + r * 4.0));
	float flash = burst * (1.0 - smoothstep(0.02, 0.17, age)) + (1.0 - smoothstep(0.02, 0.22, r)) * (1.0 - smoothstep(0.02, 0.1, age));
	float mark = (1.0 - smoothstep(0.14, 0.25, r)) * (1.0 - smoothstep(6.0, 8.0, age));
	ALBEDO = mix(vec3(0.18, 0.17, 0.15), spark_color.rgb, min(1.0, flash * 3.0));
	ALPHA = max(mark * 0.9, flash);
	ALPHA_SCISSOR_THRESHOLD = 0.35;
}
