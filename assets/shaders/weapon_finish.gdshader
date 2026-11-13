shader_type spatial;
uniform vec4 primary_color : source_color = vec4(0.2, 0.8, 0.7, 1.0);
uniform vec4 accent_color : source_color = vec4(0.9, 0.4, 0.6, 1.0);
uniform int finish = 0;
uniform sampler2D lacquer : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 local_position;
varying vec3 local_normal;

void vertex() {
	local_position = VERTEX;
	local_normal = NORMAL;
}

void fragment() {
	vec2 p = UV * 8.0;
	float pattern = 0.0;
	if (finish == 2) {
		vec2 cell = abs(fract(p) - 0.5);
		pattern = max(step(0.43, cell.x), step(0.43, cell.y)) * 0.65;
	} else if (finish == 3) {
		pattern = smoothstep(0.45, 0.8, sin(p.x * 2.0 + sin(p.y * 2.4)));
	} else if (finish == 4) {
		pattern = smoothstep(0.25, 0.8, sin(p.x + p.y * 0.7)) * 0.5;
	} else if (finish == 1) {
		pattern = step(0.92, fract((p.x + p.y) * 2.0)) * 0.18;
	}
	ALBEDO = mix(primary_color.rgb, accent_color.rgb, pattern);
	if (finish > 0) {
		vec3 weights = pow(abs(local_normal), vec3(6.0));
		weights /= max(dot(weights, vec3(1.0)), 0.001);
		vec3 p3 = local_position * 3.8;
		ALBEDO = texture(lacquer, p3.zy).rgb * weights.x
			+ texture(lacquer, p3.xz).rgb * weights.y
			+ texture(lacquer, p3.xy).rgb * weights.z;
		if (finish == 1) {
			float engraving = dot(ALBEDO, vec3(0.25, 0.5, 0.25));
			ALBEDO = mix(primary_color.rgb * 0.55, accent_color.rgb, engraving);
		} else if (finish == 3) {
			ALBEDO = mix(vec3(0.08, 0.025, 0.02), vec3(0.95, 0.43, 0.08), ALBEDO.r);
		}
	}
	METALLIC = finish == 1 ? 0.55 : 0.25;
	ROUGHNESS = finish == 1 ? 0.32 : 0.48;
	EMISSION = ALBEDO * 0.025;
}
