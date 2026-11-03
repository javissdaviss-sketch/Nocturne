extends Node3D
## Hand-built procedural scenery, centimetre world units. No runtime asset downloads.
const Data = preload("res://scripts/case_data.gd")
const LEAF_TEXTURE = preload("res://assets/textures/palm_leaf_albedo.png")
const TABLE_TEXTURE = preload("res://assets/textures/table_mahogany_albedo.png")
const CABIN_FINISH = preload("res://shaders/cabin_surfaces.gdshader")
const RUNNER_FINISH = preload("res://shaders/nocturne_runner.gdshader")
const CarriageIdentity = preload("res://scripts/carriage_identity.gd")
const LivedInDetails = preload("res://scripts/lived_in_details.gd")
const Exterior = preload("res://scripts/exterior.gd")
const RainWindows = preload("res://scripts/rain_windows.gd")
const Atmosphere = preload("res://scripts/atmosphere.gd")
var rain_windows: Node3D
var atmosphere: Node3D
var environment: Environment
var materials: Dictionary = {}
var hotspots: Dictionary = {}
var scenery: Node3D
var cabinet_door: MeshInstance3D
var drawer: MeshInstance3D
var rng := RandomNumberGenerator.new()
var palms: Array[Node3D] = []
var t := 0.0
const GOLD = Color("c6a46c")
const TEAL = Color("205451")
const WOOD = Color("403029")
const CREAM = Color("e0d3b7")

func mat(c: Color, metal: float = 0.0, glow: float = 0.0) -> StandardMaterial3D:
 var key := str(c)+str(metal)+str(glow)
 if materials.has(key): return materials[key]
 var m := StandardMaterial3D.new()
 m.albedo_color = c
 m.metallic = metal
 m.roughness = 0.55 if metal == 0 else 0.3
 if glow > 0:
  m.emission_enabled = true
  m.emission = c
  m.emission_energy_multiplier = glow
 materials[key] = m
 return m

func cabin_finish(kind: int, color: Color) -> ShaderMaterial:
 var key := "cabin_%d_%s" % [kind,str(color)]
 if materials.has(key): return materials[key]
 var material := ShaderMaterial.new()
 material.shader = CABIN_FINISH
 material.set_shader_parameter("finish",kind)
 material.set_shader_parameter("finish_color",color)
 materials[key] = material
 return material

func runner_finish(index: int) -> ShaderMaterial:
 var key := "runner_%d" % index
 if materials.has(key): return materials[key]
 var material := ShaderMaterial.new()
 material.shader = RUNNER_FINISH
 material.set_shader_parameter("wool_color",Color("613e39") if index == 2 else Color("234740"))
 material.set_shader_parameter("thread_color",Color("b9985c"))
 materials[key] = material
 return material

func mesh_obj(parent: Node3D, mesh: Mesh, p: Vector3, color: Color, solid: bool = false, metal: float = 0.0, glow: float = 0.0) -> MeshInstance3D:
 var o := MeshInstance3D.new()
 o.mesh = mesh
 o.material_override = mat(color, metal, glow)
 parent.add_child(o)
 o.position = p
 if solid: o.create_trimesh_collision()
 return o

func box(p: Vector3, size: Vector3, c: Color, solid: bool = true, parent: Node3D = self, metal: float = 0.0, glow: float = 0.0) -> MeshInstance3D:
 var m := BoxMesh.new()
 m.size = size
 return mesh_obj(parent,m,p,c,solid,metal,glow)

func ball(p: Vector3, size: Vector3, c: Color, parent: Node3D = self, glow: float = 0.0) -> MeshInstance3D:
 var m := SphereMesh.new()
 m.radius = 1.0
 m.height = 2.0
 m.radial_segments = 16
 m.rings = 8
 var o := mesh_obj(parent,m,p,c,false,0,glow)
 o.scale = size * 0.5
 return o

func cyl(p: Vector3, radius: float, height: float, c: Color, solid: bool = true, parent: Node3D = self, top: float = -1.0, metal: float = 0.0) -> MeshInstance3D:
 var m := CylinderMesh.new()
 m.top_radius = radius if top < 0 else top
 m.bottom_radius = radius
 m.height = height
 m.radial_segments = 20
 return mesh_obj(parent,m,p,c,solid,metal)

func line(a: Vector3, b: Vector3, radius: float, c: Color, parent: Node3D = self) -> MeshInstance3D:
 var o := cyl((a+b)*0.5,radius,a.distance_to(b),c,false,parent)
 var direction := (b-a).normalized()
 o.quaternion = Quaternion(Vector3.UP,direction)
 return o

func sign_text(text: String, p: Vector3, size: float = 1.0, color: Color = CREAM, parent: Node3D = self) -> Label3D:
 var l := Label3D.new()
 l.text = text
 l.font = preload("res://assets/Interface.ttf")
 l.font_size = 48
 l.pixel_size = size / 4.0
 l.modulate = color
 l.outline_size = 0
 l.no_depth_test = false
 parent.add_child(l)
 l.position = p
 return l

func light_at(p: Vector3, c: Color, energy: float, reach: float) -> OmniLight3D:
 var l := OmniLight3D.new()
 add_child(l)
 l.position = p
 l.light_color = c
 l.light_energy = energy * 24.0
 l.omni_range = reach
 l.omni_attenuation = 0.75
 l.shadow_enabled = false
 return l

func _ready() -> void:
 rng.seed = 4312
 make_environment()
 rain_windows = RainWindows.new()
 add_child(rain_windows)
 for i in range(3):
  carriage(i)
  rain_windows.add_carriage(i)
 atmosphere = Atmosphere.new()
 add_child(atmosphere)
 residential()
 dining()
 conservatory()
 people()
 var identity := CarriageIdentity.new()
 add_child(identity)
 identity.build()
 var details := LivedInDetails.new()
 add_child(details)
 details.build()
 make_hotspots()

func make_environment() -> void:
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color("09131f")
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("9aaeb9")
 e.ambient_light_energy = 0.36
 e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 # Depth fog begins beyond the cabin so nearby evidence stays crisp.
 e.fog_enabled = true
 e.fog_mode = Environment.FOG_MODE_DEPTH
 e.fog_light_color = Color("132636")
 e.fog_light_energy = 0.7
 e.fog_depth_begin = 550.0
 e.fog_depth_end = 3500.0
 e.fog_depth_curve = 1.25
 environment = e
 env.environment = e
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-52,-35,0)
 sun.light_color = Color("96bfc9")
 sun.light_energy = 0.6
 sun.shadow_enabled = true
 sun.directional_shadow_max_distance = 4500
 add_child(sun)
 scenery = Exterior.new()
 add_child(scenery)
 scenery.build()

func set_atmosphere_enabled(enabled: bool) -> void:
 if is_instance_valid(rain_windows): rain_windows.visible = enabled
 if is_instance_valid(atmosphere): atmosphere.set_enabled(enabled)
 if environment != null: environment.fog_enabled = enabled
 if is_instance_valid(scenery): scenery.set_effects_enabled(enabled)

func carriage(index: int) -> void:
 var z := float(index)*840.0
 var shade := Color("243d39") if index != 1 else Color("233f44")
 box(Vector3(0,-5,z+400),Vector3(340,10,800),WOOD).material_override = cabin_finish(0,Color("66503c"))
 for x in range(-160,161,20):
  box(Vector3(x,0.15,z+400),Vector3(0.65,0.3,800),Color("866a4b"),false)
 for j in range(12):
  box(Vector3(0,0.25,z+j*68+10),Vector3(340,0.25,0.5),Color("241f1e"),false)
 box(Vector3(0,0.8,z+400),Vector3(110,1.2,780),Color.WHITE).material_override = runner_finish(index)
 for side in [-1,1]:
  box(Vector3(side*58,1.5,z+400),Vector3(1,0.4,780),GOLD,false)
  box(Vector3(side*171,45,z+400),Vector3(7,90,800),shade).material_override = cabin_finish(2,shade)
  box(Vector3(side*171,273,z+400),Vector3(7,44,800),shade)
  box(Vector3(side*167,94,z+400),Vector3(3,3,800),GOLD,false, self,0.6)
  box(Vector3(side*167,249,z+400),Vector3(3,3,800),GOLD,false, self,0.6)
  # Invisible window collision: clear views, sealed train.
  var wall := StaticBody3D.new()
  var shape := CollisionShape3D.new()
  var cube := BoxShape3D.new()
  cube.size = Vector3(2,160,800)
  shape.shape = cube
  add_child(wall)
  wall.add_child(shape)
  wall.position = Vector3(side*174,174,z+400)
  for j in range(5):
   var pz := z+40+j*170
   box(Vector3(side*168,173,pz),Vector3(10,155,8),GOLD, true,self,0.65)
   box(Vector3(side*166,170,pz+84),Vector3(2,2,158),GOLD,false)
  for j in [120,450,700]:
   var p := Vector3(side*157,216,z+j)
   box(p,Vector3(7,25,12),GOLD,false,self,0.65)
   ball(p+Vector3(-side*5,0,0),Vector3(14,21,14),Color("ffe3a5"),self,1.5)
   light_at(p+Vector3(-side*15,0,0),Color("ffd69e"),1.4,220)
 for j in [0,800]:
  box(Vector3(-112,144,z+j),Vector3(116,290,10),shade)
  box(Vector3(112,144,z+j),Vector3(116,290,10),shade)
  box(Vector3(0,258,z+j),Vector3(110,74,10),shade)
  for side in [-1,1]: box(Vector3(side*56,113,z+j-7),Vector3(3,226,5),GOLD,false,self,0.7)
  box(Vector3(0,224,z+j-7),Vector3(115,3,5),GOLD,false,self,0.7)
 if index < 2:
  box(Vector3(0,-3,z+820),Vector3(112,6,40),Color("202e32"))
  for side in [-1,1]: box(Vector3(side*58,115,z+820),Vector3(6,230,40),Color("283a3b"))
  box(Vector3(0,233,z+820),Vector3(120,6,40),Color("283a3b"))
 if index == 0: box(Vector3(0,110,-4),Vector3(108,220,8),Color("1a3337"))
 if index == 2: box(Vector3(0,110,z+804),Vector3(108,220,8),Color("1a3337"))
 if index != 2: box(Vector3(0,297,z+400),Vector3(340,6,800),Color("253733"))
 else:
  box(Vector3(0,297,z+400),Vector3(340,6,800),Color("233e43"))
 for j in range(7):
  var rz := z+35+j*121
  for side in [-1,1]:
   box(Vector3(side*147,263,rz),Vector3(35,3,4),GOLD,false)
   var rib := box(Vector3(side*118,279,rz),Vector3(36,3,4),GOLD,false)
   rib.rotation.z = side*0.48
  box(Vector3(0,287,rz),Vector3(209,3,4),GOLD,false)
 for side in [-1,1]: box(Vector3(side*78,291,z+400),Vector3(2,2,780),Color("e2bf89"),false,self,0,1.3)
 if index == 0: sign_text("05  ←   RESIDENT ACCESS ONLY",Vector3(0,160,2),0.25,GOLD)
 if index == 2: sign_text("09  →   RESIDENT ACCESS ONLY",Vector3(0,160,z+797),0.25,GOLD)

func table_material() -> StandardMaterial3D:
 if materials.has("table_mahogany"): return materials["table_mahogany"]
 var material := StandardMaterial3D.new()
 material.albedo_texture = TABLE_TEXTURE
 material.roughness = 0.48
 material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 materials["table_mahogany"] = material
 return material

func table_slab(p: Vector3, size: Vector3) -> void:
 var slab := box(p,size,Color.WHITE)
 var arrays := slab.mesh.surface_get_arrays(0)
 var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
 var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
 # Use centimetres for consistent grain scale on every table. The photograph's
 # vertical grain follows the longest tabletop axis; edges keep the same scale.
 for i in range(vertices.size()):
  var point := vertices[i]+size*0.5
  if abs(normals[i].y) > 0.5:
   uvs[i] = Vector2(point.z,point.x)/80.0 if size.x >= size.z else Vector2(point.x,point.z)/80.0
  elif abs(normals[i].x) > 0.5:
   uvs[i] = Vector2(point.y,point.z)/80.0
  else:
   uvs[i] = Vector2(point.y,point.x)/80.0
 arrays[Mesh.ARRAY_TEX_UV] = uvs
 var mesh := ArrayMesh.new()
 mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 slab.mesh = mesh
 slab.material_override = table_material()

func table(p: Vector3, width: float = 72, depth: float = 72) -> void:
 table_slab(p+Vector3(0,74,0),Vector3(width,5,depth))
 table_slab(p+Vector3(0,77,0),Vector3(width-3,0.8,depth-3))
 for x in [-1,1]:
  for z in [-1,1]: cyl(p+Vector3(x*(width/2-8),36,z*(depth/2-8)),2,72,GOLD,true,self,-1,0.5)

func seat(p: Vector3, color: Color = TEAL) -> void:
 box(p+Vector3(0,22,0),Vector3(64,42,65),color).material_override = cabin_finish(1,color)
 var back := box(p+Vector3(0,63,27),Vector3(64,63,12),color)
 back.material_override = cabin_finish(1,color)
 back.rotation.x = -0.08
 for x in [-27,27]: box(p+Vector3(x,41,0),Vector3(9,19,61),color).material_override = cabin_finish(1,color)
 for x in [-20,0,20]: box(p+Vector3(x,60,19.8),Vector3(0.5,43,0.5),GOLD,false)
 for x in [-23,23]: cyl(p+Vector3(x,5,-20),2,10,GOLD)

func leaf_material(dark: bool) -> StandardMaterial3D:
 var key := "palm_leaf_dark" if dark else "palm_leaf_light"
 if materials.has(key): return materials[key]
 var m := StandardMaterial3D.new()
 m.albedo_texture = LEAF_TEXTURE
 m.albedo_color = Color("b7cfb5") if dark else Color.WHITE
 m.roughness = 0.65
 # Explicit leaf UVs keep the photographed vertical veins running base to tip.
 m.cull_mode = BaseMaterial3D.CULL_DISABLED
 m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
 materials[key] = m
 return m

func palm_blade(surface: SurfaceTool, base: Vector3, tip: Vector3, width: float, stripe: float) -> void:
 # A folded, tapering ribbon: U crosses the blade; V follows its entire length.
 # Each leaflet samples a narrow band of the photo, avoiding compressed veins.
 var axis := (tip-base).normalized()
 var across := axis.cross(Vector3.UP).normalized()
 var sections := 7
 for segment in range(sections):
  var points: Array[Vector3] = []
  var uvs: Array[Vector2] = []
  for row in range(2):
   var along := float(segment+row)/sections
   var center := base.lerp(tip,along)+Vector3.UP*sin(along*PI)*width*0.3
   var half_width := width*pow(sin(along*PI),0.7)*0.5
   for edge in [-1,0,1]:
    points.append(center+across*half_width*edge-Vector3.UP*abs(edge)*half_width*0.18)
    uvs.append(Vector2(stripe+float(edge)*0.055,along))
  for index in [0,3,1,1,3,4,1,4,2,2,4,5]:
   surface.set_uv(uvs[index])
   surface.add_vertex(points[index])

func palm_spine(along: float, length: float, lift: float) -> Vector3:
 return Vector3(0,lift*sin(along*PI*0.8)-length*0.30*along*along,length*along)

func palm_rib(parent: Node3D, length: float, lift: float) -> void:
 # One mesh per curved midrib keeps the richer foliage affordable to render.
 var cylinder := CylinderMesh.new()
 cylinder.top_radius = 0.35
 cylinder.bottom_radius = 0.35
 cylinder.height = 1.0
 cylinder.radial_segments = 8
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for segment in range(8):
  var a := palm_spine(float(segment)/8,length,lift)
  var b := palm_spine(float(segment+1)/8,length,lift)
  var delta := b-a
  var basis := Basis(Quaternion(Vector3.UP,delta.normalized()))*Basis.from_scale(Vector3(1,delta.length(),1))
  surface.append_from(cylinder,0,Transform3D(basis,(a+b)*0.5))
 mesh_obj(parent,surface.commit(),Vector3.ZERO,Color("748c43"))

func plant(p: Vector3, height: float = 100, spread: float = 35) -> void:
 cyl(p+Vector3(0,14,0),17,28,Color("a77758"),true,self,22)
 cyl(p+Vector3(0,28,0),21,2,Color("292e25"),false)
 # Slender, ringed palm cane below a crown of arching feather fronds.
 var crown_height := height*0.83
 cyl(p+Vector3(0,(28+crown_height)*0.5,0),2.8,crown_height-28,Color("89764d"),false,self,1.8)
 for ring in range(35,int(crown_height),8):
  cyl(p+Vector3(0,ring,0),2.85,0.65,Color("635a3b"),false)
 var crown := Node3D.new()
 add_child(crown)
 crown.position = p+Vector3(0,crown_height,0)
 palms.append(crown)
 for j in range(9):
  var frond := Node3D.new()
  crown.add_child(frond)
  frond.rotation.y = j*TAU/9+rng.randf_range(-0.15,0.15)
  var length := spread*rng.randf_range(0.88,1.10)
  var lift := length*(0.85 if j%3 == 0 else 0.48)
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  palm_rib(frond,length,lift)
  for pair in range(1,11):
   var along := float(pair)/12
   var base := palm_spine(along,length,lift)
   var blade_length := length*0.45*pow(1.0-along,0.55)
   for side in [-1,1]:
    var tip := base+Vector3(side*blade_length,-blade_length*0.22,blade_length*0.45)
    palm_blade(surface,base,tip,blade_length*0.16,0.15+float(pair%5)*0.16)
  palm_blade(surface,palm_spine(0.8,length,lift),palm_spine(1.06,length,lift),length*0.06,0.5)
  surface.generate_normals()
  var leaves := MeshInstance3D.new()
  leaves.mesh = surface.commit()
  leaves.material_override = leaf_material(j%2 == 1)
  frond.add_child(leaves)

func residential() -> void:
 for z in [140,470]:
  seat(Vector3(-119,0,z+52),Color("5d555f"))
  table(Vector3(-104,0,z),91,57)
  plant(Vector3(-131,0,z+130),130,38)
 table(Vector3(-104,0,285),91,65)
 table(Vector3(107,0,285),90,90)
 box(Vector3(107,58,95),Vector3(103,115,115),Color("20494a"))
 box(Vector3(107,119,95),Vector3(99,7,112),Color("b2a18b"))
 for z in [60,90,120]: box(Vector3(107,125,z),Vector3(81,8,24),Color("c7b99e"))
 # Writing desk and handwritten note.
 box(Vector3(-102,77,285),Vector3(22,0.5,29),Color("e7d8b2"))
 var note := sign_text("Mara —\nReturn the cuttings.\nOr I report you at dawn.\n— Elias",Vector3(-102,77.4,285),0.055,Color("493e3c"))
 note.rotation_degrees.x = -90
 cyl(Vector3(-130,84,292),3,15,GOLD)
 ball(Vector3(-130,94,292),Vector3(18,12,18),Color("c88d6b"))
 light_at(Vector3(-128,100,292),Color("ffe0b7"),0.9,90)
 # Maintenance terminal.
 table(Vector3(107,0,655),94,67)
 box(Vector3(102,83,655),Vector3(29,9,22),Color("283e42"))
 box(Vector3(102,88,655),Vector3(26,1,19),Color("72bda9"),false,self,0,0.8)
 var terminal := sign_text("AXLE 12 · I. CHEN\n22:10 — 22:36\nAUTHENTICATED",Vector3(102,88.6,655),0.04,Color("153a35"))
 terminal.rotation_degrees.x = -90
 box(Vector3(-102,77,470),Vector3(18,1,23),GOLD)
 box(Vector3(-102,77.6,470),Vector3(15,0.3,20),Color("678e88"),false)
 for z in [120,600]: plant(Vector3(133,0,z),160,44)

func dining() -> void:
 for z in [1050,1250,1450]:
  table(Vector3(-101,0,z),101,102)
  seat(Vector3(-110,0,z-75),TEAL)
  var chair := Node3D.new()
  add_child(chair)
  chair.position = Vector3(-110,0,z+75)
  # Reverse chair using a locally transformed group.
  var count := get_child_count()
  seat(Vector3(-110,0,z+75),TEAL)
  var generated := get_children().slice(count)
  for item in generated:
   if item is Node3D:
    var old: Vector3 = item.position
    remove_child(item)
    chair.add_child(item)
    item.position = Vector3(old.x+110,old.y,old.z-z-75)
  chair.rotation.y = PI
  cyl(Vector3(-101,78,z),25,0.8,CREAM,false).mesh.radial_segments = 64
  for px in [-139,-62]:
   line(Vector3(px,78,z-17),Vector3(px,78,z+17),0.6,GOLD)
  cyl(Vector3(-127,87,z+28),3,18,Color("6a8b7b"),false,self,2)
 # Cup: open cylinder constructed from fine ceramic segments.
 var cup := Vector3(-88,78,1250)
 cyl(cup+Vector3(0,0.4,0),6.5,0.8,CREAM)
 for j in range(32):
  var a := j*TAU/32
  var part := box(cup+Vector3(cos(a)*4.4,4.5,sin(a)*4.4),Vector3(0.65,8,1.05),CREAM)
  part.rotation.y = -a
 cyl(cup+Vector3(0,4,0),4.0,0.2,Color("593c31"),false)
 for j in range(11):
  var a := float(j)*0.56
  ball(cup+Vector3(cos(a)*3.6,4.3,sin(a)*3.6),Vector3(0.75,0.5,0.7),Color("aa6cbd"))
 var handle := TorusMesh.new()
 handle.inner_radius = 1.4
 handle.outer_radius = 2.1
 var h := mesh_obj(self,handle,cup+Vector3(6,4.8,0),GOLD,false,0.6)
 h.rotation.x = PI/2
 # Pastry.
 for j in range(7):
  ball(Vector3(-95+(j-3)*2.3,81,1050+pow(float(j-3),2)*0.4),Vector3(4,6,9),Color("bb854b"))
 # Covered body, discreet stylization.
 ball(Vector3(-100,45,1345),Vector3(36,30,69),Color("d3cfb9"))
 ball(Vector3(-100,47,1313),Vector3(22,22,22),Color("d3cfb9"))
 box(Vector3(-100,28,1345),Vector3(40,25,85),TEAL)
 # Service counter and cabinet.
 # Hollow cabinet: fly-sized cable access beneath the front door.
 box(Vector3(159,43,1480),Vector3(4,86,137),Color("214b49"))
 for side_z in [1412,1548]: box(Vector3(122,43,side_z),Vector3(77,86,4),Color("214b49"))
 box(Vector3(122,2.5,1480),Vector3(77,5,137),Color("214b49"))
 box(Vector3(122,35,1480),Vector3(77,3,137),Color("214b49"))
 box(Vector3(122,88,1480),Vector3(83,5,143),Color("bea783"))
 cabinet_door = box(Vector3(82,47,1460),Vector3(3,68,73),Color("315f59"))
 box(Vector3(79,53,1435),Vector3(2,16,2),GOLD,false)
 # Tiny cable duct is a real gap beneath the door, with an accessible contact.
 line(Vector3(65,2,1395),Vector3(65,2,1455),0.8,Color("dc976b"))
 line(Vector3(65,2,1455),Vector3(104,11,1460),0.8,Color("dc976b"))
 box(Vector3(104,10,1460),Vector3(3,1,4),GOLD,false)
 box(Vector3(104,11,1460),Vector3(1.2,0.4,1.2),Color("72d9bc"),false,self,0,1)
 # Bottle stands behind cabinet door.
 cyl(Vector3(121,43,1460),3.5,13,Color("80548f"))
 cyl(Vector3(121,51,1460),1.9,3,GOLD)
 box(Vector3(121,44,1456.4),Vector3(5,7,0.25),CREAM,false)
 sign_text("V9\nSABLE",Vector3(121,44,1456.1),0.025,Color("4c3650")).rotation.y = PI
 for z in [940,1580]: plant(Vector3(127,0,z),175,40)
 for z in [1110,1320]:
  box(Vector3(135,83,z),Vector3(53,6,57),Color("88684c"))
  cyl(Vector3(135,40,z),4,80,GOLD)

func conservatory() -> void:
 for side in [-1,1]:
  for z in [1770,1950,2150,2360]:
   plant(Vector3(side*125,0,z),rng.randf_range(135,205),40)
  box(Vector3(side*134,25,2070),Vector3(45,50,570),Color("41594b"))
 for z in [1830,2080,2290]:
  plant(Vector3(-89,0,z),110,29)
  plant(Vector3(97,0,z+40),135,31)
 table(Vector3(104,0,1905),95,100)
 box(Vector3(102,80,1905),Vector3(17,0.5,23),Color("d9c399"))
 var tag := sign_text("OR-031 / M. SABLE\nLIVING SPECIMENS\nLEAF > MOON > DROP",Vector3(102,80.4,1905),0.032,Color("343f36"))
 tag.rotation_degrees.x = -90
 for j in range(3):
  cyl(Vector3(123+j*5,81,1877),1.5,5,Color("b88860"))
  line(Vector3(123+j*5,84,1877),Vector3(123+j*5,94,1877),0.4,Color("4a9c66"))
 table(Vector3(-100,0,2235),95,95)
 drawer = box(Vector3(-100,80,2235),Vector3(44,8,34),Color("244945"))
 box(Vector3(-100,85,2220),Vector3(29,1,6),GOLD,false)
 box(Vector3(-100,80.5,2235),Vector3(25,1,29),Color("6b3d37"))
 # Orchid displayed on pedestal.
 cyl(Vector3(-100,40,2020),19,80,Color("35564e"))
 cyl(Vector3(-100,82,2020),11,5,Color("9e8862"))
 line(Vector3(-100,85,2020),Vector3(-100,126,2020),0.65,Color("639678"))
 for j in range(5):
  var a := j*TAU/5
  var petal := ball(Vector3(-100+cos(a)*7,124+sin(a)*7,2020),Vector3(9,5,2),Color("e3d4dc"))
  petal.rotation.z = a
 ball(Vector3(-100,124,2019),Vector3(3,3,3),Color("d5b365"))

func human(p: Vector3, coat: Color, hair: Color, name_text: String) -> void:
 var n := Node3D.new()
 add_child(n)
 n.position = p
 # Humans remain life-size; the fly is 6mm long.
 for x in [-9,9]:
  cyl(Vector3(x,36,0),7,62,Color("283139"),false,n)
  ball(Vector3(x,7,-5),Vector3(14,12,27),Color("27252c"),n)
 cyl(Vector3(0,99,0),22,71,coat,false,n,16)
 ball(Vector3(0,151,-1),Vector3(29,35,28),Color("ad8870"),n)
 ball(Vector3(0,162,2),Vector3(30,19,29),hair,n)
 for side in [-1,1]:
  line(Vector3(side*20,127,0),Vector3(side*25,93,-6),6,coat,n)
  line(Vector3(side*25,93,-6),Vector3(side*17,77,-17),5,coat,n)
  ball(Vector3(side*17,77,-17),Vector3(9,12,9),Color("ad8870"),n)
 box(Vector3(0,110,-20),Vector3(2,40,1),GOLD,false,n)
 for y in [101,113,125]: ball(Vector3(5,y,-20),Vector3(2,2,1),GOLD,n)
 var badge := sign_text(name_text,Vector3(0,180,0),0.18,GOLD,n)
 badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func people() -> void:
 human(Vector3(112,0,530),Color("697c80"),Color("292a2a"),"IVO / ENGINEERING")
 human(Vector3(113,0,1150),Color("863f54"),Color("242d30"),"MARA / HOSPITALITY")
 human(Vector3(112,0,2110),Color("a99068"),Color("b6b3a1"),"LIAN / BOTANY")

func make_hotspots() -> void:
 for source in [Data.CLUES,Data.TALKS,Data.PROPS]:
  for id in source:
   var r: Dictionary = source[id]
   var p: Array = r.point
   hotspots[id] = {"position":Vector3(p[0],p[1],p[2]),"record":r}

func unlock_cabinet() -> void:
 cabinet_door.visible = false
 for child in cabinet_door.get_children():
  if child is StaticBody3D: child.collision_layer = 0

func unlock_dispatch() -> void:
 drawer.visible = false
 for child in drawer.get_children():
  if child is StaticBody3D: child.collision_layer = 0
 var writing := sign_text("ORCHID CUTTINGS\nOR-031 / M. SABLE\nVALE HAS NOTICED",Vector3(-100,81.3,2235),0.038,CREAM)
 writing.rotation_degrees.x = -90

func _process(delta: float) -> void:
 t += delta
 for i in range(palms.size()): palms[i].rotation.z = sin(t*0.45+i)*0.012
