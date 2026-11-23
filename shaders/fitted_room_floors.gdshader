shader_type spatial;
render_mode cull_back;
uniform sampler2D reference_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 field_color : source_color = vec4(0.27,0.21,0.17,1.0);
uniform vec4 accent_color : source_color = vec4(0.51,0.43,0.32,1.0);
uniform vec2 floor_center = vec2(0.0);
uniform vec2 floor_half = vec2(150.0,140.0);
uniform vec2 repeat_cm = vec2(24.0,26.0);
uniform int style_kind=0; // woven, staggered timber, glazed tile, ribbed shop floor
uniform int motif_kind=0;
uniform float dye_variation=0.27;
uniform vec4 coach_seam_color : source_color = vec4(0.44,0.35,0.24,1.0);
uniform float coach_seam_weight=0.0; // room decks deliberately do not use coach edging
varying vec3 room_world;
varying vec3 room_normal;

void vertex() {
 room_world = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 room_normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
}

vec3 linear_color(vec3 enc) {
 return mix(enc/12.92,pow((enc+0.055)/1.055,vec3(2.4)),step(vec3(0.04045),enc));
}
float line_coverage(float dist, float half_width, float footprint) {
 return 1.0-smoothstep(max(0.0001,half_width-footprint*0.5),half_width+footprint*0.5,abs(dist));
}
float sample_finish(vec2 point, int kind) {
 vec2 origin=vec2(float(kind%4),float(kind/4))*0.25;
 vec2 cell=origin+0.004+abs(fract(point*0.5)*2.0-1.0)*0.242;
 vec3 sc=textureGrad(reference_atlas,cell,dFdx(point)*0.242,dFdy(point)*0.242).rgb;
 if (OUTPUT_IS_SRGB) sc=linear_color(sc);
 float base=kind==8 ? 0.1089:(kind==1 ? 0.0403:0.6813);
 float sample_value=clamp(dot(sc,vec3(0.30,0.59,0.11))/base,0.31,2.11);
 return OUTPUT_IS_SRGB ? sqrt(sample_value):sample_value;
}
float smooth_repeat(float q) {
 return abs(fract(q+0.5)-0.5);
}
void fragment() {
 vec2 p=room_world.xz-floor_center;
 vec2 g=p/repeat_cm;
 vec2 pixel=max(fwidth(g),vec2(0.0001));
 float edge=min(floor_half.x-abs(p.x),floor_half.y-abs(p.y));
 float real_pixel=max(max(fwidth(p.x),fwidth(p.y)),0.015);
 float top=clamp(abs(room_normal.y),0.0,1.0);
 vec3 base=field_color.rgb;
 if (style_kind==0) {
  float thread=sample_finish(g,8);
  vec2 sine = abs(fract(g)-0.5);
  float pattern = 0.0;
  if (motif_kind==0) {
   pattern = line_coverage(sine.x+sine.y-0.38,0.015,max(pixel.x,pixel.y));
  } else if (motif_kind==1) {
   pattern = (line_coverage(sine.x-0.18,0.018,pixel.x)+line_coverage(sine.x-0.28,0.01,pixel.x))*0.65;
  } else if (motif_kind==2) {
   pattern = line_coverage(length(sine*vec2(1.0,0.68))-0.29,0.018,max(pixel.x,pixel.y));
  } else {
   pattern = line_coverage(abs(sine.x-sine.y)-0.22,0.016,max(pixel.x,pixel.y));
  }
  float deaden = 1.0-smoothstep(0.075,0.15,max(pixel.x,pixel.y));
  vec3 mottled=base*mix(1.0,thread,dye_variation);
  base=mix(mottled,accent_color.rgb,clamp(pattern*0.24*deaden,0.0,1.0));
  float braid=line_coverage(edge-6.2,0.36,real_pixel)+line_coverage(edge-9.1,0.19,real_pixel)*0.72;
  base=mix(base,accent_color.rgb,0.42*min(1.0,braid)*top);
  ROUGHNESS=0.90;
 } else if (style_kind==1) {
  float board=floor(g.x);
  float endcuts=g.y+floor(board*0.5)*0.35+mod(board,2.0)*0.44;
  float grain=sample_finish(vec2(fract(g.x),endcuts),1);
  float seams=max(line_coverage(smooth_repeat(g.x),0.010,pixel.x),line_coverage(smooth_repeat(endcuts),0.009,pixel.y))*top;
  float board_tone=fract(sin(board*6.77+floor(endcuts)*73.34)*32.56);
  base=base*mix(0.94,1.06,board_tone)*mix(1.0,grain,dye_variation);
  base=mix(base,base*0.48,seams*0.67);
  ROUGHNESS=0.58;
 } else {
  float stagger = mod(floor(g.y),2.0)*0.5;
  if (motif_kind==1) stagger=0.0;
  float joint=max(line_coverage(smooth_repeat(g.x+stagger),0.017,pixel.x),line_coverage(smooth_repeat(g.y),0.015,pixel.y))*top;
  float glazed=sample_finish(g*1.48,10);
  float value=fract(sin(dot(floor(vec2(g.x+stagger,g.y)),vec2(41.7,13.91)))*24.45);
  base=mix(field_color.rgb,accent_color.rgb,0.21*value)*mix(1.0,glazed,dye_variation);
  if (style_kind==3) {
   float ridges=line_coverage(smooth_repeat(g.x*7.0+g.y*9.0),0.10,max(pixel.x,pixel.y)*9.0);
   float hit=1.0-smoothstep(0.041,0.16,max(pixel.x,pixel.y));
   base=mix(base,accent_color.rgb,0.13*ridges*hit);
  } else if (motif_kind==2) {
   vec2 b=abs(fract(vec2(g.x+stagger,g.y))-0.5);
   float corner = line_coverage(b.x+b.y-0.82,0.018,max(pixel.x,pixel.y));
   joint=max(joint,0.58*corner*top);
  }
  base=mix(base,base*0.48,joint*0.55);
  ROUGHNESS=style_kind==3 ? 0.79:0.62;
 }
 if (coach_seam_weight>0.0) {
  // Inlaid tape/wood/utility edge lies within the existing solid floor, so
  // the outline cannot block a 6 mm fly crossing the doorway.
  float edging=line_coverage(abs(p.x)-50.5,0.74,real_pixel);
  edging*=smoothstep(0.0,1.4,floor_half.y-abs(p.y));
  base=mix(base,coach_seam_color.rgb,edging*top*coach_seam_weight);
 }
 ALBEDO=base*(0.78+0.22*top);
 SPECULAR=0.25;
}
