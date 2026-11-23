extends RefCounted
## A local neutral-satin finish using the existing 1254px grain reference.
## No changes to shared material resources or scene lighting.
const SHADER := preload("res://shaders/veneered_joinery.gdshader")
const GRAIN := preload("res://assets/textures/table_mahogany_albedo.png")
const Finish := preload("res://scripts/material_library.gd").Finish

static func make(role: String, tone: Color = Color(0,0,0,0)) -> ShaderMaterial:
 var m := ShaderMaterial.new()
 m.shader = SHADER
 m.resource_name = "Fitted walnut / "+role
 m.set_meta("crafted_finish",Finish.WALNUT)
 m.set_shader_parameter("veneer",GRAIN)
 m.set_shader_parameter("strand_world",Vector3.UP)
 match role:
  "field":
   m.set_shader_parameter("timber_tint",Color("69513c"))
   m.set_shader_parameter("repeat_cm",Vector2(32,114))
   m.set_shader_parameter("satin",0.51)
  "edge":
   m.set_shader_parameter("timber_tint",Color("5f412d"))
   m.set_shader_parameter("repeat_cm",Vector2(26,148))
   m.set_shader_parameter("satin",0.37)
  "bed":
   m.set_shader_parameter("timber_tint",Color("514235"))
   m.set_shader_parameter("repeat_cm",Vector2(46,123))
   m.set_shader_parameter("satin",0.48)
   m.set_shader_parameter("strand_world",Vector3.RIGHT)
  "table":
   m.set_shader_parameter("timber_tint",Color("4e4033"))
   m.set_shader_parameter("repeat_cm",Vector2(48,140))
   m.set_shader_parameter("satin",0.52)
   m.set_shader_parameter("strand_world",Vector3.BACK)
  _:
   m.set_shader_parameter("timber_tint",Color("4e392b"))
   m.set_shader_parameter("repeat_cm",Vector2(41,140))
   m.set_shader_parameter("satin",0.48)
 if tone.a>0.0: m.set_shader_parameter("timber_tint",tone)
 return m
