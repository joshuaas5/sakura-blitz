shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth : source_color = vec4(0.3, 0.5, 0.4, 1.0);
uniform vec4 ink : source_color = vec4(0.96, 0.85, 0.63, 1.0);
uniform bool solar = false;
void vertex() {
    VERTEX.z += sin(TIME * 1.4 + UV.y * 4.0) * 0.035 * UV.y;
}
void fragment() {
    vec2 p = (UV - 0.5) * vec2(1.0, 1.5);
    if (UV.y > 0.92 + abs(UV.x - 0.5) * 0.16) discard;
    float edge = step(UV.x, 0.045) + step(0.955, UV.x);
    float trim = step(abs(UV.y - 0.12), 0.012) + step(abs(UV.y - 0.86), 0.012);
    float emblem;
    if (solar) {
        float radius = length(p);
        float ray = step(0.45, cos(atan(p.y, p.x) * 12.0));
        emblem = 1.0 - smoothstep(0.14, 0.15, radius);
        emblem += ray * step(0.19, radius) * (1.0 - step(0.28, radius));
    } else {
        vec2 a = mat2(vec2(0.8, -0.6), vec2(0.6, 0.8)) * (p - vec2(-0.08, 0.01));
        vec2 b = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * (p - vec2(0.08, -0.13));
        float leaves = min(length(a / vec2(0.11, 0.22)), length(b / vec2(0.10, 0.18)));
        emblem = 1.0 - smoothstep(0.92, 1.0, leaves);
        emblem = max(emblem, (1.0 - step(0.014, abs(p.x))) * step(-0.32, p.y) * step(p.y, 0.18));
    }
    float weave = sin(UV.x * 170.0) * sin(UV.y * 240.0) * 0.018;
    ALBEDO = mix(cloth.rgb * (0.98 + weave), ink.rgb, clamp(edge + trim + emblem, 0.0, 1.0));
    ROUGHNESS = 0.95;
}
