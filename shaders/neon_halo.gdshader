shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 neon_color : source_color = vec4(0.16, 0.68, 0.78, 1.0);
uniform float sign_phase = 0.0;
uniform vec2 frame_ratio = vec2(1.0);
uniform bool wall_reflection = false;

void fragment() {
 // Local halo around actual neon tubing, so Compatibility needs no screen glow.
 vec2 p = abs((UV - vec2(0.5)) * frame_ratio);
 vec2 frame = frame_ratio * 0.30;
 float distance_to_frame = abs(max(p.x - frame.x, p.y - frame.y));
 float halo = exp(-distance_to_frame * 27.0);
 float soft = exp(-distance_to_frame * 9.0) * 0.10;
 // Slow ballast variation instead of strobing or random flashes.
 float ballast = 0.93 + 0.045 * sin(TIME * 0.73 + sign_phase) + 0.025 * sin(TIME * 1.31 + sign_phase * 2.2);
 if (wall_reflection) {
  vec2 stretched = (UV - vec2(0.5)) * vec2(3.5, 2.4);
  float smear = exp(-dot(stretched, stretched) * 3.0);
  float streak = 0.6 + 0.4 * sin(UV.x * 110.0 + sin(UV.y * 12.0));
  halo = smear * streak * 0.20;
  soft = 0.0;
 }
 ALBEDO = neon_color.rgb * ballast;
 ALPHA = clamp((halo * 0.22 + soft) * neon_color.a, 0.0, 0.5);
}
