extends "res://scripts/lived_in_details.gd"
## Constructed garden furniture: shaped joinery, open ceramic vessels, visible hardware.
## Call build_planter after adding this node to the interior; world compiles physics.
const Profiles = preload("res://scripts/ceramic_profiles.gd")
const Padding = preload("res://scripts/upholstery_geometry.gd")
const WOOD := Color("493c2d")
const INSET := Color("263f35")
const METAL := Color("88734d")
const FINISH = preload("res://shaders/cabin_surfaces.gdshader")
const SOIL := Color("191b12")

static func pot_mesh(diameter: float, height: float) -> ArrayMesh:
 var r := diameter*0.5
 return Profiles.lathe([
  Vector2(0.02,0.2),Vector2(r*0.62,0.2),Vector2(r*0.69,0.8),
  Vector2(r*0.70,2.0),Vector2(r*0.73,3.0),Vector2(r*0.90,height*0.65),
  Vector2(r*0.98,height-1.4),Vector2(r*1.05,height-0.8),Vector2(r*1.07,height+0.4),
  Vector2(r*1.04,height+1.0),Vector2(r*0.93,height+1.0),Vector2(r*0.90,height+0.4),
  Vector2(r*0.89,height-1.0),Vector2(r*0.81,height*0.65),Vector2(r*0.65,3.0),
  Vector2(r*0.58,2.2),Vector2(0.02,2.2)])

static func foot_mesh() -> ArrayMesh:
 return Profiles.lathe([Vector2(0.02,0),Vector2(3.5,0),Vector2(4.1,0.6),Vector2(4.0,1.7),Vector2(3.0,2.2),Vector2(2.5,4),Vector2(2.8,7.8),Vector2(3.7,9.5),Vector2(4.3,10),Vector2(4.3,12),Vector2(0.02,12)])

func rounded(key: String, p: Vector3, size: Vector3, color: Color, radius: float = 0.7, metal: bool = false) -> void:
 if not meshes.has(key): meshes[key] = Padding.build(size,radius)
 instance(key,p,Vector3.ONE,color,metal)

func build_planter(p: Vector3, size: Vector3 = Vector3(200,64,62)) -> void:
 name = "CraftedGardenPlanter"
 position = p
 var half := size*0.5
 meshes["turned_foot"] = foot_mesh()
 for x in [-half.x+13,half.x-13]:
  for z in [-half.z+11,half.z-11]:
   instance("turned_foot",Vector3(x,0,z),Vector3.ONE,METAL,true)
 # A substantial moulded plinth supports separate front, rear and end joinery.
 rounded("plinth",Vector3(0,14,0),Vector3(size.x-8,7,size.z-8),WOOD,1.3)
 rounded("plinth_bead",Vector3(0,18.1,0),Vector3(size.x-5,1.2,size.z-5),METAL,0.45,true)
 for side in [-1,1]:
  var z: float = side*(half.z-3.2)
  # Individual framed panels carry recessed, angled louvers rather than a box face.
  for section in [-1,0,1]:
   var x: float = section*(size.x-20)/3
   var panel_width := (size.x-30)/3
   rounded("panel_back",Vector3(x,39,z),Vector3(panel_width-1,34,1.8),INSET,0.5)
   for y in [23,55]:
    rounded("panel_rail",Vector3(x,y,z+side*1.5),Vector3(panel_width,2.5,2.8),WOOD,0.6)
   for dx in [-panel_width*0.5,panel_width*0.5]:
    rounded("panel_stile",Vector3(x+dx,39,z+side*1.5),Vector3(2.8,34,2.8),WOOD,0.6)
   for y in [29,34,39,44,49]:
    if not meshes.has("louver"): meshes["louver"] = Padding.build(Vector3(panel_width-6,3.3,2),0.4)
    instance("louver",Vector3(x,y,z+side*1.8),Vector3.ONE,INSET,false,Vector3(side*0.20,0,0))
   for dx in [-panel_width*0.5+3,panel_width*0.5-3]:
    for y in [25,53]: instance("sphere",Vector3(x+dx,y,z+side*3),Vector3(1.1,1.1,0.45),METAL,true)
  # Small framed blank specimen cartouche; the existing sensor overlays the front.
  rounded("cartouche",Vector3(0,46,z+side*3.3),Vector3(29,16,1.8),METAL,0.8,true)
  rounded("cartouche_inset",Vector3(0,46,z+side*4.25),Vector3(25,12,0.5),Color("20382f"),0.4)
 for x in [-half.x+5,half.x-5]:
  for z in [-half.z+5,half.z-5]:
   rounded("corner_post",Vector3(x,39,z),Vector3(6,43,6),WOOD,0.8)
   for y in [20,58]: rounded("post_collar",Vector3(x,y,z),Vector3(7,2,7),METAL,0.45,true)
 for side in [-1,1]:
  var x: float = side*(half.x-4.4)
  for z in [-18,-9,0,9,18]:
   rounded("end_slat",Vector3(x,39,z),Vector3(3.4,34,6.6),INSET,0.7)
  for y in [23,55]: rounded("end_rail",Vector3(x,y,0),Vector3(5,3.5,size.z-12),WOOD,0.7)
 # Rounded overhanging cap surrounds an inset basin, leaving a real open top.
 for side in [-1,1]:
  rounded("long_rim",Vector3(0,62,side*(half.z-2)),Vector3(size.x,6,5.5),WOOD,1.1)
  rounded("long_rim_inlay",Vector3(0,64.7,side*(half.z-2)),Vector3(size.x-5,0.6,0.8),METAL,0.2,true)
  rounded("end_rim",Vector3(side*(half.x-2),62,0),Vector3(5.5,6,size.z-8),WOOD,1.1)
 meshes["cultivated_soil"] = soil_mesh(size.x-10,size.z-10)
 instance("cultivated_soil",Vector3.ZERO,Vector3.ONE,SOIL)
 var rng := RandomNumberGenerator.new()
 rng.seed = 173
 for i in range(48):
  var x := rng.randf_range(-half.x+12,half.x-12)
  var z := rng.randf_range(-half.z+11,half.z-11)
  var radius := rng.randf_range(0.6,1.7)
  instance("sphere",Vector3(x,soil_height(x,z,size.x-10,size.z-10)+0.2,z),Vector3(radius*1.3,radius*0.55,radius),Color("262417") if i%4 else Color("3a3527"),false,Vector3(0,rng.randf()*TAU,0))
 # Drainage exits are formed tubes with open mouths, not painted circles.
 meshes["drain"] = Profiles.lathe([Vector2(1.6,0),Vector2(1.9,0.5),Vector2(1.9,3.5),Vector2(1.5,4),Vector2(1.1,4),Vector2(1.1,0)])
 for x in [-67,67]: instance("drain",Vector3(x,17,-half.z+1),Vector3.ONE,METAL,true,Vector3(PI/2,0,0))
 finish_batches()
 for key in materials:
  if str(key).begins_with(SOIL.to_html()+str(false)):
   var soil := StandardMaterial3D.new()
   soil.albedo_color = SOIL
   soil.roughness = 1.0
   soil.metallic_specular = 0.0
   materials[key] = soil
  if str(key).begins_with(WOOD.to_html()+str(false)):
   var material := ShaderMaterial.new()
   material.shader = FINISH
   material.set_shader_parameter("finish",2)
   material.set_shader_parameter("finish_color",WOOD)
   material.set_shader_parameter("wood_texture",preload("res://assets/textures/table_mahogany_albedo.png"))
   materials[key] = material
 for child in get_children():
  if child is MultiMeshInstance3D:
   var key := str(child.get_meta("detail_batch_key",str(child.name).trim_prefix("Details_")))
   child.material_override = materials[batches[key].material]
   child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

static func soil_height(x: float, z: float, width: float, depth: float) -> float:
 var edge := minf(width*0.5-absf(x),depth*0.5-absf(z))
 var bank := smoothstep(0,8,edge)
 return 60.8+bank*4.1+bank*(sin(x*0.37+sin(z*0.5))*0.32+sin(z*1.1+x*0.2)*0.17)

static func soil_mesh(width: float, depth: float) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(20):
  for column in range(64):
   for index in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var x := (float(column+index.x)/64-0.5)*width
    var z := (float(row+index.y)/20-0.5)*depth
    var dx := (soil_height(x+0.1,z,width,depth)-soil_height(x-0.1,z,width,depth))/0.2
    var dz := (soil_height(x,z+0.1,width,depth)-soil_height(x,z-0.1,width,depth))/0.2
    surface.set_normal(Vector3(-dx,1,-dz).normalized())
    surface.set_uv(Vector2(x,z)/16)
    surface.add_vertex(Vector3(x,soil_height(x,z,width,depth),z))
 return surface.commit()
