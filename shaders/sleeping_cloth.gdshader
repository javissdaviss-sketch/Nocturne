shader_type spatial;
render_mode cull_disabled;
uniform vec4 cloth_color : source_color = vec4(0.1,0.25,0.23,1.0);
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz; }
void fragment() {
 vec3 p = world_position;
 float thread = sin(p.x*24.0+p.y*3.0)*sin(p.z*26.0+p.y*22.0);
 float visibility = 1.0-smoothstep(0.35,1.4,max(fwidth(p.x),max(fwidth(p.y),fwidth(p.z)))*24.0);
 float yarn = thread*visibility;
 float variation = sin(p.x*0.17+p.z*0.13)*sin(p.z*0.21+p.y*0.16);
 ALBEDO = cloth_color.rgb*(0.985+0.012*variation+0.017*yarn);
 ROUGHNESS = 0.88+0.03*yarn;
 RIM = 0.16;
 RIM_TINT = 0.45;
 vec3 dx = dFdx(VERTEX);
 vec3 dy = dFdy(VERTEX);
 vec3 r1 = cross(dy,NORMAL);
 vec3 r2 = cross(NORMAL,dx);
 float determinant = dot(dx,r1);
 float height = yarn*0.005;
 vec3 gradient = sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
 NORMAL = normalize(abs(determinant)*NORMAL-gradient);
}
