extends "res://scripts/lived_in_details.gd"
## Recognizable working-garden props, kept on the outer benches and floor margins.
const Fixtures = preload("res://scripts/garden_fixture_geometry.gd")
const Profiles = preload("res://scripts/ceramic_profiles.gd")
const Padding = preload("res://scripts/upholstery_geometry.gd")
const Botanicals = preload("res://scripts/botanical_collection.gd")

func box(p: Vector3, size: Vector3, color: Color, metal: bool = false, rotation_y: float = 0.0) -> void:
 var key := "joinery_"+str(size)
 if not meshes.has(key): meshes[key] = Padding.build(size,minf(0.55,minf(size.x,minf(size.y,size.z))*0.12))
 instance(key,p,Vector3.ONE,color,metal,Vector3(0,rotation_y,0))

func vessel(p: Vector3, diameter: float, height: float, color: Color) -> Vector3:
 var key := "pot_%s_%s" % [diameter,height]
 if not meshes.has(key): meshes[key] = Fixtures.pot_mesh(diameter,height)
 instance(key,p,Vector3.ONE,color)
 cyl(p+Vector3(0,height-0.6,0),diameter*0.86,0.5,Color("303b2b"))
 return p+Vector3(0,height,0)

func build() -> void:
 var botanical := Botanicals.new()
 botanical.make_leaf_meshes()
 meshes["seedling_leaf"] = botanical.meshes["broad_leaf"]
 botanical.free()
 watering_can(Vector3(134,50.2,2177))
 nursery_tray(Vector3(-134,50.2,1905))
 propagation_rack(Vector3(143,50.2,2268))
 slatted_crate(Vector3(-133,0.3,2421))
 # Coiled hose and brass tap stay on the lower outer panel, not in the aisle.
 # The winding is one continuous round rubber hose, hung on a cast cradle.
 meshes["hose_coil"] = hose_mesh()
 instance("hose_coil",Vector3(-165,62,2180),Vector3.ONE,Color("354c3e"))
 for y in [49,75]: rod(Vector3(-166,y,2167),Vector3(-166,y,2193),1.2,BRASS,true)
 cyl(Vector3(-164,77,2180),3.0,5.0,BRASS,true)
 rod(Vector3(-164,75,2180),Vector3(-158,75,2180),1.8,BRASS,true)
 box(Vector3(-162,68,2180),Vector3(1,1,30),BRASS,true)
 finish_batches()

func watering_can(p: Vector3) -> void:
 meshes["watering_body"] = Profiles.lathe([Vector2(0.02,0.4),Vector2(6.4,0.4),Vector2(7.3,0.9),Vector2(7.9,2),Vector2(8.7,7),Vector2(8.8,13),Vector2(8.4,17),Vector2(7.5,18),Vector2(5.3,18.4),Vector2(4.8,18.9),Vector2(4.4,18.9),Vector2(4.3,18.2),Vector2(7.1,17.3),Vector2(7.7,13),Vector2(7.6,7),Vector2(6.6,2),Vector2(0.02,1.5)])
 instance("watering_body",p,Vector3.ONE,TEAL,true)
 for y in [1.6,16.9]: instance("fine_ring",p+Vector3(0,y,0),Vector3(16.5,0.5,16.5),BRASS,true)
 instance("fine_ring",p+Vector3(0,18.8,0),Vector3(9.2,0.6,9.2),BRASS,true)
 # A tall arched carrying handle above the broad can, and a rising spout.
 instance("ring",p+Vector3(1,19,0),Vector3(18,1.8,18),BRASS,true,Vector3(PI*0.5,0,0))
 var start := p+Vector3(-7,5,0)
 var end := p+Vector3(-22,16,0)
 var length := start.distance_to(end)
 meshes["spout"] = Profiles.lathe([Vector2(2.1,0),Vector2(1.9,2),Vector2(1.0,length-1),Vector2(1.15,length),Vector2(0.75,length),Vector2(0.7,length-1),Vector2(1.5,0)])
 instance("spout",start,Vector3.ONE,TEAL,true,Quaternion(Vector3.UP,(end-start).normalized()).get_euler())
 meshes["watering_rose"] = Profiles.lathe([Vector2(0.7,0),Vector2(1.1,0),Vector2(1.4,0.6),Vector2(2.6,2.0),Vector2(2.9,2.5),Vector2(2.9,2.9),Vector2(2.6,3.1),Vector2(0.02,3.1)])
 var rose_rotation := Quaternion(Vector3.UP,Vector3(-0.8,0.6,0)).get_euler()
 instance("watering_rose",end,Vector3.ONE,BRASS,true,rose_rotation)
 var rose_basis := Basis.from_euler(rose_rotation)
 for j in range(12):
  var a := float(j)*TAU/12
  instance("sphere",end+rose_basis*Vector3(cos(a)*2,3.15,sin(a)*2),Vector3(0.28,0.28,0.28),DARK)

func nursery_tray(p: Vector3) -> void:
 box(p+Vector3(0,1,0),Vector3(28,2,35),Color("70523c"))
 for side in [-1,1]:
  box(p+Vector3(side*14,3,0),Vector3(1.2,5,36),Color("917251"))
  box(p+Vector3(0,3,side*17.5),Vector3(28,5,1.2),Color("917251"))
 for row in range(3):
  for column in range(2):
   var pot := p+Vector3(-6+column*12,2,-11+row*11)
   var stem := vessel(pot,8,6,Color("a17252"))+Vector3(0,1,0)
   rod(stem,stem+Vector3(0,8+row,0),0.22,Color("5c7950"))
   for side in [-1,1]:
    instance("seedling_leaf",stem+Vector3(side*0.5,5.0,0),Vector3(2.3,5,5),Color("6a8c55"),false,Vector3(-0.3,side*PI/2,0))

func propagation_rack(p: Vector3) -> void:
 # A two-tier wire rack standing on the broad planter, away from the ledger.
 for x in [-11,11]:
  for z in [-19,19]: rod(p+Vector3(x,0,z),p+Vector3(x,52,z),1.0,BRASS,true)
 for height in [5,30]:
  for x in [-11,11]: rod(p+Vector3(x,height,-19),p+Vector3(x,height,19),0.8,BRASS,true)
  for z in [-19,19]: rod(p+Vector3(-11,height,z),p+Vector3(11,height,z),0.8,BRASS,true)
  for z in range(-16,17,8): rod(p+Vector3(-11,height,z),p+Vector3(11,height,z),0.45,BRASS,true)
  for z in [-11,9]:
   var pot := p+Vector3(0,height+0.5,z)
   vessel(pot,12,8,Color("8f6951"))
   rod(pot+Vector3(0,8,0),pot+Vector3(0,19,0),0.25,Color("5b8058"))
   for side in [-1,1]: instance("seedling_leaf",pot+Vector3(side*0.5,14,0),Vector3(2.2,5.5,5.5),Color("5f8655"),false,Vector3(-0.35,side*PI/2,0))

func slatted_crate(p: Vector3) -> void:
 var wood := Color("937453")
 box(p+Vector3(0,1.2,0),Vector3(32,2.4,36),wood)
 for x in [-15,15]:
  for z in [-17,17]:
   box(p+Vector3(x,13,z),Vector3(2.0,26,2.0),Color("604934"))
 for height in [6,14,22]:
  for side in [-1,1]:
   box(p+Vector3(side*15.5,height,0),Vector3(1.4,5.0,35),wood)
   box(p+Vector3(0,height,side*17.5),Vector3(32,5.0,1.4),wood)
 for x in [-7,7]:
  vessel(p+Vector3(x,1.5,0),11,15,Color("a57e5f"))
 # Exposed screw heads and edge bands follow the individual slats, leaving gaps open.
 for side in [-1,1]:
  for z in [-13,13]:
   for height in [6,14,22]:
    instance("sphere",p+Vector3(side*16.25,height,z),Vector3(0.45,0.9,0.9),BRASS,true)
 # World compiles each visible slat, preserving gaps and the perchable rim.

func hose_mesh() -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var sections := 240
 for segment in range(sections):
  for side in range(10):
   for index in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var t := float(segment+index.y)/sections
    var angle := t*TAU*4
    var radius := lerpf(14.5,5.5,t)
    var cross_angle := float(side+index.x)*TAU/10
    var normal := Vector3(cos(cross_angle),cos(angle)*sin(cross_angle),sin(angle)*sin(cross_angle))
    var center := Vector3(0,cos(angle)*radius,sin(angle)*radius)
    surface.set_normal(normal)
    surface.set_uv(Vector2(float(side+index.x)/10,t*8))
    surface.add_vertex(center+normal*0.65)
 return surface.commit()
