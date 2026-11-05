shader_type spatial;
render_mode unshaded, shadows_disabled;
void fragment() {
 // Real framed openings supply the geometry. Here, stable per-window variation
 // suggests curtains, partly lowered blinds and lit rooms behind the wet glass.
 float seed = COLOR.a * 73.17;
 float edge = min(min(UV.x,1.0-UV.x),min(UV.y,1.0-UV.y));
 float reveal = mix(0.30,1.0,smoothstep(0.0,0.035,edge));
 float detail = 0.88-0.28*length(UV-vec2(0.5,0.58));
 if (fract(seed) > 0.43) {
  float curtains = 1.0-smoothstep(0.10,0.25,UV.x)+smoothstep(0.76,0.93,UV.x);
  float folds = sin(UV.x*80.0+seed);
  folds *= 1.0-smoothstep(0.4,1.2,fwidth(UV.x)*80.0);
  detail *= mix(1.0,0.48+0.10*folds,curtains);
 } else {
  float lowered_to = 0.28+fract(seed*3.1)*0.45;
  float blind = 1.0-smoothstep(lowered_to-0.015,lowered_to+0.015,UV.y);
  float slats = sin(UV.y*113.1);
  slats *= 1.0-smoothstep(0.4,1.2,fwidth(UV.y)*113.1);
  detail *= mix(1.0,0.57+0.10*slats,blind);
 }
 vec3 room = COLOR.rgb*detail*reveal*0.58;
 // Muted sky reflection keeps unlit panes readable without bright white squares.
 float reflection = 0.10+0.08*smoothstep(0.35,1.0,UV.y);
 ALBEDO = mix(room,vec3(0.018,0.030,0.038),reflection);
}
