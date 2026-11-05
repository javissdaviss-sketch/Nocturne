shader_type spatial;
uniform vec4 color : source_color = vec4(0.4,0.25,0.15,1.0);
uniform int finish = 0; // leather, paper, linen, polished wood, bread crust
varying vec3 p;
void vertex() { p = VERTEX; }
float hash(vec3 q) { return fract(sin(dot(q,vec3(12.9898,78.233,36.425)))*43758.5453); }
void fragment() {
 float fine = hash(floor(p*24.0));
 float wear = 0.5+0.5*sin(p.x*0.77+sin(p.z*0.43)+p.y*0.26);
 ALBEDO = color.rgb;
 ROUGHNESS = 0.6;
 if (finish == 0) {
  ALBEDO *= 0.94+fine*0.05+wear*0.035;
  ROUGHNESS = 0.48+fine*0.12;
  CLEARCOAT = 0.12;
  CLEARCOAT_ROUGHNESS = 0.5;
 } else if (finish == 1) {
  float edge = sin(p.y*34.0);
  edge *= 1.0-smoothstep(0.4,1.3,fwidth(p.y)*34.0);
  ALBEDO *= 0.95+edge*0.025+fine*0.02;
  ROUGHNESS = 0.87;
 } else if (finish == 2) {
  float weave = sin(p.x*35.0)*sin(p.z*35.0);
  weave *= 1.0-smoothstep(0.4,1.3,max(fwidth(p.x),fwidth(p.z))*35.0);
  ALBEDO *= 0.96+weave*0.04;
  ROUGHNESS = 0.91;
 } else if (finish == 3) {
  float grain = sin(p.z*8.6+sin(p.x*0.10)*1.8+sin(p.z*0.15));
  grain *= 1.0-smoothstep(0.4,1.3,fwidth(p.z)*8.6);
  ALBEDO *= 0.97+grain*0.012+wear*0.018;
  ROUGHNESS = 0.34+fine*0.05;
  CLEARCOAT = 0.32;
  CLEARCOAT_ROUGHNESS = 0.3;
 } else {
  float crust = 0.5+0.5*sin(p.x*1.7+sin(p.z*1.3)*2.2+sin(p.y*2.6));
  ALBEDO = mix(color.rgb*(0.74+0.24*crust+0.05*fine),vec3(0.74,0.49,0.25),clamp((1.0-COLOR.b)*1.4,0.0,1.0));
  ROUGHNESS = 0.72+fine*0.16;
 }
}
