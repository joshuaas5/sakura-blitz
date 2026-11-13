shader_type spatial;
render_mode cull_disabled;
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap;
uniform vec4 low_color : source_color = vec4(0.62, 0.08, 0.25, 1.0);
uniform vec4 high_color : source_color = vec4(1.0, 0.45, 0.68, 1.0);
void fragment() {
	vec4 tex = texture(leaf_texture, UV);
	float lightness = dot(tex.rgb, vec3(0.30, 0.50, 0.20));
	ALBEDO = mix(low_color.rgb, high_color.rgb, clamp(lightness * 2.4, 0.0, 1.0));
	ROUGHNESS = 0.95;
	ALPHA = tex.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
}
