shader_type spatial;
render_mode cull_disabled;
// Reference-inspired photographic atlas. Coordinates are physical centimetres,
// including canonical primitive meshes rendered through MultiMesh batches.
uniform sampler2D material_atlas : source_color, filter_linear_mipmap_anisotropic, repeat_disable;
uniform vec4 tint : source_color = vec4(0.3,0.2,0.14,1.0);
uniform int surface_kind = 0;
uniform vec2 tile_cm = vec2(48.0,140.0);
uniform float mean_luminance = 0.0574;
uniform float base_roughness = 0.45;
uniform float metalness = 0.0;
uniform float relief_cm = 0.012;
uniform float varnish = 0.0;
uniform bool floor_planks = false;
uniform bool carpet_border = false;
varying vec3 physical_position;
varying vec3 physical_normal;
varying vec3 world_position;
void vertex() {
 vec3 physical_scale = vec3(length(MODEL_MATRIX[0].xyz),length(MODEL_MATRIX[1].xyz),length(MODEL_MATRIX[2].xyz));
 physical_position = VERTEX*physical_scale;
 physical_normal = normalize(NORMAL/max(physical_scale,vec3(0.0001)));
 world_position = (MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}
vec3 photograph(vec2 coordinates) {
 // A mirrored repeat keeps the photographed grain continuous. An inset keeps
 // adjacent atlas cells out of the anisotropic filter footprint.
 vec2 mirrored = abs(fract(coordinates*0.5)*2.0-1.0);
 vec2 cell = vec2(float(surface_kind%4),float(surface_kind/4));
 vec2 atlas_uv = cell*0.25+vec2(0.004)+mirrored*0.242;
 vec2 dx = dFdx(coordinates)*0.242;
 vec2 dy = dFdy(coordinates)*0.242;
 // Beyond a cell's useful resolution the mean is safer than adjacent materials.
 float footprint = max(length(dx),length(dy));
 vec3 sample_color = textureGrad(material_atlas,atlas_uv,dx,dy).rgb;
 return mix(sample_color,vec3(mean_luminance),smoothstep(0.012,0.04,footprint));
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
void fragment() {
 vec3 blend = pow(abs(physical_normal),vec3(6.0));
 blend /= max(dot(blend,vec3(1.0)),0.0001);
 vec3 photo;
 if (floor_planks || carpet_border) {
  vec2 coordinates = world_position.xz/tile_cm;
  if (floor_planks) {
   float plank = floor((world_position.x+510.0)/20.0);
   coordinates = vec2(fract((world_position.x+510.0)/20.0),world_position.z/tile_cm.y+plank*0.37);
  }
  photo = photograph(coordinates);
 } else {
  photo = photograph(physical_position.zy/tile_cm)*blend.x
   +photograph(physical_position.xz/tile_cm)*blend.y
   +photograph(physical_position.xy/tile_cm)*blend.z;
 }
 float luminance = dot(photo,vec3(0.30,0.59,0.11));
 float figure = clamp(luminance/max(mean_luminance,0.001),0.28,2.6);
 float contrast = (surface_kind == 7 || surface_kind == 8) ? 0.87 : (surface_kind == 4 ? 0.28 : 0.62);
 ALBEDO = tint.rgb*mix(1.0,figure,contrast);
 // Keep the rug/damask's actual colored threads instead of tinting to grayscale.
 if (surface_kind == 7 || surface_kind == 8) {
  ALBEDO = mix(ALBEDO,photo*0.85,0.62);
 }
 if (floor_planks) {
  vec2 p = world_position.xz;
  float plank = floor((p.x+510.0)/20.0);
  float across = min(mod(p.x+510.0,20.0),20.0-mod(p.x+510.0,20.0));
  float along = mod(p.y+mod(plank,2.0)*42.0,84.0);
  float seam = min(across,min(along,84.0-along));
  ALBEDO *= mix(0.56,1.0,smoothstep(0.015,0.10,seam));
 }
 if (carpet_border) {
  float edge = abs(world_position.x);
  float braid = 1.0-smoothstep(0.25,0.55,abs(edge-49.0));
  ALBEDO = mix(ALBEDO,vec3(0.30,0.20,0.085),braid*0.7);
 }
 METALLIC = metalness;
 ROUGHNESS = clamp(base_roughness+(1.0-figure)*0.055,0.16,0.98);
 CLEARCOAT = varnish;
 CLEARCOAT_ROUGHNESS = 0.32;
 NORMAL = relief_normal(VERTEX,NORMAL,(figure-1.0)*relief_cm);
 if (surface_kind == 4 || surface_kind == 6 || surface_kind == 8) {
  RIM = 0.13;
  RIM_TINT = 0.35;
 }
 if (surface_kind == 14) {
  BACKLIGHT = ALBEDO*0.28;
  ROUGHNESS = 0.64;
 }
}
