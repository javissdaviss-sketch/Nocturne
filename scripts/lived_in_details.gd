extends Node3D
## Non-interactive set dressing, grouped by primitive/material into MultiMeshes.
## All coordinates are centimetres. Evidence, walkways and collisions are untouched.
const BRASS := Color("bda374")
const CREAM := Color("ddd4bc")
const TEAL := Color("2d625e")
const DARK := Color("273a39")
const LINEN := Color("d1c7ac")
var batches: Dictionary = {}
var materials: Dictionary = {}
var meshes: Dictionary = {}
var detail_count := 0

func build() -> void:
 residential_details()
 dining_details()
 garden_details()
 for key in batches:
  var data: Dictionary = batches[key]
  var instances := MultiMesh.new()
  instances.transform_format = MultiMesh.TRANSFORM_3D
  instances.mesh = meshes[data.shape]
  instances.instance_count = data.transforms.size()
  for i in range(instances.instance_count):
   instances.set_instance_transform(i,data.transforms[i])
  var node := MultiMeshInstance3D.new()
  node.name = "Details_"+str(key)
  node.multimesh = instances
  node.material_override = materials[data.material]
  # Tiny trim should not add shadow-map work; large existing furniture casts it.
  node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(node)

func material_id(color: Color, metal: bool) -> String:
 var key := color.to_html()+str(metal)
 if not materials.has(key):
  var material := StandardMaterial3D.new()
  material.albedo_color = color
  material.roughness = 0.31 if metal else 0.64
  material.metallic = 0.65 if metal else 0.0
  materials[key] = material
 return key

func instance(shape: String, p: Vector3, size: Vector3, color: Color, metal: bool = false, rotation3: Vector3 = Vector3.ZERO) -> void:
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
   mesh.radial_segments = 24
   meshes[shape] = mesh
  elif shape == "sphere":
   var mesh := SphereMesh.new()
   mesh.radius = 0.5
   mesh.height = 1.0
   mesh.radial_segments = 8
   mesh.rings = 4
   meshes[shape] = mesh
  elif shape == "ring":
   var mesh := TorusMesh.new()
   mesh.inner_radius = 0.39
   mesh.outer_radius = 0.5
   mesh.rings = 12
   mesh.ring_segments = 6
   meshes[shape] = mesh
  elif shape == "fine_ring":
   var mesh := TorusMesh.new()
   mesh.inner_radius = 0.485
   mesh.outer_radius = 0.5
   mesh.rings = 32
   mesh.ring_segments = 8
   meshes[shape] = mesh
 var material := material_id(color,metal)
 var key := shape+material
 if not batches.has(key): batches[key] = {"shape":shape,"material":material,"transforms":[]}
 var basis := Basis.from_euler(rotation3).scaled(size)
 batches[key].transforms.append(Transform3D(basis,p))
 detail_count += 1

func box(p: Vector3, size: Vector3, color: Color, metal: bool = false, rotation_y: float = 0.0) -> void:
 instance("box",p,size,color,metal,Vector3(0,rotation_y,0))

func cyl(p: Vector3, diameter: float, height: float, color: Color, metal: bool = false) -> void:
 instance("cylinder",p,Vector3(diameter,height,diameter),color,metal)

func rod(a: Vector3, b: Vector3, diameter: float, color: Color, metal: bool = false) -> void:
 var direction := (b-a).normalized()
 var rotation3 := Quaternion(Vector3.UP,direction).get_euler()
 instance("cylinder",(a+b)*0.5,Vector3(diameter,a.distance_to(b),diameter),color,metal,rotation3)

func suitcase(p: Vector3, size: Vector3, color: Color) -> void:
 box(p+Vector3(0,size.y*0.5,0),size,color)
 # Leather piping, travel straps and brass corners distinguish real luggage.
 for z_sign in [-1,1]:
  box(p+Vector3(0,size.y*0.5,z_sign*(size.z*0.5+0.15)),Vector3(size.x,0.5,0.6),DARK)
 for x_sign in [-1,1]:
  var x: float = x_sign*size.x*0.28
  box(p+Vector3(x,size.y+0.2,0),Vector3(1.5,0.5,size.z),Color("816d4f"))
  box(p+Vector3(x,size.y*0.5,-size.z*0.5-0.25),Vector3(2.3,3.3,0.6),BRASS,true)
 for side in [-1,1]:
  rod(p+Vector3(side*3,size.y+0.7,-2),p+Vector3(side*3,size.y+3.6,-2),0.9,BRASS,true)
 rod(p+Vector3(-3,size.y+3.6,-2),p+Vector3(3,size.y+3.6,-2),1.4,DARK)

func book(p: Vector3, width: float, depth: float, thickness: float, color: Color, angle: float = 0.0) -> void:
 # Closed, unmarked books stay clearly separate from authored evidence sheets.
 box(p+Vector3(0,thickness*0.5,0),Vector3(width,thickness-0.4,depth),Color("c1b69c"),false,angle)
 for y in [0.15,thickness-0.15]:
  box(p+Vector3(0,y,0),Vector3(width+0.6,0.3,depth+0.6),color,false,angle)
 # Spine and small embossed binding bands use the same local rotation.
 var basis := Basis(Vector3.UP,angle)
 box(p+basis*Vector3(-width*0.5,thickness*0.5,0),Vector3(0.6,thickness,depth),color,false,angle)
 for z_sign in [-1,1]:
  box(p+basis*Vector3(-width*0.5-0.33,thickness*0.5,z_sign*depth*0.32),Vector3(0.12,thickness*0.65,0.7),BRASS,true,angle)

func residential_details() -> void:
 # Floor luggage stays along the outer wall, away from the central flight aisle.
 suitcase(Vector3(133,0.4,373),Vector3(33,25,43),Color("5b4340"))
 suitcase(Vector3(133,25.7,373),Vector3(28,17,34),TEAL)
 suitcase(Vector3(-133,0.4,363),Vector3(31,21,39),Color("5b6656"))
 # A built-in reading shelf below the window; note and terminal remain clear.
 box(Vector3(147,65,414),Vector3(32,3,75),Color("60473b"))
 for z in [386,441]:
  box(Vector3(156,59,z),Vector3(13,10,2),BRASS,true)
 book(Vector3(145,66.7,396),17,24,3.3,Color("6a4045"),-0.06)
 book(Vector3(145,70.0,396),15,22,2.8,TEAL,0.07)
 book(Vector3(143,66.7,429),17,25,3.6,Color("63594b"),0.04)
 # Folded travel blankets at each residential sofa's outer arm.
 for z in [192,522]:
  box(Vector3(-139,48,z),Vector3(14,5,29),Color("a5977d"))
  for stripe in [-4,0,4]:
   box(Vector3(-139+stripe,50.6,z),Vector3(0.8,0.15,27),Color("686d5d"))

func service_cup(p: Vector3) -> void:
 cyl(p+Vector3(0,0.4,0),10,0.65,CREAM)
 instance("fine_ring",p+Vector3(0,0.8,0),Vector3(9.3,0.22,9.3),BRASS,true)
 cyl(p+Vector3(0,3.3,0),5.8,5.4,CREAM)
 cyl(p+Vector3(0,6.08,0),4.8,0.14,Color("4c3328"))
 instance("fine_ring",p+Vector3(0,6.1,0),Vector3(5.9,0.3,5.9),BRASS,true)
 instance("ring",p+Vector3(3.4,3.5,0),Vector3(3.4,0.55,3.4),BRASS,true,Vector3(PI*0.5,0,0))

func napkin(p: Vector3) -> void:
 box(p+Vector3(0,0.6,0),Vector3(13,1.1,18),LINEN,false,0.12)
 box(p+Vector3(0,1.3,0),Vector3(10,0.3,16),CREAM,false,0.12)
 box(p+Vector3(0,1.6,0),Vector3(13.2,0.25,2.1),BRASS,true,0.12)

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
 for z in [1110,1320]:
  box(Vector3(137,86.7,z),Vector3(37,0.8,31),BRASS,true)
  box(Vector3(137,87.2,z),Vector3(33,0.35,27),DARK)
  for side in [-1,1]:
   box(Vector3(137+side*19,88.2,z),Vector3(0.8,2.7,31),BRASS,true)
  for j in range(3):
   cyl(Vector3(128,87.7+j*0.6,z-4),9,0.55,CREAM)
  napkin(Vector3(146,87.4,z+4))
 # A tidy coffee pot on the service counter, away from the bottle and duct.
 cyl(Vector3(136,91.9,1516),10.5,5,BRASS,true)
 cyl(Vector3(136,99,1516),8,10,Color("c7c7b8"),true)
 cyl(Vector3(136,104.6,1516),9,1.1,BRASS,true)
 cyl(Vector3(136,106,1516),2.1,1.8,DARK)
 rod(Vector3(131,98,1516),Vector3(126,102,1516),2.0,BRASS,true)
 instance("ring",Vector3(142,99,1516),Vector3(8,1,8),DARK,false,Vector3(PI*0.5,0,0))

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
