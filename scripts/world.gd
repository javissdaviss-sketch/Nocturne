extends Node3D
## Hand-built procedural scenery, centimetre world units. No runtime asset downloads.
const Data = preload("res://scripts/case_data.gd")
const LEAF_TEXTURE = preload("res://assets/textures/palm_leaf_albedo.png")
const TABLE_TEXTURE = preload("res://assets/textures/table_mahogany_albedo.png")
const BROCADE_TEXTURE = preload("res://assets/textures/botanical_brocade_albedo.png")
const CABIN_FINISH = preload("res://shaders/cabin_surfaces.gdshader")
const RUNNER_FINISH = preload("res://shaders/nocturne_runner.gdshader")
const SolidGeometry = preload("res://scripts/solid_geometry.gd")
var solid_geometry = SolidGeometry.new()
var collision_stats: Dictionary = {}
const CarriageIdentity = preload("res://scripts/carriage_identity.gd")
const ResidentialProps = preload("res://scripts/residential_props.gd")
const HospitalityProps = preload("res://scripts/hospitality_props.gd")
const GardenProps = preload("res://scripts/garden_props.gd")
const LivedInDetails = preload("res://scripts/lived_in_details.gd")
const Exterior = preload("res://scripts/exterior.gd")
const RainWindows = preload("res://scripts/rain_windows.gd")
const TrainLayout = preload("res://scripts/train_layout.gd")
const Atmosphere = preload("res://scripts/atmosphere.gd")
const CyberLuxe = preload("res://scripts/cyber_luxe.gd")
const InteriorBatches = preload("res://scripts/interior_batches.gd")
const CeramicProfiles = preload("res://scripts/ceramic_profiles.gd")
const HeroAssets = preload("res://scripts/hero_assets.gd")
var rain_windows: Node3D
var atmosphere: Node3D
var environment: Environment
var materials: Dictionary = {}
var cushion_meshes: Dictionary = {}
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
 m.roughness = 0.52 if metal == 0 else 0.28
 if c == CREAM:
  m.roughness = 0.22
  m.clearcoat_enabled = true
  m.clearcoat = 0.35
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
 if kind in [0,2]: material.set_shader_parameter("wood_texture",TABLE_TEXTURE)
 if kind == 3: material.set_shader_parameter("brocade_texture",BROCADE_TEXTURE)
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
 m.radial_segments = 32
 m.rings = 16
 var o := mesh_obj(parent,m,p,c,false,0,glow)
 o.scale = size * 0.5
 return o

func cushion(p: Vector3, size: Vector3, color: Color, bevel: float = 2.0, parent: Node3D = self, tufted: bool = false) -> MeshInstance3D:
 # Shared, smoothly rounded upholstery; recesses are geometry rather than decals.
 var key := str(size)+str(bevel)+str(tufted)
 if not cushion_meshes.has(key):
  cushion_meshes[key] = preload("res://scripts/upholstery_geometry.gd").build(size,bevel,tufted)
 var node := mesh_obj(parent,cushion_meshes[key],p,color)
 node.material_override = cabin_finish(1,color)
 return node

func cyl(p: Vector3, radius: float, height: float, c: Color, solid: bool = true, parent: Node3D = self, top: float = -1.0, metal: float = 0.0) -> MeshInstance3D:
 var m := CylinderMesh.new()
 m.top_radius = radius if top < 0 else top
 m.bottom_radius = radius
 m.height = height
 m.radial_segments = 48
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
 for prop_script in [ResidentialProps,HospitalityProps,GardenProps]:
  var props: Node3D = prop_script.new()
  add_child(props)
  props.build()
 var rooms := TrainLayout.new()
 add_child(rooms)
 rooms.build(self)
 var luxe := CyberLuxe.new()
 add_child(luxe)
 luxe.build_interior(self,rooms)
 make_hotspots()
 collision_stats = solid_geometry.build(self,[scenery,rain_windows,atmosphere])
 var exclusions: Array[Node] = [scenery,rain_windows,atmosphere,cabinet_door,drawer]
 for palm in palms: exclusions.append(palm)
 InteriorBatches.new().build(self,exclusions)

func make_environment() -> void:
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color("09131f")
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("b6c8c4")
 e.ambient_light_energy = 0.34
 e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 if RenderingServer.get_current_rendering_method() == "forward_plus":
  e.ssao_enabled = true
  e.ssao_radius = 16.0
  e.ssao_intensity = 1.25
  e.ssao_power = 1.3
  e.ssao_detail = 0.6
  e.ssil_enabled = true
  e.ssil_radius = 80.0
  e.ssil_intensity = 0.7
  e.glow_enabled = true
  e.glow_intensity = 0.35
  e.glow_bloom = 0.02
  e.glow_hdr_threshold = 1.6
 # Depth fog begins beyond the cabin so nearby evidence stays crisp.
 e.fog_enabled = true
 e.fog_mode = Environment.FOG_MODE_DEPTH
 e.fog_light_color = Color("132636")
 e.fog_light_energy = 0.35
 e.fog_density = 0.00025
 e.fog_depth_begin = 550.0
 e.fog_depth_end = 3500.0
 e.fog_depth_curve = 1.25
 environment = e
 env.environment = e
 add_child(env)
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-52,-35,0)
 sun.light_color = Color("96bfc9")
 sun.light_energy = 0.24
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
 var shade := Color("432d25") if index != 2 else Color("233d35")
 box(Vector3(0,-5,z+400),Vector3(1020,10,800),WOOD).material_override = cabin_finish(0,Color("66503c"))
 # Floor joints belong to the finish, not raised bars that catch a 6 mm fly.
 box(Vector3(0,0.8,z+400),Vector3(110,1.2,780),Color.WHITE).material_override = runner_finish(index)
 for side in [-1,1]:
  box(Vector3(side*58,1.5,z+400),Vector3(1,0.4,780),GOLD,false)
  box(Vector3(side*511,45,z+400),Vector3(7,90,800),shade).material_override = cabin_finish(2,shade)
  box(Vector3(side*511,273,z+400),Vector3(7,44,800),shade)
  box(Vector3(side*507,94,z+400),Vector3(3,3,800),GOLD,false, self,0.6)
  box(Vector3(side*507,249,z+400),Vector3(3,3,800),GOLD,false, self,0.6)
  # Invisible window collision: clear views, sealed train.
  var wall := StaticBody3D.new()
  var shape := CollisionShape3D.new()
  var cube := BoxShape3D.new()
  cube.size = Vector3(2,160,800)
  shape.shape = cube
  add_child(wall)
  wall.add_child(shape)
  wall.position = Vector3(side*514,174,z+400)
  for j in range(5):
   var pz := z+40+j*170
   box(Vector3(side*508,173,pz),Vector3(10,155,8),GOLD, true,self,0.65)
   box(Vector3(side*506,170,pz+84),Vector3(2,2,158),GOLD,false)
  for j in [40,380,720]:
   var p := Vector3(side*497,216,z+j)
   box(p+Vector3(side*3,0,0),Vector3(8,33,20),WOOD,false)
   box(p,Vector3(7,25,12),GOLD,false,self,0.65)
   ball(p+Vector3(-side*5,0,0),Vector3(14,21,14),Color("ffe3a5"),self,0.45)
   for dz in [-5,0,5]:
    line(p+Vector3(-side*11,-10,dz),p+Vector3(-side*11,10,dz),0.45,GOLD)
   for y in [-11,11]:
    box(p+Vector3(-side*5,y,0),Vector3(15,1.3,16),GOLD,false,self,0.7)
   light_at(p+Vector3(-side*15,0,0),Color("ffd69e"),1.4,220)
 for j in [0,800]:
  box(Vector3(-282,144,z+j),Vector3(456,290,10),shade)
  box(Vector3(282,144,z+j),Vector3(456,290,10),shade)
  box(Vector3(0,258,z+j),Vector3(110,74,10),shade)
  for side in [-1,1]: box(Vector3(side*56,113,z+j-7),Vector3(3,226,5),GOLD,false,self,0.7)
  box(Vector3(0,224,z+j-7),Vector3(115,3,5),GOLD,false,self,0.7)
 if index < 2:
  box(Vector3(0,-3,z+820),Vector3(112,6,40),Color("202e32"))
  for side in [-1,1]: box(Vector3(side*58,115,z+820),Vector3(6,230,40),Color("283a3b"))
  box(Vector3(0,233,z+820),Vector3(120,6,40),Color("283a3b"))
 if index == 0: box(Vector3(0,110,-4),Vector3(108,220,8),Color("1a3337"))
 if index == 2: box(Vector3(0,110,z+804),Vector3(108,220,8),Color("1a3337"))
 if index != 2: box(Vector3(0,297,z+400),Vector3(1020,6,800),CREAM).material_override = cabin_finish(4,Color("c1ae8d"))
 else:
  box(Vector3(0,297,z+400),Vector3(1020,6,800),Color("233e43"))
 for j in range(7):
  var rz := z+35+j*121
  for side in [-1,1]:
   box(Vector3(side*487,263,rz),Vector3(35,3,4),GOLD,false)
   var rib := box(Vector3(side*458,279,rz),Vector3(36,3,4),GOLD,false)
   rib.rotation.z = side*0.48
  box(Vector3(0,287,rz),Vector3(889,3,4),GOLD,false)
 for side in [-1,1]: box(Vector3(side*78,291,z+400),Vector3(2,2,780),Color("e2bf89"),false,self,0,1.3)
 if index == 0: sign_text("05  ←   RESIDENT ACCESS ONLY",Vector3(0,160,2),0.25,GOLD)
 if index == 2: sign_text("09  →   RESIDENT ACCESS ONLY",Vector3(0,160,z+797),0.25,GOLD)

func table_material() -> ShaderMaterial:
 if materials.has("table_mahogany"): return materials["table_mahogany"]
 var material := ShaderMaterial.new()
 material.shader = CABIN_FINISH
 material.set_shader_parameter("finish",5)
 material.set_shader_parameter("wood_texture",TABLE_TEXTURE)
 materials["table_mahogany"] = material
 return material

func table_slab(p: Vector3, size: Vector3) -> void:
 # Retained for callers needing a single softened, veneered slab.
 var slab := cushion(p,size,Color.WHITE,minf(size.y*0.25,1.5))
 slab.material_override = table_material()

func table(p: Vector3, width: float = 72, depth: float = 72) -> void:
 var model := Node3D.new()
 model.name = "CraftedWalnutTable"
 add_child(model)
 model.position = p
 preload("res://scripts/furniture_models.gd").table(self,model,width,depth)

func seat(p: Vector3, color: Color = TEAL) -> Node3D:
 var model := Node3D.new()
 model.name = "TuftedParlourChair"
 add_child(model)
 model.position = p
 p = Vector3.ZERO
 var timber := Color("493328")
 var models = preload("res://scripts/furniture_models.gd")
 # An open, crafted frame replaces the solid rectangular base.
 for x in [-25,25]:
  for z in [-24,24]:
   var profile := PackedVector2Array([Vector2(0,1.8),Vector2(4,2.1),Vector2(5,1.7),Vector2(20,1.8),Vector2(24,2.6),Vector2(27,3.0),Vector2(30,2.7),Vector2(34,2.7)])
   mesh_obj(model,models.lathe(profile),p+Vector3(x,0,z),timber).material_override = cabin_finish(2,timber)
   cyl(p+Vector3(x,3,z),2.1,6,GOLD,true,model,-1,0.65)
 for z in [-27,27]:
  mesh_obj(model,models.apron(56,11,3),p+Vector3(0,29,z),timber).material_override = cabin_finish(2,timber)
 for x in [-27,27]:
  var side_apron := mesh_obj(model,models.apron(54,11,3),p+Vector3(x,29,0),timber)
  side_apron.material_override = cabin_finish(2,timber)
  side_apron.rotation.y = PI/2
 cushion(p+Vector3(0,41,-2.5),Vector3(64,12,60),color,2.5,model)
 models.timber_back(self,model,p+Vector3(0,63,28),Vector2(64,63))
 var back := cushion(p+Vector3(0,63,20),Vector3(56,55,9),color,3,model,true)
 back.rotation.x = -0.08
 for x in [-27,27]:
  cyl(p+Vector3(x,43,-25),2.3,22,timber,true,model,2.8).material_override = cabin_finish(2,timber)
  mesh_obj(model,models.arm(7,5,55),p+Vector3(x,45,0),timber).material_override = cabin_finish(2,timber)
  mesh_obj(model,models.arm(10,12,60),p+Vector3(x,51,0),color).material_override = cabin_finish(1,color)
 # Covered buttons sit inside the modeled depressions of the tilted back.
 var back_basis := Basis(Vector3.RIGHT,-0.08)
 for x in [-18,0,18]:
  for y in [-11,10]:
   ball(p+Vector3(0,63,20)+back_basis*Vector3(x,y,-3.4),Vector3(1.8,1.8,0.65),color.darkened(0.12),model)
 # Welt cord follows the seat's rounded front corners rather than a straight rod.
 var path: Array[Vector3] = []
 for corner in [Vector2(-27.5,-28),Vector2(27.5,-28),Vector2(27.5,23),Vector2(-27.5,23)]:
  var start_angle: float = [-PI,-PI/2,0.0,PI/2][path.size()/7]
  for i in range(7):
   var angle: float = start_angle+float(i)*PI/12
   path.append(p+Vector3(corner.x+cos(angle)*4.55,40.5,corner.y+sin(angle)*4.55))
 for i in range(path.size()): line(path[i],path[(i+1)%path.size()],0.20,color.lightened(0.12),model)
 # A shallow brass crest gives the chair a tailored top outline.
 for segment in range(12):
  var xa := -27.0+segment*4.5
  var xb := xa+4.5
  line(p+Vector3(xa,92.7-4.5*pow(xa/27,2),23),p+Vector3(xb,92.7-4.5*pow(xb/27,2),23),0.30,GOLD,model)
 return model

func leaf_material(dark: bool) -> StandardMaterial3D:
 var key := "palm_leaf_dark" if dark else "palm_leaf_light"
 if materials.has(key): return materials[key]
 var m := StandardMaterial3D.new()
 m.albedo_texture = LEAF_TEXTURE
 m.albedo_color = Color("68866b") if dark else Color("88a17b")
 m.roughness = 0.78
 m.metallic_specular = 0.24
 # Keep the source texture and explicit UVs on every authored leaf surface.
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
 return preload("res://scripts/palm_geometry.gd").spine(along,length,lift)

func palm_rib(parent: Node3D, length: float, lift: float) -> void:
 mesh_obj(parent,preload("res://scripts/palm_geometry.gd").rib(length,lift),Vector3.ZERO,Color("526747"))

func plant(p: Vector3, height: float = 100, spread: float = 35) -> void:
 var forms = preload("res://scripts/palm_geometry.gd")
 mesh_obj(self,preload("res://scripts/garden_fixture_geometry.gd").pot_mesh(41,27),p,Color("926c53"))
 cyl(p+Vector3(0,28,0),21,2,Color("292e25"),false)
 var crown_height := height*0.83
 var cane := mesh_obj(self,forms.cane(crown_height),p,Color("4e5139"))
 cane.name = "OrganicPalmCane"
 cane.material_override = forms.bark_material()
 var crown := Node3D.new()
 add_child(crown)
 crown.position = p+Vector3(0,crown_height,0)
 palms.append(crown)
 # Older outer fronds droop; upright young fronds fill the crown with a varied fan.
 for j in range(11):
  var frond := Node3D.new()
  crown.add_child(frond)
  frond.rotation.y = j*TAU/11+rng.randf_range(-0.16,0.16)
  frond.rotation.z = sin(j*1.7)*0.055
  var length := spread*rng.randf_range(0.90,1.16)
  var lift: float = length*([0.98,0.52,0.38,0.70][j%4]+rng.randf_range(-0.055,0.055))
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  palm_rib(frond,length,lift)
  for pair in range(1,16):
   var along := float(pair)/17
   var base := palm_spine(along,length,lift)
   var blade_length := length*0.46*pow(1.0-along,0.53)*(0.92+0.08*sin(pair*1.7+j))
   for side in [-1,1]:
    var phase: float = pair*1.3+j*0.6+side*0.5
    var tip := base+Vector3(side*blade_length,-blade_length*(0.15+0.09*sin(phase)),blade_length*(0.38+0.10*cos(phase)))
    forms.blade(surface,base,tip,maxf(0.85,blade_length*0.25),0.15+float(pair%5)*0.16,phase)
  forms.blade(surface,palm_spine(0.84,length,lift),palm_spine(1.07,length,lift),length*0.065,0.5,float(j))
  surface.generate_normals()
  var leaves := MeshInstance3D.new()
  leaves.name = "CurvedPalmLeaflets"
  leaves.mesh = surface.commit()
  leaves.material_override = leaf_material(j%3 != 0)
  frond.add_child(leaves)

func residential() -> void:
 for z in [140,470]:
  seat(Vector3(-119,0,z+52),Color("5d555f"))
  table(Vector3(-104,0,z),91,57)
  plant(Vector3(-131,0,z+130),130,38)
 table(Vector3(-104,0,285),91,65)
 table(Vector3(107,0,285),90,90)
 var chaise := preload("res://scripts/furniture_models.gd").build_chaise(self,self,Vector3(160,0,70))
 chaise.rotation.y = PI/2
 # Writing desk and handwritten note.
 box(Vector3(-102,77,285),Vector3(22,0.5,29),Color("e7d8b2"))
 var note := sign_text("Mara —\nReturn the cuttings.\nOr I report you at dawn.\n— Elias",Vector3(-102,77.4,285),0.055,Color("493e3c"))
 note.rotation_degrees.x = -90
 cyl(Vector3(-130,84,292),3,15,GOLD)
 ball(Vector3(-130,94,292),Vector3(18,12,18),Color("c88d6b"))
 light_at(Vector3(-128,100,292),Color("ffe0b7"),0.9,90)
 # Maintenance terminal.
 table(Vector3(107,0,655),94,67)
 HeroAssets.terminal(self,self,Vector3(102,83,655))
 HeroAssets.framed_photo(self,self,Vector3(-102,77,470))
 plant(Vector3(240,0,275),160,44)
 plant(Vector3(133,0,600),160,44)

func dining() -> void:
 for z in [1050,1250,1450]:
  table(Vector3(-110,0,z),101,102)
  for end in [-1,1]:
   var chair := seat(Vector3(-220,0,z+end*70),TEAL)
   var toward_table := Vector3(-110,0,z)-chair.position
   chair.rotation.y = atan2(-toward_table.x,-toward_table.z)
  mesh_obj(self,CeramicProfiles.plate_mesh(),Vector3(-101,78,z),CREAM)
  for px in [-139,-62]:
   line(Vector3(px,78,z-17),Vector3(px,78,z+17),0.6,GOLD)
  cyl(Vector3(-127,87,z+28),3,18,Color("6a8b7b"),false,self,2)
 HeroAssets.evidence_cup(self,self,Vector3(-88,78,1250))
 # The dining roll is the scored, continuous model placed by hospitality props.
 # A continuous opaque sheet keeps the scene discreet, with gravity-shaped folds.
 HeroAssets.covered_scene(self,self,Vector3(-100,0,1345))
 # Service counter and cabinet.
 # Hollow cabinet: fly-sized cable access beneath the front door.
 HeroAssets.rounded(self,self,Vector3(159,43,1476),Vector3(4,86,129),0.5,Color("214b49"))
 for side_z in [1412,1540]:
  var end_panel: MeshInstance3D = preload("res://scripts/cabinet_assets.gd").framed_panel(self,self,Vector3(122,43,side_z),Vector3(77,86,4))
  if side_z > 1480: end_panel.rotation.y = PI
 HeroAssets.rounded(self,self,Vector3(122,2.5,1476),Vector3(77,5,129),0.8,Color("214b49"))
 HeroAssets.rounded(self,self,Vector3(122,35,1476),Vector3(77,3,129),0.4,Color("214b49"))
 HeroAssets.rounded(self,self,Vector3(122,88,1476),Vector3(83,5,135),1.2,Color("bea783"))
 cabinet_door = preload("res://scripts/cabinet_assets.gd").framed_panel(self,self,Vector3(82,47,1460),Vector3(73,68,3))
 cabinet_door.rotation.y = PI/2
 # Stationary frame closes the remainder of the front, leaving only the authored
 # cable opening below Y13 and the actual moving door when it is released.
 HeroAssets.rounded(self,self,Vector3(82,47,1418.75),Vector3(3,68,9.4),0.3,Color("4d3328"))
 var fixed_front: MeshInstance3D = preload("res://scripts/cabinet_assets.gd").framed_panel(self,self,Vector3(82,47,1517.25),Vector3(41.4,68,3))
 fixed_front.rotation.y = PI/2
 HeroAssets.rounded(self,self,Vector3(82,83.5,1480),Vector3(4,5,132),0.6,Color("4d3328"))
 # Tiny cable duct is a real gap beneath the door, with an accessible contact.
 line(Vector3(65,2,1395),Vector3(65,2,1455),0.8,Color("dc976b"))
 line(Vector3(65,2,1455),Vector3(104,11,1460),0.8,Color("dc976b"))
 box(Vector3(104,10,1460),Vector3(3,1,4),GOLD,false)
 box(Vector3(104,11,1460),Vector3(1.2,0.4,1.2),Color("72d9bc"),false,self,0,1)
 # Bottle stands behind cabinet door.
 HeroAssets.chemical_bottle(self,self,Vector3(121,36.5,1460))
 for z in [940,1438]: plant(Vector3(250,0,z),175,40)
 for z in [1095,1320]:
  HeroAssets.side_table(self,self,Vector3(135,0,z))

func conservatory() -> void:
 for side in [-1,1]:
  for z in [1770,1950,2150,2360]:
   var palm_position := Vector3(side*(245 if z == 1770 or z == 2150 or z == 2360 else 125),0,z)
   if side == 1 and z == 2150:
    # Keep the mature crown and its pot clear of Lian's head and the next bed.
    palm_position = Vector3(205,0,2140)
   plant(palm_position,rng.randf_range(135,205),40)
  for z in [1880,2070,2260]:
   var planter := preload("res://scripts/garden_fixture_geometry.gd").new()
   add_child(planter)
   # The middle bed ends before the compartment partition, leaving the
   # botanist's standing space clear without moving the person or hotspot.
   var planter_x := 165 if z == 2070 else (240 if z == 1880 or (side == 1 and z == 2260) else 134)
   planter.build_planter(Vector3(side*planter_x,0,2008 if z == 2070 else z))
   planter.rotation.y = PI/2
   planter.scale = Vector3(0.30 if z == 2070 else 0.95,0.78,0.725)
 for z in [1830,2080,2290]:
  plant(Vector3(-245 if z == 2080 else -89,0,z),110,29)
  if z == 2080:
   # A compact specimen in the rear margin replaces the pot through Lian's feet.
   plant(Vector3(245,0,2400),135,20)
  else:
   plant(Vector3(245 if z == 2290 else 97,0,z+40),135,31)
 table(Vector3(108,0,1905),95,100)
 box(Vector3(102,80,1905),Vector3(17,0.5,23),Color("d9c399"))
 var tag := sign_text("OR-031 / M. SABLE\nLIVING SPECIMENS\nLEAF > MOON > DROP",Vector3(102,80.4,1905),0.032,Color("343f36"))
 tag.rotation_degrees.x = -90
 for j in range(3):
  cyl(Vector3(123+j*5,81,1877),1.5,5,Color("b88860"))
  line(Vector3(123+j*5,84,1877),Vector3(123+j*5,94,1877),0.4,Color("4a9c66"))
 table(Vector3(-100,0,2235),95,95)
 drawer = HeroAssets.dispatch_cover(self,self,Vector3(-100,80,2235))
 HeroAssets.ledger(self,self,Vector3(-100,79.1,2235))
 # Orchid displayed on pedestal.
 cyl(Vector3(-100,40,2020),19,80,Color("35564e"))
 cyl(Vector3(-100,82,2020),11,5,Color("9e8862"))
 line(Vector3(-100,85,2020),Vector3(-100,126,2020),0.65,Color("639678"))
 for j in range(5):
  var a := j*TAU/5
  var petal := ball(Vector3(-100+cos(a)*7,124+sin(a)*7,2020),Vector3(9,5,2),Color("e3d4dc"))
  petal.rotation.z = a
 ball(Vector3(-100,124,2019),Vector3(3,3,3),Color("d5b365"))

func human(p: Vector3, coat: Color, hair: Color, name_text: String, hotspot_id: String = "") -> void:
 var n: Node3D = preload("res://scripts/resident_assets.gd").build(self,self,p,coat,hair)
 n.set_meta("hotspot_id",hotspot_id)
 var badge := sign_text(name_text,Vector3(0,180,0),0.18,GOLD,n)
 badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED

func people() -> void:
 human(Vector3(112,0,530),Color("697c80"),Color("292a2a"),"IVO / ENGINEERING","engineer")
 human(Vector3(113,0,1150),Color("863f54"),Color("242d30"),"MARA / HOSPITALITY","steward")
 human(Vector3(112,0,2110),Color("a99068"),Color("b6b3a1"),"LIAN / BOTANY","botanist")

func make_hotspots() -> void:
 for source in [Data.CLUES,Data.TALKS,Data.PROPS]:
  for id in source:
   var r: Dictionary = source[id]
   var p: Array = r.point
   hotspots[id] = {"position":Vector3(p[0],p[1],p[2]),"record":r}

func unlock_cabinet() -> void:
 cabinet_door.visible = false
 HeroAssets.set_colliders(cabinet_door,false)

func unlock_dispatch() -> void:
 drawer.visible = false
 HeroAssets.set_colliders(drawer,false)
 var writing := sign_text("ORCHID CUTTINGS\nOR-031 / M. SABLE\nVALE HAS NOTICED",Vector3(-100,81.3,2235),0.038,CREAM)
 writing.rotation_degrees.x = -90

func _process(delta: float) -> void:
 t += delta
 for i in range(palms.size()): palms[i].rotation.z = sin(t*0.45+i)*0.012
