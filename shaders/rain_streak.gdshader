shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

void fragment() {
 // Soft, thin precipitation streaks; no opaque particle rectangles.
 float across = 1.0 - smoothstep(0.0, 0.5, abs(UV.x - 0.5));
 float ends = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.55, 1.0, UV.y));
 ALBEDO = vec3(0.43, 0.64, 0.75);
 ALPHA = across * ends * 0.20;
}
