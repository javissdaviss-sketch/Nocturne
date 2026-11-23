shader_type spatial;
render_mode cull_disabled;
// Scope: positioned timber joinery and one table only. End grain uses the same
// authored photograph as the length face, brought into scale without its red cast.
uniform sampler2D veneer : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 timber_tint : source_color = vec4(0.31,0.25,0.20,1.0);
uniform vec2 repeat_cm = vec2(39.0,142.0);
uniform float figure_contrast = 0.84;
uniform float satin = 0.47;
uniform float coat_amount = 0.19;
uniform vec3 strand_world = vec3(0.0,1.0,0.0);
varying vec3 physical_point;
varying vec3 world_normal;

void vertex() {
 physical_point = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 world_normal = normalize(MODEL_NORMAL_MATRIX*NORMAL);
}

vec2 mirror_sample(vec2 uv) {
 return vec2(0.003) + abs(fract(uv*0.5)*2.0 - 1.0)*0.994;
}

void fragment() {
 // Project every board along a physical grain axis. On the edge parallel
 // to the axis the second tangent is derived from the dominant face.
 vec3 along = normalize(strand_world);
 vec3 n = normalize(world_normal);
 vec3 across = cross(along,n);
 if (dot(across,across)<0.08) { across = vec3(1,0,0); }
 across = normalize(across);
 vec2 board_position = vec2(dot(physical_point,across),dot(physical_point,along));
 vec2 uv = board_position/repeat_cm;
 vec3 grain = textureGrad(veneer,mirror_sample(uv),dFdx(uv)*0.994,dFdy(uv)*0.994).rgb;
 // Compatibility samples a color input in encoded space, while the
 // default Forward+ samples the same texture in linear space. Normalize
 // both around the measured linear median of the original wood PNG.
 if (OUTPUT_IS_SRGB) {
  grain = mix(grain/12.92,pow((grain+vec3(0.055))/1.055,vec3(2.4)),step(vec3(0.04045),grain));
 }
 float figure = clamp(dot(grain,vec3(0.30,0.59,0.11))/0.02100565,0.42,1.95);
 float figure_for_color = OUTPUT_IS_SRGB ? sqrt(figure) : figure;
 ALBEDO = timber_tint.rgb*mix(1.0,figure_for_color,figure_contrast);
 ROUGHNESS = clamp(satin-0.12*(figure-1.0),0.29,0.75);
 CLEARCOAT = coat_amount;
 CLEARCOAT_ROUGHNESS = 0.43;
 METALLIC = 0.0;
 SPECULAR = 0.31;
}
