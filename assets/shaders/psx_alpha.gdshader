shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float emission = 0.0;
uniform bool use_vcol = false;
uniform sampler2DArray tex : filter_nearest, repeat_enable;
uniform int kind = -1;
uniform float tex_k = 1.0;
uniform float tiles = 0.5;

varying vec3 wpos;
varying vec3 wnrm;
varying float cam_dist;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 view_pos = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	cam_dist = length(view_pos);
}

void fragment() {
	vec3 n = normalize(wnrm);
	vec3 c = use_vcol ? COLOR.rgb * albedo.rgb : albedo.rgb;
	if (kind >= 0) {
		vec3 an = abs(n);
		bool lay = an.y >= an.x && an.y >= an.z;
		vec2 uv = lay ? wpos.xz : (an.x > an.z ? vec2(wpos.z, -wpos.y) : vec2(wpos.x, -wpos.y));
		float dist_fade = clamp(1.0 - (cam_dist - 8.0) / 38.0, 0.22, 1.0);
		float m = clamp(texture(tex, vec3(uv * tiles, float(kind))).r * 2.0, 0.82, 1.16);
		c *= mix(1.0, m, tex_k * dist_fade);
	}
	c += c * emission * 0.65;
	ALBEDO = clamp(c, vec3(0.0), vec3(1.35));
	ALPHA = albedo.a;
}
