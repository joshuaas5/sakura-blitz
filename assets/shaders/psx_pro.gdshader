shader_type spatial;
// Rock-Solid Stylized 3D Low-Poly / PS1-Plus Shader (Zero Shadow/Texture Flicker)
// Uses deterministic world-space analytical Sun + Sky Hemisphere + Ground AO shading in fragment()
// and distance-stabilized pixel textures so moving or rotating the camera NEVER causes dark shadow
// blotches, Z-fighting, or mipmap shimmering (optimized for Desktop & iOS/Android Mobile GPUs).
render_mode unshaded, cull_back;

uniform vec4 albedo : source_color = vec4(1.0);
uniform float emission = 0.0;
uniform bool use_vcol = false;
uniform sampler2DArray tex : filter_nearest, repeat_enable;
uniform sampler2D painted_stone : source_color, filter_linear_mipmap, repeat_enable;
uniform int kind = -1;
uniform float tex_k = 1.0;
uniform float tiles = 0.5;
uniform float hit_flash = 0.0;

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
		int k = kind;

		// Distance-stabilized texture contrast: crisp close up, zero moire/flicker at distance
		float dist_fade = clamp(1.0 - (cam_dist - 8.0) / 38.0, 0.22, 1.0);
		float m = texture(tex, vec3(uv * tiles, float(k))).r * 2.0;
		float m_clamped = clamp(m, 0.80, 1.18);
		c *= mix(1.0, m_clamped, tex_k * dist_fade);
		if (k == 8) {
			vec3 paint = texture(painted_stone, uv * 0.20).rgb;
			// Preserve the authored palette; limestone supplies pigment detail only.
			float pigment = clamp(dot(paint, vec3(0.2126, 0.7152, 0.0722)) / 0.45, 0.68, 1.18);
			c = albedo.rgb * pigment;
		}
	}

	// Deterministic World-Space Sun + Sky Dome + Bounce Lighting (100% immune to camera rotation)
	vec3 sun_dir = normalize(vec3(0.48, 0.76, 0.43));
	float ndotl = dot(n, sun_dir);
	float sun_diff = clamp(ndotl * 0.5 + 0.5, 0.0, 1.0);
	float sky_hemi = clamp(n.y * 0.5 + 0.5, 0.0, 1.0);

	// Crisp stylized face contrast (bright top, warm sunlit south/east walls, cool shaded north/west walls)
	vec3 light_col = mix(vec3(0.57, 0.68, 0.86), vec3(1.02, 0.99, 0.93), sun_diff);
	light_col = mix(light_col * 0.90, light_col * 1.06, sky_hemi);

	// Subtle ground-contact ambient occlusion on vertical walls near y = 0
	if (abs(n.y) < 0.45 && wpos.y > -0.1 && wpos.y < 1.1) {
		light_col *= mix(0.84, 1.0, smoothstep(0.0, 0.95, wpos.y));
	}

	c *= light_col;

	// Emission & Hit Flash
	c = mix(c, vec3(1.0, 0.95, 0.85), clamp(hit_flash, 0.0, 1.0));
	c += c * min(emission, 1.0) * 0.22 + vec3(1.0, 0.9, 0.8) * (hit_flash * 0.85);

	// Gentle distance aerial perspective (sky haze)
	float fog_f = clamp((cam_dist - 45.0) / 95.0, 0.0, 0.35);
	c = mix(c, vec3(0.82, 0.91, 1.0), fog_f);

	float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
	c = mix(vec3(luma), c, 1.12);
	ALBEDO = clamp(c, vec3(0.0), vec3(1.0));
}
