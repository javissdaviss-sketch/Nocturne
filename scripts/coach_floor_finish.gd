extends RefCounted
## Entry-readable coach identity without raised joints under fly feet.
const Library := preload("res://scripts/material_library.gd")
const Field := preload("res://shaders/fitted_room_floors.gdshader")
# Residential muffled footsteps, polished dark dining decks, washable intake.
const COACH := [
 ["Residence / striped wool runner",0,1,"6e5b56","b7906d",Vector2(28,57),0.41,"a1856c",0.55],
 ["Meridian / narrow satin timber",1,0,"685341","9c7953",Vector2(15,106),0.48,"9d805c",0.68],
 ["Archive / pressed utility flooring",3,0,"5c6d65","82917b",Vector2(23,33),0.34,"96ab94",0.46],
]
static var objects:Dictionary={}
static func get_finish(index:int)->ShaderMaterial:
 var ref:=clampi(index,0,COACH.size()-1)
 if objects.has(ref):return objects[ref]
 var spec:Array=COACH[ref]
 var m:=ShaderMaterial.new()
 m.shader=Field
 m.resource_name=spec[0]
 m.set_meta("crafted_finish",[Library.Finish.RUG,Library.Finish.WALNUT,Library.Finish.CERAMIC][ref])
 m.set_shader_parameter("reference_atlas",Library.ATLAS)
 m.set_shader_parameter("floor_center",Vector2(0,float(ref)*840.0+400.0))
 m.set_shader_parameter("floor_half",Vector2(55,390))
 m.set_shader_parameter("style_kind",spec[1])
 m.set_shader_parameter("motif_kind",spec[2])
 m.set_shader_parameter("field_color",Color(spec[3]))
 m.set_shader_parameter("accent_color",Color(spec[4]))
 m.set_shader_parameter("repeat_cm",spec[5])
 m.set_shader_parameter("dye_variation",spec[6])
 m.set_shader_parameter("coach_seam_color",Color(spec[7]))
 m.set_shader_parameter("coach_seam_weight",spec[8])
 objects[ref]=m
 return m
