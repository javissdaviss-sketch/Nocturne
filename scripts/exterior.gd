extends Node3D
## Human-scale railway district. Perspective supplies parallax at one train speed.
const HALO = preload("res://shaders/neon_halo.gdshader")
const WINDOWS = preload("res://shaders/neon_windows.gdshader")
const HotelRelief:=preload("res://scripts/railside_hotel_relief.gd")
const MASONRY = preload("res://shaders/city_masonry.gdshader")
const NightLocal = preload("res://scripts/night_local.gd")
const PERIOD := 13440.0
const TRAIN_SPEED := 460.0
const STREET_LEVEL := -120.0
const SIGN_COLORS := [Color("55cbd2"),Color("d478a5"),Color("e4b36a")]
const SALON_BAY_Z := 1135.0
const MAX_SPILL_ENERGY := 1.35
var layers: Array[Node3D] = []
var clock := 0.0
var halos: Array[MeshInstance3D] = []
var sign_sources: Array[Dictionary] = []
var spill_lights: Array[SpotLight3D] = []
var night_local: Node3D
var passing_train_enabled := false
var effects_enabled := true
var rng := RandomNumberGenerator.new()
var building_material: ShaderMaterial
var window_material: ShaderMaterial
var trim_material: StandardMaterial3D
var tube_materials: Array[StandardMaterial3D] = []
var metal_material: StandardMaterial3D
var facade_transforms: Dictionary = {}
var facade_colors: Dictionary = {}
var hotel_relief:SurfaceTool

func build() -> void:
 set_meta("solid_geometry_exclude",true)
 building_material = ShaderMaterial.new()
 building_material.shader = MASONRY
 metal_material = StandardMaterial3D.new()
 metal_material.vertex_color_use_as_albedo = true
 metal_material.roughness = 0.38
 metal_material.metallic = 0.55
 window_material = ShaderMaterial.new()
 window_material.shader = WINDOWS
 trim_material = StandardMaterial3D.new()
 trim_material.albedo_color = Color("101a21")
 trim_material.roughness = 0.3
 trim_material.metallic = 0.5
 for tint in SIGN_COLORS:
  var material := StandardMaterial3D.new()
  material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
  material.albedo_color = tint.lightened(0.45)
  tube_materials.append(material)
 for layer_index in range(3):
  var layer := Node3D.new()
  layer.name = "CityParallax%d" % layer_index
  add_child(layer)
  layers.append(layer)
  facade_transforms.clear()
  facade_colors.clear()
  if layer_index==0:
   hotel_relief=SurfaceTool.new()
   hotel_relief.begin(Mesh.PRIMITIVE_TRIANGLES)
  # The 134 m district wraps beyond the camera's 80 m range. Every section
  # repeats its seed, so the wrap never substitutes a different frontage.
  for section in range(-2,2):
   rng.seed = 90621 + layer_index * 73
   for side in [-1,1]:
    var lots: int = [8,6,4][layer_index]
    for i in range(lots):
     var width := rng.randf_range(1000,1480)*(1.0+layer_index*0.30)
     var depth := rng.randf_range(650,1050)+layer_index*280.0
     var front: float = [1180.0,2540.0,4140.0][layer_index]+rng.randf_range(0,180+layer_index*70)
     var floor_pitch := rng.randf_range(300,325)
     var floors := rng.randi_range(3,8)+layer_index*5
     var z := section*PERIOD+i*PERIOD/lots+rng.randf_range(-75,75)
     facade(layer,side,layer_index,i,front,z,width,depth,floors,floor_pitch)
  for group in facade_transforms:
   var material: Material = window_material if group == "Windows" else (metal_material if group == "Metal" else building_material)
   batch(layer,facade_transforms[group],facade_colors[group],material,group)
  if layer_index==0: HotelRelief.attach(layer,hotel_relief.commit())
 build_salon_spill()
 night_local = NightLocal.new()
 add_child(night_local)
 night_local.build()
 update_passing_train()
 set_meta("facade_scale",{"floor_pitch_cm":Vector2(300,325),"upper_window_height_cm":Vector2(160,190),"upper_window_width_cm":Vector2(90,115),"minimum_frontage_cm":1000,"nearest_wall_cm":1180,"district_period_cm":PERIOD})

func facade_box(group: String, size: Vector3, p: Vector3, color: Color) -> void:
 if not facade_transforms.has(group):
  var transforms: Array[Transform3D] = []
  var colors: Array[Color] = []
  facade_transforms[group] = transforms
  facade_colors[group] = colors
 facade_transforms[group].append(Transform3D(Basis.from_scale(size),p))
 facade_colors[group].append(color)

func facade(layer: Node3D, side: int, layer_index: int, index: int, front: float, z: float, width: float, depth: float, floors: int, pitch: float) -> void:
 var height := floors*pitch
 var stone: Color = [Color("3b4140"),Color("42433b"),Color("473d38"),Color("364147")][index%4]
 stone = stone.darkened(layer_index*0.16)
 var frame := Color("243034").darkened(layer_index*0.15)
 var cornice := stone.lightened(0.10/(1+layer_index))
 # Main mass sits behind the glazing. The train-facing wall is assembled from
 # piers and spandrels, leaving actual 22 cm recesses rather than painted panes.
 facade_box("Stone",Vector3(depth-50,height,width),Vector3(side*(front+(depth+50)*0.5),STREET_LEVEL+height*0.5,z),stone.darkened(0.08))
 var columns := clampi(int(width/215),4,10)
 var bay := width/columns
 var window_width := rng.randf_range(90,115)
 var window_height := rng.randf_range(160,190)
 for storey in range(floors):
  var base := STREET_LEVEL+storey*pitch
  var shop := storey == 0 and layer_index == 0 and index%3 != 0
  var opening_width := bay-44 if shop else window_width
  var opening_height := 222.0 if shop else window_height
  var sill_height := 26.0 if shop else 67.0
  facade_box("Stone",Vector3(32,sill_height,width),Vector3(side*(front+16),base+sill_height*0.5,z),stone)
  var top_band := pitch-sill_height-opening_height
  facade_box("Stone",Vector3(32,top_band,width),Vector3(side*(front+16),base+pitch-top_band*0.5,z),stone)
  for divider in range(columns+1):
   var pier_width := (bay-opening_width)*(0.5 if divider in [0,columns] else 1.0)
   var pier_z := z-width*0.5+divider*bay
   if divider == 0: pier_z += pier_width*0.5
   elif divider == columns: pier_z -= pier_width*0.5
   facade_box("Stone",Vector3(32,pitch,pier_width),Vector3(side*(front+16),base+pitch*0.5,pier_z),stone)
  for column in range(columns):
   var wz := z-width*0.5+(column+0.5)*bay
   var wy := base+sill_height+opening_height*0.5
   var lit := rng.randf() > (0.35 if shop else 0.64)
   var pane_color := Color("cbb68e") if rng.randf() > 0.27 else Color("95b4b8")
   pane_color *= rng.randf_range(0.34,0.64)/(1.0+layer_index*0.65) if lit else 0.075/(1.0+layer_index*0.45)
   pane_color.a = rng.randf_range(0.1,0.95)
   facade_box("Windows",Vector3(2,opening_height-6,opening_width-6),Vector3(side*(front+23),wy,wz),pane_color)
   for dz in [-1,1]:
    facade_box("Metal",Vector3(22,opening_height,4),Vector3(side*(front+11),wy,wz+dz*(opening_width*0.5-2)),frame)
   for dy in [-1,1]:
    facade_box("Metal",Vector3(22,4,opening_width),Vector3(side*(front+11),wy+dy*(opening_height*0.5-2),wz),frame)
   if shop or (index+column)%3 == 0:
    facade_box("Metal",Vector3(6,opening_height,3.2),Vector3(side*(front+19),wy,wz),frame)
   if not shop and (index+storey+column)%3 != 1:
    facade_box("Metal",Vector3(6,3.5,opening_width),Vector3(side*(front+19),wy+opening_height*0.17,wz),frame)
   # Projecting sill, shadow reveal and an occasional lintel rather than a
   # single identical grid stamped over the whole skyline.
   facade_box("Stone",Vector3(45,10,opening_width+22),Vector3(side*(front+5),base+sill_height-3,wz),cornice)
   if layer_index == 0 and (index+column)%2 == 0:
    facade_box("Stone",Vector3(38,13,opening_width+29),Vector3(side*(front+7),base+sill_height+opening_height+7,wz),cornice)
   if layer_index == 0 and storey in [1,3] and column == columns/2 and index%3 == 1:
    balcony(side,front,base+sill_height,wz,opening_width+90,frame,cornice)
  if storey == 0 or (storey+index)%3 == 0:
   facade_box("Stone",Vector3(48,12,width+16),Vector3(side*(front+3),base+pitch-8,z),cornice)
 # A shaped cornice, parapet and setback service housing finish the silhouette.
 for tier in range(3):
  facade_box("Stone",Vector3(45+tier*8,12,width+16+tier*10),Vector3(side*(front+2-tier*3),STREET_LEVEL+height-8+tier*10,z),cornice)
 facade_box("Stone",Vector3(28,74,width),Vector3(side*(front+18),STREET_LEVEL+height+45,z),stone)
 if index%2 == 0:
  facade_box("Stone",Vector3(220,170,width*0.32),Vector3(side*(front+depth*0.62),STREET_LEVEL+height+85,z+width*0.14),stone.darkened(0.16))
  facade_box("Metal",Vector3(236,10,width*0.32+18),Vector3(side*(front+depth*0.62),STREET_LEVEL+height+174,z+width*0.14),frame)
 if layer_index == 0:
  # Railway-side pavement and a stone curb anchor every frontage to the street.
  facade_box("Stone",Vector3(225,16,width+80),Vector3(side*(front-96),STREET_LEVEL-8,z),stone.darkened(0.18))
  facade_box("Stone",Vector3(22,26,width+80),Vector3(side*(front-205),STREET_LEVEL-3,z),cornice.darkened(0.18))
  if index in [1,4,7]:
   var sign_at:=Vector3(side*(front-12),STREET_LEVEL+pitch-38,z-width*0.16)
   neon_sign(layer,sign_at,side,(index+int(side)+3)%3,index)
   if index==1: HotelRelief.append_batch(hotel_relief,side,sign_at)

func balcony(side: int, front: float, y: float, z: float, width: float, metal: Color, stone: Color) -> void:
 facade_box("Stone",Vector3(94,12,width),Vector3(side*(front-35),y-5,z),stone)
 for h in [22,102]:
  facade_box("Metal",Vector3(4,4,width-6),Vector3(side*(front-79),y+h,z),metal)
 for rail in range(int(width/18)+1):
  var rz := z-width*0.5+5+rail*(width-10)/int(width/18)
  facade_box("Metal",Vector3(2.5,98,2.5),Vector3(side*(front-79),y+51,rz),metal)
 for end in [-1,1]:
  facade_box("Metal",Vector3(80,4,4),Vector3(side*(front-39),y+102,z+end*(width*0.5-4)),metal)

func batch(parent: Node3D, transforms: Array[Transform3D], colors: Array[Color], material: Material, group: String = "City") -> void:
 var mesh := BoxMesh.new()
 mesh.size = Vector3.ONE
 var multimesh := MultiMesh.new()
 multimesh.transform_format = MultiMesh.TRANSFORM_3D
 multimesh.use_colors = true
 multimesh.mesh = mesh
 multimesh.instance_count = transforms.size()
 multimesh.set_meta("solid_geometry_transforms",transforms.duplicate())
 for i in range(transforms.size()):
  multimesh.set_instance_transform(i,transforms[i])
  multimesh.set_instance_color(i,colors[i])
 var instance := MultiMeshInstance3D.new()
 instance.name = group
 instance.multimesh = multimesh
 instance.material_override = material
 instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 parent.add_child(instance)

func block(parent: Node3D, size: Vector3, position3: Vector3, material: Material) -> MeshInstance3D:
 var mesh := preload("res://scripts/prop_meshes.gd").rounded(size,1.2)
 var instance := MeshInstance3D.new()
 instance.mesh = mesh
 instance.position = position3
 instance.material_override = material
 instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 parent.add_child(instance)
 return instance

func neon_sign(parent: Node3D, position3: Vector3, side: int, palette: int, index: int) -> void:
 # One seed-identical district repeat supplies motion for all lit signs.
 if position3.z>=0 and position3.z<PERIOD:
  sign_sources.append({"z":position3.z,"side":side,"tint":SIGN_COLORS[palette]})
 var sign_root := Node3D.new()
 parent.add_child(sign_root)
 sign_root.position = position3
 # Sign local +Z points toward the train; X is horizontal along the railway.
 sign_root.rotation.y = -side*PI*0.5
 block(sign_root,Vector3(244,84,8),Vector3.ZERO,trim_material)
 for x in [-82,82]:
  block(sign_root,Vector3(8,67,15),Vector3(x,0,-9),trim_material)
 var tube := tube_materials[palette]
 var tube_frame := MeshInstance3D.new()
 tube_frame.mesh = preload("res://scripts/prop_meshes.gd").rounded_loop(220,64,7,0.9)
 tube_frame.rotation.x = PI/2
 tube_frame.position.z = 5.2
 tube_frame.material_override = tube
 tube_frame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 sign_root.add_child(tube_frame)
 var text := Label3D.new()
 text.text = "HOTEL" if index == 1 else ("NIGHT CAFE" if index == 4 else "PHARMACIE")
 text.font = preload("res://assets/Interface.ttf")
 text.font_size = 56
 text.pixel_size = 0.65 if index == 1 else 0.47
 text.modulate = tube.albedo_color
 text.outline_size = 0
 text.position = Vector3(0,1,6.5)
 text.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 sign_root.add_child(text)
 var quad := QuadMesh.new()
 quad.size = Vector2(366.7,106.7)
 var halo := MeshInstance3D.new()
 halo.mesh = quad
 halo.position = Vector3(0,0,7.5)
 halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material := ShaderMaterial.new()
 material.shader = HALO
 material.set_shader_parameter("neon_color",SIGN_COLORS[palette])
 material.set_shader_parameter("frame_ratio",Vector2(1.0,1.0))
 material.set_shader_parameter("sign_phase",float(index*7+side))
 halo.material_override = material
 sign_root.add_child(halo)
 halos.append(halo)
 # Small reflected tint on the wet wall beneath each sign, no scene lights.
 var reflection := MeshInstance3D.new()
 reflection.mesh = quad
 reflection.position = Vector3(0,-70,5.8)
 reflection.scale = Vector3(0.62,0.55,1)
 var reflection_material := material.duplicate() as ShaderMaterial
 reflection_material.set_shader_parameter("wall_reflection",true)
 reflection.material_override = reflection_material
 reflection.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 sign_root.add_child(reflection)
 halos.append(reflection)

func build_salon_spill() -> void:
 # Two restrained, non-shadowed lights stay in a single window bay, facing
 # the sill and nearby furniture, not the evidence at the inner tables.
 for side in [-1,1]:
  var spill := SpotLight3D.new()
  spill.name = "PassingNeonLeft" if side == -1 else "PassingNeonRight"
  spill.light_energy = 0.0
  spill.shadow_enabled = false
  spill.spot_range = 145.0
  spill.spot_attenuation = 1.2
  spill.spot_angle = 61.0
  add_child(spill)
  spill.position = Vector3(side*502,178,SALON_BAY_Z)
  spill.look_at(Vector3(side*397,116,SALON_BAY_Z))
  spill_lights.append(spill)

func sample_salon_sign(side: int, district_offset: float) -> Dictionary:
 var closest := INF
 var tint := Color.WHITE
 for sign_source in sign_sources:
  if sign_source.side != side: continue
  var distance := absf(fposmod(sign_source.z+district_offset-SALON_BAY_Z+PERIOD*0.5,PERIOD)-PERIOD*0.5)
  if distance < closest:
   closest = distance
   tint = sign_source.tint
 var signal_strength := 1.0-smoothstep(30.0,455.0,closest)
 return {"energy":MAX_SPILL_ENERGY*signal_strength*signal_strength,"tint":Color("e5e8eb").lerp(tint,0.58)}

func update_salon_spill(district_offset: float) -> void:
 if not effects_enabled: return
 for i in range(spill_lights.size()):
  var sample := sample_salon_sign(-1 if i==0 else 1,district_offset)
  spill_lights[i].light_color = sample.tint
  spill_lights[i].light_energy = sample.energy

func set_effects_enabled(enabled: bool) -> void:
 effects_enabled = enabled
 update_passing_train()
 for halo in halos: halo.visible = enabled
 for spill in spill_lights:
  spill.visible = enabled
  if not enabled: spill.light_energy = 0.0
 if enabled: update_salon_spill(fposmod(clock*TRAIN_SPEED,PERIOD))

func set_passing_train_enabled(enabled: bool) -> void:
 if enabled == passing_train_enabled: return
 passing_train_enabled = enabled
 update_passing_train()

func update_passing_train() -> void:
 if is_instance_valid(night_local):
  night_local.set_ambient_enabled(effects_enabled and passing_train_enabled)

func observe_salon_view(viewer: Vector3,forward: Vector3) -> void:
 if effects_enabled and passing_train_enabled and is_instance_valid(night_local):
  night_local.observe(viewer,forward,true)

func _process(delta: float) -> void:
 clock += delta
 if is_instance_valid(night_local) and night_local.in_motion: night_local.advance(delta)
 var district_offset := fposmod(clock*TRAIN_SPEED,PERIOD)
 update_salon_spill(district_offset)
 if building_material != null:
  building_material.set_shader_parameter("district_offset",district_offset)
 for i in range(layers.size()):
  # One physical translation; farther rows cross the view more slowly because
  # of their distance, without sliding independently across the same street.
  layers[i].position.z = district_offset
