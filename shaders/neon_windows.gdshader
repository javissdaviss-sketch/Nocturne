shader_type spatial;
render_mode unshaded, shadows_disabled;
void fragment() {
 // Instance color keeps individual windows dim and varied, rather than white.
 vec2 edge = smoothstep(vec2(0.0), vec2(0.10), UV) * (vec2(1.0) - smoothstep(vec2(0.90), vec2(1.0), UV));
 float frame = edge.x * edge.y;
 float blinds = 0.86 + 0.14 * sin(UV.y * 62.83);
 ALBEDO = COLOR.rgb * frame * blinds;
}
