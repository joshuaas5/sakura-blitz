shader_type spatial;
render_mode cull_disabled;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float ripple = sin(world_position.x * 0.45 + TIME * 0.7) * sin(world_position.z * 0.7 - TIME * 0.5);
	float fade = 1.0 - smoothstep(0.1, 1.2, length(fwidth(world_position.xz)));
	ALBEDO = vec3(0.15, 0.39, 0.43) + vec3(0.055, 0.075, 0.07) * ripple * fade;
	ROUGHNESS = 0.36;
	METALLIC = 0.15;
}
