extends RefCounted
## Shared cabinet materials use the supplied mahogany image at physical scale.
## Small finish variation remains visible close up without painted-on shadows.
static var _cache: Dictionary = {}

static func timber(tint: Color) -> ShaderMaterial:
 var key := "timber_"+str(tint)
 if _cache.has(key): return _cache[key]
 var shader := Shader.new()
 shader.code = """
shader_type spatial;
uniform vec4 tint : source_color;
uniform sampler2D timber_map : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 timber_position;
varying vec3 timber_normal;
void vertex() { timber_position = VERTEX; timber_normal = NORMAL; }
void fragment() {
 vec3 blend = pow(abs(timber_normal),vec3(6.0));
 blend /= max(dot(blend,vec3(1.0)),0.0001);
 vec3 yz = texture(timber_map,timber_position.zy/vec2(95.0,190.0)).rgb;
 vec3 xz = texture(timber_map,timber_position.xz/vec2(95.0,190.0)).rgb;
 vec3 xy = texture(timber_map,timber_position.xy/vec2(95.0,190.0)).rgb;
 vec3 grain = yz*blend.x+xz*blend.y+xy*blend.z;
 float figure = clamp(grain.r*4.0,0.0,1.0);
 ALBEDO = tint.rgb*mix(0.60,1.24,figure);
 ROUGHNESS = mix(0.48,0.34,figure);
 CLEARCOAT = 0.28;
 CLEARCOAT_ROUGHNESS = 0.32;
}
"""
 var material := ShaderMaterial.new()
 material.shader = shader
 material.set_shader_parameter("tint",tint)
 material.set_shader_parameter("timber_map",preload("res://assets/textures/table_mahogany_albedo.png"))
 _cache[key] = material
 return material

static func stone() -> ShaderMaterial:
 if _cache.has("stone"): return _cache["stone"]
 var shader := Shader.new()
 shader.code = """
shader_type spatial;
varying vec3 stone_position;
void vertex() { stone_position = VERTEX; }
float noise(vec2 p) {
 vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
 float a=fract(sin(dot(i,vec2(127.1,311.7)))*43758.5453);
 float b=fract(sin(dot(i+vec2(1.0,0.0),vec2(127.1,311.7)))*43758.5453);
 float c=fract(sin(dot(i+vec2(0.0,1.0),vec2(127.1,311.7)))*43758.5453);
 float d=fract(sin(dot(i+vec2(1.0,1.0),vec2(127.1,311.7)))*43758.5453);
 return mix(mix(a,b,f.x),mix(c,d,f.x),f.y);
}
void fragment() {
 vec2 p=stone_position.xz;
 float cloud=noise(p*0.075)*0.65+noise(p*0.19)*0.35;
 float vein=1.0-smoothstep(0.03,0.12,abs(sin(p.x*0.035+p.y*0.019+cloud*2.3)));
 ALBEDO=vec3(0.47,0.44,0.36)*(0.95+cloud*0.09)-vec3(0.035,0.032,0.024)*vein;
 ROUGHNESS=0.31+cloud*0.05+vein*0.025;
}
"""
 var material := ShaderMaterial.new()
 material.shader = shader
 _cache["stone"] = material
 return material
