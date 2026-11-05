extends Node3D
## Rain lives on sealed window glass; it never emits particles inside the train.
const RAIN_SHADER = preload("res://shaders/window_rain.gdshader")
var glass_material: ShaderMaterial

func _init() -> void:
 glass_material = ShaderMaterial.new()
 glass_material.shader = RAIN_SHADER

func add_carriage(index: int) -> void:
 # Shared mesh/material per carriage side; the existing frame and crossbars
 # occlude the pane naturally. UV V increases downward, matching gravity.
 for side in [-1,1]:
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  var vertices := [Vector3(0,247,-400), Vector3(0,247,400), Vector3(0,96,400), Vector3(0,96,-400)]
  var uv_offset := Vector2(float(index)*91.7+float(side)*12.3, float(index)*23.1)
  var uvs := [Vector2(0,0), Vector2(800,0), Vector2(800,151), Vector2(0,151)]
  for i in [0,1,2,0,2,3]:
   surface.set_normal(Vector3(-side,0,0))
   surface.set_uv(uvs[i]+uv_offset)
   # Unshifted physical coordinates keep collected moisture at the real seals
   # and mullions; the primary UV retains variation between carriage sides.
   surface.set_uv2(uvs[i])
   surface.add_vertex(vertices[i])
  var pane := MeshInstance3D.new()
  pane.name = "RainGlass_%d_%s" % [index, "left" if side < 0 else "right"]
  pane.mesh = surface.commit()
  pane.material_override = glass_material
  pane.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(pane)
  pane.position = Vector3(side*513,0,float(index)*840.0+400.0)
