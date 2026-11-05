shader_type spatial;
// Small procedural variations stay at centimetre scale, even at fly distance.
uniform vec4 finish_color : source_color = vec4(0.1,0.22,0.2,1.0);
uniform int finish = 0; // floor, velvet, mahogany, brocade, ceiling, textured walnut
uniform sampler2D wood_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D brocade_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_position;
varying vec3 local_position;
varying vec3 local_normal;
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 local_position = VERTEX;
 local_normal = NORMAL;
}
float hash21(vec2 p) {return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
vec3 relief_normal(vec3 position, vec3 normal, float height) {
 vec3 dx = dFdx(position);
 vec3 dy = dFdy(position);
 vec3 r1 = cross(dy,normal);
 vec3 r2 = cross(normal,dx);
 float determinant = dot(dx,r1);
 vec3 gradient = sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
 return normalize(abs(determinant)*normal-gradient);
}
void fragment() {
 vec2 p = world_position.xz;
 float shade = 1.0;
 if (finish == 0) {
  float plank = floor((p.x+170.0)/20.0);
  float row = floor((p.y+mod(plank,2.0)*42.0)/84.0);
  float grain = sin(p.x*8.0+sin(p.y*0.027+plank)*2.3+sin(p.x*0.7)*0.7);
  float fine = sin(p.x*31.0+sin(p.y*0.019)*3.0)*(1.0-smoothstep(0.5,2.0,fwidth(p.x)*31.0));
  shade = 0.88+grain*0.055+fine*0.025+hash21(vec2(plank,row))*0.22;
  float seam = min(mod(p.y+mod(plank,2.0)*42.0,84.0),84.0-mod(p.y+mod(plank,2.0)*42.0,84.0));
  shade *= mix(0.58,1.0,smoothstep(0.05,0.16,seam));
  ROUGHNESS = 0.48+grain*0.06;
 } else if (finish == 1) {
  // Fine cloth; actual model seams and tufts supply the tailoring.
  vec2 cloth = vec2(world_position.x,world_position.y+world_position.z);
  float cloth_footprint = max(fwidth(cloth.x)*45.0,fwidth(cloth.y)*41.0);
  float weave = sin(cloth.x*45.0)*sin(cloth.y*41.0)*(1.0-smoothstep(0.5,2.0,cloth_footprint));
  // Tailoring comes from modeled seams and tufting; the weave stays microscopic.
  shade = 0.94+0.025*weave;
  ROUGHNESS = 0.90;
  NORMAL = relief_normal(VERTEX,NORMAL,weave*0.012);
 } else if (finish == 2) {
  vec3 blend = pow(abs(local_normal),vec3(6.0));
  blend /= max(dot(blend,vec3(1.0)),0.0001);
  vec3 yz = texture(wood_texture,local_position.zy/vec2(95.0,190.0)).rgb;
  vec3 xz = texture(wood_texture,local_position.xz/vec2(95.0,190.0)).rgb;
  vec3 xy = texture(wood_texture,local_position.xy/vec2(95.0,190.0)).rgb;
  float figure = clamp((yz*blend.x+xz*blend.y+xy*blend.z).r*4.0,0.0,1.0);
  shade = mix(0.70,1.17,figure);
  ROUGHNESS = mix(0.49,0.39,figure);
  CLEARCOAT = 0.18;
  CLEARCOAT_ROUGHNESS = 0.42;
 } else if (finish == 3) {
  // Fine botanical brocade with continuous edge values at mirrored repeats.
  vec2 wall = vec2(world_position.x+world_position.z,world_position.y)/64.0;
  vec2 woven_uv = abs(fract(wall*0.5)*2.0-1.0);
  vec3 fabric = texture(brocade_texture,woven_uv).rgb;
  float thread = dot(fabric,vec3(0.30,0.59,0.11));
  ALBEDO = fabric*1.35;
  ROUGHNESS = 0.79-thread*0.12;
  NORMAL = relief_normal(VERTEX,NORMAL,thread*0.025);
 } else if (finish == 5) {
  vec3 sample_color = texture(wood_texture,UV).rgb;
  float luminance = dot(sample_color,vec3(0.3,0.59,0.11));
  // Keep the supplied timber texture at fly distance with a quiet walnut tone.
  ALBEDO = mix(vec3(luminance),sample_color,0.20)*vec3(0.90,0.79,0.68);
  ROUGHNESS = 0.44;
  CLEARCOAT = 0.45;
  CLEARCOAT_ROUGHNESS = 0.35;
  NORMAL = relief_normal(VERTEX,NORMAL,luminance*0.06);
 } else {
  shade = 0.96+0.018*sin(world_position.z*0.8);
  ROUGHNESS = 0.78;
 }
 if (finish != 3 && finish != 5) { ALBEDO = finish_color.rgb*shade; }
}
