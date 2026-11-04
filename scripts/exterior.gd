extends Node3D
## Repeating city sections with independent parallax; no screen-space effects.
const HALO = preload("res://shaders/neon_halo.gdshader")
const WINDOWS = preload("res://shaders/neon_windows.gdshader")
const PERIOD := 1680.0
var layers: Array[Node3D] = []
var clock := 0.0
var halos: Array[MeshInstance3D] = []
var rng := RandomNumberGenerator.new()
var building_material: StandardMaterial3D
var window_material: ShaderMaterial
var trim_material: StandardMaterial3D
var tube_materials: Array[StandardMaterial3D] = []

func build() -> void:
 building_material = StandardMaterial3D.new()
 building_material.vertex_color_use_as_albedo = true
 building_material.roughness = 0.38
 building_material.metallic = 0.18
 window_material = ShaderMaterial.new()
 window_material.shader = WINDOWS
 trim_material = StandardMaterial3D.new()
 trim_material.albedo_color = Color("101a21")
 trim_material.roughness = 0.3
 trim_material.metallic = 0.5
 for tint in [Color("55cbd2"),Color("d478a5"),Color("e4b36a")]:
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = tint.lightened(0.45)
  tube_materials.append(material)
 for layer_index in range(3):
  var layer := Node3D.new()
  layer.name = "CityParallax%d" % layer_index
  add_child(layer)
  layers.append(layer)
  var buildings: Array[Transform3D] = []
  var building_colors: Array[Color] = []
  var windows: Array[Transform3D] = []
  var window_colors: Array[Color] = []
  # Every section has the same seed and layout, making wrapping imperceptible.
  for section in range(-2,4):
   rng.seed = 90621 + layer_index * 73
   for side in [-1,1]:
    for i in range(5):
     var depth := 100.0 + layer_index*35.0
     var distance := 815.0 + layer_index*410.0 + rng.randf_range(0,120)
     var width := rng.randf_range(180,280)
     var height := rng.randf_range(340,850) + layer_index*120.0
     var z := section*PERIOD + i*336 + rng.randf_range(-24,24)
     var position3 := Vector3(side*distance,height*0.5-100,z)
     buildings.append(Transform3D(Basis.from_scale(Vector3(depth,height,width)),position3))
     var tint := Color("152733") if i%2 else Color("1a2b36")
     building_colors.append(tint.darkened(layer_index*0.16))
     # Panes lie along Y/Z, on the wall facing the train, not the street end.
     var face: float = side*(distance-depth*0.5-0.8)
     for floor_index in range(2,int(height/62)-1):
      for column in range(4):
       var lit := rng.randf() > 0.53
       if not lit: continue
       var wp := Vector3(face,float(floor_index)*62-70,z+(column-1.5)*45)
       windows.append(Transform3D(Basis.from_scale(Vector3(1.0,24.0,14.0)),wp))
       var color := Color("9da595") if column%3 else Color("b59470")
       window_colors.append(color*rng.randf_range(0.20,0.58)/(1.0+layer_index*0.45))
     if layer_index == 0 and i in [1,3]:
      neon_sign(layer,Vector3(face-side*4,128+rng.randf_range(-12,46),z),side,(i+int(side)+3)%3,i)
  batch(layer,buildings,building_colors,building_material)
  batch(layer,windows,window_colors,window_material)

func batch(parent: Node3D, transforms: Array[Transform3D], colors: Array[Color], material: Material) -> void:
 var mesh := BoxMesh.new()
 mesh.size = Vector3.ONE
 var multimesh := MultiMesh.new()
 multimesh.transform_format = MultiMesh.TRANSFORM_3D
 multimesh.use_colors = true
 multimesh.mesh = mesh
 multimesh.instance_count = transforms.size()
 for i in range(transforms.size()):
  multimesh.set_instance_transform(i,transforms[i])
  multimesh.set_instance_color(i,colors[i])
 var instance := MultiMeshInstance3D.new()
 instance.multimesh = multimesh
 instance.material_override = material
 instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 parent.add_child(instance)

func block(parent: Node3D, size: Vector3, position3: Vector3, material: Material) -> MeshInstance3D:
 var mesh := BoxMesh.new()
 mesh.size = size
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = position3
 instance.material_override = material
 instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 parent.add_child(instance)
 return instance

func neon_sign(parent: Node3D, position3: Vector3, side: int, palette: int, index: int) -> void:
 var sign_root := Node3D.new()
 parent.add_child(sign_root)
 sign_root.position = position3
 # Sign local +Z points toward the train; X is horizontal along the railway.
 sign_root.rotation.y = -side*PI*0.5
 block(sign_root,Vector3(132,69,6),Vector3.ZERO,trim_material)
 var tube := tube_materials[palette]
 for x in [-58,58]: block(sign_root,Vector3(1.1,53,1.1),Vector3(x,0,4),tube)
 for y in [-26.5,26.5]: block(sign_root,Vector3(116,1.1,1.1),Vector3(0,y,4),tube)
 var text := Label3D.new()
 text.text = "HOTEL" if index == 1 else "NIGHT CAFE"
 text.font = preload("res://assets/Interface.ttf")
 text.font_size = 56
 text.pixel_size = 0.32 if index == 1 else 0.24
 text.modulate = tube.albedo_color
 text.outline_size = 0
 text.position = Vector3(0,1,4.7)
 text.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 sign_root.add_child(text)
 var quad := QuadMesh.new()
 quad.size = Vector2(194,88.33)
 var halo := MeshInstance3D.new()
 halo.mesh = quad
 halo.position = Vector3(0,0,5.5)
 halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material := ShaderMaterial.new()
 material.shader = HALO
 material.set_shader_parameter("neon_color",Color("55cbd2") if palette == 0 else (Color("d478a5") if palette == 1 else Color("e4b36a")))
 material.set_shader_parameter("frame_ratio",Vector2(1.0,1.0))
 material.set_shader_parameter("sign_phase",float(index*7+side))
 halo.material_override = material
 sign_root.add_child(halo)
 halos.append(halo)
 # Small reflected tint on the wet wall beneath each sign, no scene lights.
 var reflection := MeshInstance3D.new()
 reflection.mesh = quad
 reflection.position = Vector3(0,-52,4.8)
 reflection.scale = Vector3(0.62,0.55,1)
 var reflection_material := material.duplicate() as ShaderMaterial
 reflection_material.set_shader_parameter("wall_reflection",true)
 reflection.material_override = reflection_material
 reflection.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 sign_root.add_child(reflection)
 halos.append(reflection)

func set_effects_enabled(enabled: bool) -> void:
 for halo in halos: halo.visible = enabled

func _process(delta: float) -> void:
 clock += delta
 for i in range(layers.size()):
  layers[i].position.z = fmod(clock*(170.0/(1.0+i*0.8)),PERIOD)
