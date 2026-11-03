shader_type spatial;
// Small procedural variations stay at centimetre scale, even at fly distance.
uniform vec4 finish_color : source_color = vec4(0.1,0.22,0.2,1.0);
uniform int finish = 0; // 0 walnut floor, 1 woven upholstery, 2 lacquer panel
varying vec3 world_position;
varying vec3 local_position;
void vertex() {
 world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz;
 local_position = VERTEX;
}
float hash21(vec2 p) {return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453);}
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
  // Broad stitched channels plus fine cloth, without glossy plastic highlights.
  vec2 cloth = vec2(local_position.x,local_position.y+local_position.z);
  float cloth_footprint = max(fwidth(cloth.x)*45.0,fwidth(cloth.y)*41.0);
  float weave = sin(cloth.x*45.0)*sin(cloth.y*41.0)*(1.0-smoothstep(0.5,2.0,cloth_footprint));
  float channel = abs(sin((local_position.x+32.0)*3.14159/13.0));
  shade = (0.91+0.055*weave)*mix(0.66,1.0,smoothstep(0.01,0.11,channel));
  ROUGHNESS = 0.90;
 } else {
  float grain = sin(world_position.y*1.8+sin(world_position.z*0.025)*1.5);
  shade = 0.96+grain*0.035;
  ROUGHNESS = 0.52+grain*0.035;
 }
 ALBEDO = finish_color.rgb*shade;
}
