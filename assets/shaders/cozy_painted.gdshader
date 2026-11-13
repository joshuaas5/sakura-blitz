shader_type spatial;
render_mode unshaded;
varying vec3 local_position;
varying vec3 world_normal;
void vertex() {
	local_position = VERTEX;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}
void fragment() {
	vec3 n = normalize(world_normal);
	float light = dot(n, normalize(vec3(-0.4,0.8,0.6))) * 0.5 + 0.5;
	vec3 shade = mix(vec3(0.64,0.68,0.78), vec3(1.05,1.0,0.88), light);
	// Stable pigment variation in object space; no screen-space shimmer.
	vec3 p = floor(local_position * 24.0);
	float grain = fract(sin(dot(p,vec3(12.9898,78.233,37.719))) * 43758.5453);
	float pigment = mix(0.98,1.02,grain);
	ALBEDO = COLOR.rgb * shade * pigment;
}
