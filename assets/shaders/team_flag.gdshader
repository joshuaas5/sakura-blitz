shader_type spatial;
render_mode cull_disabled;
uniform vec4 team_color : source_color = vec4(0.57, 0.90, 0.76, 1.0);
void vertex() { VERTEX.z += sin(UV.x * 7.0 - TIME * 3.0) * UV.x * 0.12; }
void fragment() {
	float emblem = 1.0 - smoothstep(0.16, 0.18, abs(UV.x - 0.45) + abs(UV.y - 0.5));
	ALBEDO = mix(team_color.rgb, vec3(0.94, 0.89, 0.73), emblem);
	ROUGHNESS = 0.95;
}
