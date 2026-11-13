shader_type spatial;
varying vec3 world_pos;
void vertex() { world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment() {
	float bend = sin(world_pos.x * 0.15) * 0.35 + sin(world_pos.z * 0.22) * 0.18;
	float layer = sin((world_pos.y + bend) * 2.7) * 0.5 + 0.5;
	float vein = smoothstep(0.96, 0.995, layer) * 0.055;
	float sand = sin(world_pos.x * 7.7 + world_pos.z * 4.3) * sin(world_pos.y * 11.0) * 0.025;
	float fade = 1.0 - smoothstep(0.1, 1.0, length(fwidth(world_pos)));
	ALBEDO = mix(vec3(0.58, 0.34, 0.22), vec3(0.72, 0.46, 0.29), layer * 0.45 + 0.2) + vec3(vein + sand * fade);
	ROUGHNESS = 0.98;
	SPECULAR = 0.1;
}
