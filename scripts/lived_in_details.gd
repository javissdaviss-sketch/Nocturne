extends Node3D
## Prop visuals grouped by primitive/material; world compiles physical collision.
## All coordinates are centimetres. Preserve per-instance geometry for physics.
const BRASS := Color("bda374")
const CREAM := Color("ddd4bc")
const TEAL := Color("2d625e")
const DARK := Color("273a39")
const LINEN := Color("d1c7ac")
var batches: Dictionary = {}
var materials: Dictionary = {}
var meshes: Dictionary = {}
var detail_count := 0
const PropMeshes = preload("res://scripts/prop_meshes.gd")

func build() -> void:
 residential_details()
 dining_details()
 garden_details()
 finish_batches()

func finish_batches() -> void:
 for key in batches:
  var data: Dictionary = batches[key]
  var instances := MultiMesh.new()
  instances.transform_format = MultiMesh.TRANSFORM_3D
  instances.mesh = meshes[data.shape]
  instances.instance_count = data.transforms.size()
  # Keep CPU geometry available even with Godot's headless dummy renderer.
  instances.set_meta("solid_geometry_transforms",data.transforms.duplicate())
  for i in range(instances.instance_count):
   instances.set_instance_transform(i,data.transforms[i])
  var node := MultiMeshInstance3D.new()
  node.name = "Details_"+str(key)
  node.set_meta("detail_batch_key",key)
  node.multimesh = instances
  node.material_override = materials[data.material]
  # Modeled bodies and cloth cast shadows; thin trim remains a receiving surface.
  if data.shape in ["box","cylinder","sphere","ring","fine_ring"] or str(data.shape).begins_with("welt"):
   node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(node)

func material_id(color: Color, metal: bool, finish: int = -1) -> String:
 var key := color.to_html()+str(metal)+(str(finish) if finish >= 0 else "")
 if not materials.has(key):
  if finish >= 0:
   materials[key] = preload("res://scripts/material_library.gd").prop(finish,color)
   return key
  var material := StandardMaterial3D.new()
  material.albedo_color = color
  material.roughness = 0.28 if metal else 0.64
  material.metallic = 0.85 if metal else 0.0
  if color == CREAM:
   material.roughness = 0.23
   material.clearcoat_enabled = true
   material.clearcoat = 0.35
  materials[key] = material
 return key

func instance(shape: String, p: Vector3, size: Vector3, color: Color, metal: bool = false, rotation3: Vector3 = Vector3.ZERO, finish: int = -1) -> void:
 if not meshes.has(shape):
  if shape == "box":
   var mesh := BoxMesh.new()
   mesh.size = Vector3.ONE
   meshes[shape] = mesh
  elif shape == "cylinder":
   var mesh := CylinderMesh.new()
   mesh.top_radius = 0.5
   mesh.bottom_radius = 0.5
   mesh.height = 1.0
   mesh.radial_segments = 48
   meshes[shape] = mesh
  elif shape == "sphere":
   var mesh := SphereMesh.new()
   mesh.radius = 0.5
   mesh.height = 1.0
   mesh.radial_segments = 32
   mesh.rings = 16
   meshes[shape] = mesh
  elif shape == "ring":
   var mesh := TorusMesh.new()
   mesh.inner_radius = 0.39
   mesh.outer_radius = 0.5
   mesh.rings = 64
   mesh.ring_segments = 16
   meshes[shape] = mesh
  elif shape == "fine_ring":
   var mesh := TorusMesh.new()
   mesh.inner_radius = 0.485
   mesh.outer_radius = 0.5
   mesh.rings = 64
   mesh.ring_segments = 12
   meshes[shape] = mesh
 var material := material_id(color,metal,finish)
 var key := shape+material
 if not batches.has(key): batches[key] = {"shape":shape,"material":material,"transforms":[]}
 var basis := Basis.from_euler(rotation3)*Basis.from_scale(size)
 batches[key].transforms.append(Transform3D(basis,p))
 detail_count += 1

func rounded_box(p: Vector3, size: Vector3, color: Color, radius: float = 0.4, metal: bool = false, rotation3: Vector3 = Vector3.ZERO, finish: int = -1) -> void:
 var shape := "rounded"+str(size)+str(radius)
 if not meshes.has(shape): meshes[shape] = PropMeshes.rounded(size,radius)
 instance(shape,p,Vector3.ONE,color,metal,rotation3,finish)

func lathed(shape: String, profile: Array[Vector2], p: Vector3, color: Color, metal: bool = false, scale3: Vector3 = Vector3.ONE) -> void:
 if not meshes.has(shape): meshes[shape] = PropMeshes.lathe(profile,shape in ["tea_body","tea_lid","sugar_bowl","sugar_lid","coffee_body","coffee_lid","water_bottle"])
 instance(shape,p,scale3,color,metal)

func curved_tube(shape: String, path: Array[Vector3], radii: PackedFloat32Array, p: Vector3, color: Color, metal: bool = false, hollow: bool = false, rotation3: Vector3 = Vector3.ZERO) -> void:
 if not meshes.has(shape): meshes[shape] = PropMeshes.tube(path,radii,24,hollow)
 instance(shape,p,Vector3.ONE,color,metal,rotation3)

func welt(p: Vector3, width: float, depth: float, radius: float, cord: float, color: Color, rotation3: Vector3 = Vector3.ZERO, metal: bool = false) -> void:
 var shape := "welt"+str(Vector3(width,depth,radius))+str(cord)
 if not meshes.has(shape): meshes[shape] = PropMeshes.rounded_loop(width,depth,radius,cord)
 instance(shape,p,Vector3.ONE,color,metal,rotation3)

func linen(p: Vector3, width: float, depth: float, height: float, color: Color, rotation3: Vector3 = Vector3.ZERO) -> void:
 var shape := "linen"+str(Vector3(width,depth,height))
 if not meshes.has(shape): meshes[shape] = PropMeshes.linen(width,depth,height)
 instance(shape,p,Vector3.ONE,color,false,rotation3,2)

func box(p: Vector3, size: Vector3, color: Color, metal: bool = false, rotation_y: float = 0.0) -> void:
 instance("box",p,size,color,metal,Vector3(0,rotation_y,0))

func cyl(p: Vector3, diameter: float, height: float, color: Color, metal: bool = false) -> void:
 instance("cylinder",p,Vector3(diameter,height,diameter),color,metal)

func rod(a: Vector3, b: Vector3, diameter: float, color: Color, metal: bool = false) -> void:
 var direction := (b-a).normalized()
 var rotation3 := Quaternion(Vector3.UP,direction).get_euler()
 instance("cylinder",(a+b)*0.5,Vector3(diameter,a.distance_to(b),diameter),color,metal,rotation3)

func suitcase(p: Vector3, size: Vector3, color: Color) -> void:
 var bevel := minf(size.y*0.11,2.4)
 # Separate molded lid and deep body have a real recessed closing seam.
 rounded_box(p+Vector3(0,size.y*0.5,size.z*0.125),Vector3(size.x,size.y,size.z*0.75-0.12),color,bevel,false,Vector3.ZERO,0)
 rounded_box(p+Vector3(0,size.y*0.5,-size.z*0.375),Vector3(size.x,size.y,size.z*0.25-0.12),color.lightened(0.035),bevel,false,Vector3.ZERO,0)
 for z in [-size.z*0.5-0.04,-size.z*0.25,size.z*0.5+0.04]:
  welt(p+Vector3(0,size.y*0.5,z),size.x-1.4,size.y-1.4,bevel,0.16,color.lightened(0.18),Vector3(PI/2,0,0))
 for x in [-size.x*0.28,size.x*0.28]:
  rounded_box(p+Vector3(x,size.y+0.08,0),Vector3(2.0,0.24,size.z-2),color.darkened(0.19),0.1,false,Vector3.ZERO,0)
  rounded_box(p+Vector3(x,size.y*0.5,-size.z*0.5-0.08),Vector3(2.0,size.y-2,0.24),color.darkened(0.19),0.1,false,Vector3.ZERO,0)
  welt(p+Vector3(x,size.y*0.58,-size.z*0.5-0.32),2.8,3.9,0.5,0.22,BRASS,Vector3(PI/2,0,0),true)
  rod(p+Vector3(x,size.y*0.58-1.3,-size.z*0.5-0.4),p+Vector3(x,size.y*0.58+1.3,-size.z*0.5-0.4),0.18,BRASS,true)
  for y in [2.3,size.y-2.3]:
   instance("sphere",p+Vector3(x,y,-size.z*0.5-0.25),Vector3(0.65,0.65,0.24),BRASS,true)
 for side in [-1,1]:
  rounded_box(p+Vector3(side*4,size.y+0.3,-2),Vector3(2,0.6,2.4),BRASS,0.35,true)
 var handle_path: Array[Vector3] = []
 for j in range(25):
  var t := float(j)/24
  handle_path.append(Vector3(lerpf(-4,4,t),size.y+0.65+sin(t*PI)*3.6,-2))
 curved_tube("luggage_handle"+str(size.y),handle_path,PackedFloat32Array([0.68]),p,color.darkened(0.3))
 # Fitted corner caps are separate from the leather shells.
 for x in [-1,1]:
  for y in [-1,1]:
   for z in [-1,1]:
    var signs := Vector3(x,y,z)
    var shape := "case_corner"+str(signs)+str(bevel)
    if not meshes.has(shape): meshes[shape] = PropMeshes.fitted_corner(bevel,signs)
    instance(shape,p+Vector3(x*(size.x*0.5-bevel),size.y*0.5+y*(size.y*0.5-bevel),z*(size.z*0.5-bevel)),Vector3.ONE,BRASS,true)

func book(p: Vector3, width: float, depth: float, thickness: float, color: Color, angle: float = 0.0) -> void:
 # Closed, unmarked books stay clearly separate from authored evidence sheets.
 rounded_box(p+Vector3(0,thickness*0.5,0),Vector3(width,thickness-0.4,depth),Color("c1b69c"),0.2,false,Vector3(0,angle,0),1)
 for y in [0.15,thickness-0.15]:
  rounded_box(p+Vector3(0,y,0),Vector3(width+0.8,0.3,depth+0.8),color,0.14,false,Vector3(0,angle,0),0)
 # Spine and small embossed binding bands use the same local rotation.
 var basis := Basis(Vector3.UP,angle)
 rounded_box(p+basis*Vector3(-width*0.5,thickness*0.5,0),Vector3(thickness*0.58,thickness,depth+0.5),color,thickness*0.28,false,Vector3(0,angle,0),0)
 for band in [-0.35,-0.23,0.23,0.35]:
  rounded_box(p+basis*Vector3(-width*0.5-thickness*0.24,thickness*0.5,band*depth),Vector3(0.2,thickness*0.82,0.4),BRASS,0.09,true,Vector3(0,angle,0))
 welt(p+Vector3(0,thickness+0.02,0),width-2,depth-2,0.65,0.07,BRASS,Vector3(0,angle,0),true)
 rounded_box(p+Vector3(0,thickness+0.03,0),Vector3(width*0.42,0.06,depth*0.12),color.darkened(0.19),0.025,false,Vector3(0,angle,0),0)

func residential_details() -> void:
 # Floor luggage stays along the outer wall, away from the central flight aisle.
 suitcase(Vector3(133,0.4,373),Vector3(33,25,43),Color("5b4340"))
 suitcase(Vector3(133,25.7,373),Vector3(28,17,34),TEAL)
 suitcase(Vector3(-133,0.4,363),Vector3(31,21,39),Color("5b6656"))
 # A narrow freestanding reading console supports the existing books in place.
 var shelf_wood := Color("60473b")
 rounded_box(Vector3(147,65,414),Vector3(32,3,75),shelf_wood,0.8,false,Vector3.ZERO,3)
 # The front supports sit behind the stowed cases, clear of their corner caps.
 for x in [137,157]:
  for z in [400,441]:
   lathed("reading_console_leg",[Vector2(0.02,0),Vector2(1.8,0),Vector2(2.1,0.7),Vector2(2.1,3),Vector2(1.65,4),Vector2(1.45,10),Vector2(1.6,41),Vector2(2.3,46),Vector2(2.5,49),Vector2(1.9,52),Vector2(1.9,61.5),Vector2(2.3,63.5),Vector2(0.02,63.5)],Vector3(x,0,z),shelf_wood)
   lathed("reading_console_ferrule",[Vector2(0.02,0),Vector2(1.9,0),Vector2(2.2,0.7),Vector2(2.2,3),Vector2(1.7,3.3),Vector2(0.02,3.3)],Vector3(x,0,z),BRASS,true)
  rounded_box(Vector3(x,60.5,420.5),Vector3(3,6,41),shelf_wood,0.55,false,Vector3.ZERO,3)
 for z in [400,441]:
  rounded_box(Vector3(147,60.5,z),Vector3(26,6,2.4),shelf_wood,0.5,false,Vector3.ZERO,3)
  rounded_box(Vector3(147,61.5,z-1.24),Vector3(20,0.35,0.18),BRASS,0.08,true)
 book(Vector3(145,66.7,396),17,24,3.3,Color("6a4045"),-0.06)
 book(Vector3(145,70.0,396),15,22,2.8,TEAL,0.07)
 book(Vector3(143,66.7,429),17,25,3.6,Color("63594b"),0.04)
 # Folded travel blankets at each residential sofa's outer arm.
 for z in [192,522]:
  for layer in range(4):
   linen(Vector3(-139,46.2+layer*0.7,z),14,29,1.0,Color("a5977d"),Vector3(0,0.02*layer,0))

func service_cup(p: Vector3) -> void:
 if not meshes.has("service_cup"):
  meshes["service_cup"] = preload("res://scripts/ceramic_profiles.gd").cup_mesh()
  meshes["service_saucer"] = preload("res://scripts/ceramic_profiles.gd").saucer_mesh()
 instance("service_saucer",p,Vector3(0.78,0.78,0.78),CREAM)
 instance("service_cup",p,Vector3(0.65,0.70,0.65),CREAM)
 instance("fine_ring",p+Vector3(0,5.75,0),Vector3(6.04,0.13,6.04),BRASS,true)
 cyl(p+Vector3(0,4.9,0),5.25,0.06,Color("4c3328"))
 var handle: Array[Vector3] = []
 for j in range(33):
  var a := float(j)*TAU/32
  handle.append(Vector3(3.55+cos(a)*1.35,3.0+sin(a)*1.8,0))
 curved_tube("service_cup_handle",handle,PackedFloat32Array([0.3]),p,CREAM)

func saucer(p: Vector3, diameter: float, color: Color = CREAM) -> void:
 if not meshes.has("service_saucer"): meshes["service_saucer"] = preload("res://scripts/ceramic_profiles.gd").saucer_mesh()
 var scale3 := diameter/13.1
 instance("service_saucer",p,Vector3(scale3,0.8,scale3),color)

func napkin(p: Vector3) -> void:
 linen(p,13,18,0.7,LINEN,Vector3(0,0.12,0))
 linen(p+Vector3(-1,0.45,0),10,16,0.75,CREAM,Vector3(0,0.12,0))
 # A thin oval metal loop surrounds the folded linen instead of a solid bar.
 instance("fine_ring",p+Vector3(0,1.0,0),Vector3(13.1,1.6,2.4),BRASS,true,Vector3(PI/2,0,0))

func flower_sprig(base: Vector3, lean: Vector3, color: Color) -> void:
 var tip := base+lean
 rod(base,tip,0.24,Color("536e4a"))
 var leaf := base.lerp(tip,0.55)
 instance("sphere",leaf+Vector3(1.2,0,0),Vector3(3.3,0.5,1.2),Color("557c56"),false,Vector3(0,0,0.3))
 for petal in range(5):
  var a := float(petal)*TAU/5.0
  instance("sphere",tip+Vector3(cos(a)*1.8,0,sin(a)*1.8),Vector3(2.5,0.8,2.1),color)
 cyl(tip+Vector3(0,0.5,0),1.5,0.6,Color("b99c55"))

func dining_details() -> void:
 # No additions to Vale's place setting or covered body at 1250–1387.
 for z in [1050,1450]:
  napkin(Vector3(-75,78.0,z+28))
  service_cup(Vector3(-72,78.0,z-31))
  # Concentric porcelain/gold plate trim, leaving the pastry untouched.
  instance("fine_ring",Vector3(-101,78.55,z),Vector3(46,0.12,46),BRASS,true)
  instance("fine_ring",Vector3(-101,78.56,z),Vector3(41,0.12,41),CREAM)
 # Small fresh stems in the original vases, including the vase away from Vale’s cup.
 for z in [1050,1250,1450]:
  for j in range(3):
   flower_sprig(Vector3(-127,96,z+28),Vector3((j-1)*3.0,8+float(j%2)*3,(j-1)*1.5),Color("e0c0ba"))
 # Hospitality side tables are already in the world, away from the cable duct.
 for z in [1095,1320]:
  rounded_box(Vector3(137,86.7,z),Vector3(37,0.8,31),BRASS,0.35,true)
  rounded_box(Vector3(137,87.2,z),Vector3(33,0.35,27),DARK,0.16)
  welt(Vector3(137,87.55,z),35,29,2.5,0.25,BRASS,Vector3.ZERO,true)
  for side in [-1,1]:
   box(Vector3(137+side*19,88.2,z),Vector3(0.8,2.7,31),BRASS,true)
  for j in range(3):
   saucer(Vector3(128,87.4+j*0.55,z-4),9)
  napkin(Vector3(146,87.4,z+4))
 coffee_pot(Vector3(136,89.4,1516))

func coffee_pot(p: Vector3) -> void:
 lathed("coffee_body",[Vector2(0.02,0),Vector2(4.3,0),Vector2(5.2,0.6),Vector2(5.2,1.3),Vector2(4.8,1.8),Vector2(4.2,3),Vector2(3.7,10.5),Vector2(3.8,14),Vector2(4.3,14.6),Vector2(4.1,15.2),Vector2(0.02,15.2)],p,Color("c7c7b8"),true)
 lathed("coffee_lid",[Vector2(0.02,0),Vector2(4.6,0),Vector2(4.6,0.5),Vector2(3.6,1.2),Vector2(2,1.8),Vector2(0.6,2),Vector2(0.02,2)],p+Vector3(0,15.2,0),BRASS,true)
 lathed("coffee_finial",[Vector2(0.02,0),Vector2(0.7,0),Vector2(0.6,0.8),Vector2(1.1,1.2),Vector2(1.2,1.8),Vector2(0.6,2.2),Vector2(0.02,2.2)],p+Vector3(0,17.1,0),DARK)
 var spout: Array[Vector3] = []
 var radii := PackedFloat32Array()
 for j in range(25):
  var t := float(j)/24
  spout.append(Vector3(-3.5-t*6.8,6.0+3*t+5*t*t,0))
  radii.append(lerpf(1.5,0.75,t))
 curved_tube("coffee_spout",spout,radii,p,BRASS,true,true)
 var handle: Array[Vector3] = []
 for j in range(41):
  var a := float(j)*TAU/40
  handle.append(Vector3(5.6+cos(a)*3.5,9.5+sin(a)*5.0,0))
 curved_tube("coffee_handle",handle,PackedFloat32Array([0.48]),p,DARK)

func garden_details() -> void:
 # Botanical supplies live on unused portions of the existing potting bench.
 # The clue label at (102,80,1905) and its approach stay fully exposed.
 box(Vector3(126,78.0,1935),Vector3(28,1.0,23),Color("826e50"))
 box(Vector3(126,78.7,1935),Vector3(25,0.5,20),Color("383e2f"))
 for x in [119,127,135]:
  cyl(Vector3(x,81,1935),6.0,5,Color("9c7153"))
  cyl(Vector3(x,83.6,1935),5.5,0.4,Color("31342a"))
  rod(Vector3(x,84,1935),Vector3(x+1,91,1935),0.25,Color("5f8058"))
  instance("sphere",Vector3(x+2,88,1935),Vector3(4,0.6,1.5),Color("5f8058"),false,Vector3(0,0,0.4))
 # Slim mist bottle, folded cloth and hand trowel toward the outer edge.
 cyl(Vector3(139,83,1896),5,10,Color("657e73"))
 cyl(Vector3(139,89,1896),2,2.4,BRASS,true)
 box(Vector3(138,91,1896),Vector3(5,1.5,2),DARK)
 box(Vector3(122,78.3,1880),Vector3(12,1,9),LINEN,false,0.15)
 rod(Vector3(79,78.8,1922),Vector3(79,78.8,1937),1.0,Color("80644c"))
 instance("sphere",Vector3(79,78.8,1941),Vector3(4,0.6,8),BRASS,true)
 # Spare ceramics at floor level on the planter's outer edge, not near the orchid.
 for z in [1810,2330]:
  cyl(Vector3(148,56,z),12,12,Color("97745d"))
  cyl(Vector3(148,62.1,z),10,0.3,Color("2e342b"))
  instance("ring",Vector3(148,62.2,z),Vector3(12.5,0.8,12.5),CREAM)
