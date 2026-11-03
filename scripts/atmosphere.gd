extends Node3D
## Bounded CPU particles work with the game's GL Compatibility renderer.
const RAIN_SHADER = preload("res://shaders/rain_streak.gdshader")
var emitters: Array[CPUParticles3D] = []

func _ready() -> void:
 var rain_material := ShaderMaterial.new()
 rain_material.shader = RAIN_SHADER
 var rain_mesh := QuadMesh.new()
 rain_mesh.size = Vector2(0.6,13.0)
 rain_mesh.orientation = PlaneMesh.FACE_X
 rain_mesh.material = rain_material
 # Entire emission volumes sit outside the sealed train; no rain in the cabin.
 for car in range(3):
  for side in [-1,1]:
   var rain := CPUParticles3D.new()
   rain.name = "ExteriorRain_%d_%d" % [car,side]
   rain.amount = 140
   rain.lifetime = 1.5
   rain.preprocess = 1.5
   rain.mesh = rain_mesh
   rain.position = Vector3(side*475,520,car*840+400)
   rain.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
   rain.emission_box_extents = Vector3(190,15,415)
   rain.direction = Vector3(0,-1,0.12).normalized()
   rain.spread = 4.0
   rain.initial_velocity_min = 400.0
   rain.initial_velocity_max = 480.0
   rain.gravity = Vector3(0,-70,0)
   rain.visibility_aabb = AABB(Vector3(-430,-800,-450),Vector3(860,850,900))
   add_child(rain)
   emitters.append(rain)
 var dust_material := StandardMaterial3D.new()
 dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 dust_material.vertex_color_use_as_albedo = true
 dust_material.albedo_color = Color(0.78,0.65,0.43,0.28)
 var dust_mesh := SphereMesh.new()
 dust_mesh.radius = 0.07
 dust_mesh.height = 0.14
 dust_mesh.radial_segments = 4
 dust_mesh.rings = 2
 dust_mesh.material = dust_material
 for car in range(3):
  var dust := CPUParticles3D.new()
  dust.name = "LamplightDust_%d" % car
  dust.amount = 45
  dust.lifetime = 14.0
  dust.preprocess = 14.0
  dust.mesh = dust_mesh
  dust.position = Vector3(105,170,car*840+400)
  dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
  dust.emission_box_extents = Vector3(40,45,350)
  dust.direction = Vector3.UP
  dust.spread = 65.0
  dust.initial_velocity_min = 0.2
  dust.initial_velocity_max = 0.7
  dust.gravity = Vector3(0.02,-0.015,0)
  dust.scale_amount_min = 0.5
  dust.scale_amount_max = 1.2
  dust.visibility_aabb = AABB(Vector3(-60,-65,-375),Vector3(120,150,750))
  add_child(dust)
  emitters.append(dust)

func set_enabled(enabled: bool) -> void:
 visible = enabled
 for emitter in emitters:
  emitter.emitting = enabled
  emitter.visible = enabled
