shader_type spatial;
// Retain painted texture detail while giving modular roofs a readable color family.
uniform sampler2D pigment_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 palette_color : source_color = vec4(1.0);
void fragment() {
	vec3 paint = texture(pigment_texture, UV).rgb;
	float detail = clamp(dot(paint, vec3(0.2126, 0.7152, 0.0722)) / 0.4, 0.55, 1.18);
	ALBEDO = mix(paint, palette_color.rgb * detail, 0.88);
	ROUGHNESS = 0.9;
	SPECULAR = 0.12;
}
