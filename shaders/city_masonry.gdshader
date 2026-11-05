shader_type spatial;
// MultiMesh colors keep the prior linear interpretation. Night exposure is
// reduced once here; applying sRGB decoding as well would crush the facade.
uniform float night_albedo = 0.68;
uniform float district_offset = 0.0;
varying vec3 masonry_position;
varying vec3 masonry_normal;

float hash21(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise2(vec2 p) {
 vec2 cell = floor(p);
 vec2 f = fract(p);
 f = f*f*(3.0-2.0*f);
 return mix(mix(hash21(cell),hash21(cell+vec2(1.0,0.0)),f.x),mix(hash21(cell+vec2(0.0,1.0)),hash21(cell+vec2(1.0,1.0)),f.x),f.y);
}
vec3 relief_normal(vec3 position, vec3 normal, float height) {
 vec3 dx = dFdx(position);
 vec3 dy = dFdy(position);
 vec3 r1 = cross(dy,normal);
 vec3 r2 = cross(normal,dx);
 float determinant = dot(dx,r1);
 vec3 gradient = sign(determinant)*(dFdx(height)*r1+dFdy(height)*r2);
 return normalize(abs(determinant)*normal-gradient);
}
void vertex() {
 masonry_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 masonry_position.z -= district_offset;
 masonry_normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment() {
 vec3 normal_axis = abs(masonry_normal);
 vec2 p = normal_axis.x > 0.5 ? masonry_position.zy : (normal_axis.y > 0.5 ? masonry_position.xz : masonry_position.xy);
 // Broad, quiet mineral variation and occasional damp vertical streaks.
 float mottling = noise2(p/160.0);
 float mineral = noise2(p/28.0);
 float damp = smoothstep(0.53,0.80,noise2(p/vec2(24.0,260.0)));
 // Fine, shallow ashlar joints: 90 x 40 cm blocks, staggered half a course.
 float course = floor(p.y/40.0);
 vec2 bond = vec2((p.x+mod(course,2.0)*45.0)/90.0,p.y/40.0);
 vec2 tile = fract(bond);
 vec2 edge = min(tile,vec2(1.0)-tile)*vec2(90.0,40.0);
 float aa = max(max(fwidth(p.x),fwidth(p.y)),0.15);
 float joint = 1.0-smoothstep(0.5-aa,0.5+aa,min(edge.x,edge.y));
 float block_tone = hash21(floor(bond));
 float variation = 1.0+(mottling-0.5)*0.07+(mineral-0.5)*0.025+(block_tone-0.5)*0.025;
 ALBEDO = COLOR.rgb*night_albedo*variation*mix(1.0,0.95,joint);
 ROUGHNESS = clamp(0.82+(mottling-0.5)*0.08-damp*0.18,0.62,0.88);
 SPECULAR = 0.35;
 NORMAL = relief_normal(VERTEX,NORMAL,(mineral-0.5)*0.018-joint*0.035);
}
