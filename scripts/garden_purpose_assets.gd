extends RefCounted
## Purpose-built horticulture furniture for the outer crew rooms only. The
## existing protected case plant, its evidence route and sensors are separate.
const Props := preload("res://scripts/prop_meshes.gd")
const Finishes := preload("res://scripts/material_library.gd")
const Sleeper := preload("res://scripts/sleeping_assets.gd")

static func build(world: Node3D, parent: Node3D, origin: Vector3, orchid: bool) -> Node3D:
 var object := Node3D.new()
 object.name = "OrchidExhibitionStand" if orchid else "PottingWorkBench"
 parent.add_child(object)
 object.position=origin
 if orchid: exhibit(world,object)
 else: potting(world,object)
 return object

static func potting(world: Node3D,root:Node3D) -> void:
 var frame := wire_mesh()
 var tray := wire_mesh()
 var tools := wire_mesh()
 for x in [-23.5,23.5]:
  for z in [-14.0,14.0]:
   path(frame,[Vector3(x,1.0,z),Vector3(x,12,z),Vector3(x*0.88,66,z*0.88),Vector3(x,71.5,z)],1.64)
   block(frame,Vector3(x,1.0,z),Vector3(5.4,2.0,5.0),0.48)
  path(frame,[Vector3(x,14.0,-14),Vector3(x,13.1,0),Vector3(x,14.0,14)],1.29)
 for z in [-15.1,15.1]:
  block(frame,Vector3(0,69.0,z),Vector3(48.1,4.4,3.12),0.67)
 block(tray,Vector3(0,73.0,0),Vector3(55.5,4.1,35.4),1.48)
 # The surrounding low rim genuinely holds a soil tray and two empty nursery
 # pots. They are not a box pretending to be a ceramic work surface.
 for z in [-15.9,15.9]:
  block(tray,Vector3(0,75.3,z),Vector3(54.0,3.4,2.02),0.63)
 for x in [-26.21,26.21]:
  block(tray,Vector3(x,75.3,0),Vector3(2.22,3.3,31.0),0.61)
 # A drainboard edge is intentionally distinct from the specimen stand.
 for i in range(7):
  block(tray,Vector3(4.7+i*2.88,75.13,6.3),Vector3(0.72,0.29,14.2),0.13)
 append_at(tools,nursery_pot(6.5,7.0),Vector3(-16.9,75.05,-3.8))
 append_at(tools,nursery_pot(5.1,6.4),Vector3(-3.7,75.05,-5.2))
 append_at(tools,nursery_pot(4.15,5.25),Vector3(-9.75,75.05,8.9))
 shade(world,root,"PottingSteelFrame",frame.commit(),Finishes.make(Finishes.Finish.STEEL,Color("566064"),false,false,true))
 shade(world,root,"PottingRecessedDrainTray",tray.commit(),Finishes.make(Finishes.Finish.STEEL,Color("7b8c88")))
 shade(world,root,"PottingTerracottaPots",tools.commit(),Finishes.make(Finishes.Finish.TERRACOTTA,Color("9a6048")))

static func exhibit(world: Node3D,root:Node3D) -> void:
 var frame := wire_mesh()
 var ceramic := wire_mesh()
 var leaf := wire_mesh()
 var flowers := wire_mesh()
 # Grounded bronze pedestal: lower apron, gracefully swept legs and an
 # open lattice. No extra light, thin geometry isn't forced to cast shadows.
 for i in range(4):
  var angle := float(i)*TAU/4.0+PI/4.0
  var direction := Vector3(cos(angle),0,sin(angle))
  var tangent := Vector3(-sin(angle),0,cos(angle))
  var rail: Array[Vector3] = []
  for step in range(19):
   var s := float(step)/18.0
   rail.append(direction*(18.0-7.0*sin(s*PI))+Vector3.UP*(1.0+80.0*s)+tangent*(1.35*sin(s*PI)))
  path(frame,rail,1.54)
  block(frame,Vector3(direction.x*18,1.0,direction.z*18),Vector3(5.0,2.0,5.1),0.54)
  path(frame,[direction*15.3+Vector3.UP*31,direction*5.2+Vector3.UP*37,Vector3.UP*38],0.92)
 block(frame,Vector3(0,81.3,0),Vector3(43.1,3.4,33.5),1.10)
 block(ceramic,Vector3(0,84.3,0),Vector3(44,3.9,34),1.23)
 append_at(ceramic,nursery_pot(8.6,13.9),Vector3(0,86.25,0))
 block(ceramic,Vector3(0,97.3,0),Vector3(13.5,1.6,13.5),0.43)
 # A simple non-clue coral specimen with tapered stems and cupped petals.
 # Only remains visibly connected to the ceramic vessel; no case markers.
 var centres := wire_mesh()
 for i in range(3):
  var tip := Vector3(-8.0+8.0*i,112.6-2.5*abs(i-1),-2.5+(i%2)*5)
  var stem: Array[Vector3]=[Vector3(0,97.5,0),Vector3(tip.x*0.25,103,tip.z*0.29),Vector3(tip.x*0.80,tip.y-3.2,tip.z*0.8),tip]
  path(leaf,stem,0.32)
  var attitude := Basis(Vector3.UP,-0.54+0.56*i)*Basis(Vector3.RIGHT,0.26-0.13*i)
  for j in range(5):
   var angle := float(j)*TAU/5.0
   append_bloom_petal(flowers,tip,attitude,angle,4.22 if j in [0,2,3] else 3.22)
  append_bloom_petal(flowers,tip+attitude*Vector3(0,-0.08,-0.62),attitude,-PI*0.5,2.80,true)
  var boss := SphereMesh.new()
  boss.radius=0.49
  boss.height=0.98
  boss.radial_segments=12
  boss.rings=6
  centres.append_from(boss,0,Transform3D(attitude.scaled(Vector3(0.75,1.3,0.60)),tip+attitude*Vector3(0,0.1,-0.75)))
 for i in range(4):
  var angle := i*TAU/4.0+0.31
  append_flower_petal(leaf,Vector3(0,100.95,0),angle,5.2,0.78)
 shade(world,root,"ExhibitCurvedBronzeStand",frame.commit(),Finishes.make(Finishes.Finish.BRASS,Color("8d805d")))
 shade(world,root,"ExhibitPorcelainBasin",ceramic.commit(),Finishes.make(Finishes.Finish.CERAMIC,Color("beb79c")))
 shade(world,root,"ExhibitNoncasePlant",leaf.commit(),Finishes.make(Finishes.Finish.LEAF,Color("45684f")))
 shade(world,root,"ExhibitCoralPetals",flowers.commit(),Finishes.make(Finishes.Finish.LEAF,Color("ac6965")))
 shade(world,root,"ExhibitSmallPollenHearts",centres.commit(),Finishes.make(Finishes.Finish.CERAMIC,Color("c7a775")))

static func bloom_surface(t:float,side:float,tall:float,folded:bool) -> Vector3:
 # Taper from a supported tube to a broad lobed blade, fold a central
 # ridge and two slightly curled margins. Origin coincides with the stem.
 var outline := pow(maxf(0.0,sin(PI*(t*0.94+0.025))),0.69)*(1.0-t*0.08)
 var edge: float = pow(absf(side),2.6)
 var width: float = (1.32 if not folded else 0.83)*outline
 var rise := -0.61*sin(PI*t)-0.29*t-0.57*edge*t*outline
 if folded: rise -= 0.55*t*t+0.23*sin(t*4.0)
 return Vector3(side*width*(1.0+0.08*sin(t*9.0+side*2.0)),t*tall+0.13*edge*sin(t*PI),rise)

static func append_bloom_petal(out:SurfaceTool, base:Vector3,attitude:Basis,angle:float,length:float,folded:bool=false) -> void:
 var rotated := attitude*Basis(Vector3.FORWARD,angle)
 for section in range(11):
  for strip in range(6):
   var points: Array[Vector3]=[]
   var normals: Array[Vector3]=[]
   for v:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var t := 0.012+0.988*float(section+v.y)/11.0
    var s := -1.0+2.0*float(strip+v.x)/6.0
    var centre := bloom_surface(t,s,length,folded)
    var dt := bloom_surface(t+0.002,s,length,folded)-bloom_surface(t-0.002,s,length,folded)
    var ds := bloom_surface(t,s+0.002,length,folded)-bloom_surface(t,s-0.002,length,folded)
    points.append(base+rotated*centre)
    normals.append(rotated*(dt.cross(ds).normalized()))
   Props.quad(out,points,normals)

static func append_flower_petal(st:SurfaceTool,center:Vector3,angle:float,reached:float,scale:float=0.70) -> void:
 var dir:=Vector3(cos(angle),sin(angle)*0.72,0).normalized()
 var cross:=Vector3(-dir.y,dir.x,0)
 for step in range(9):
  var a := float(step)/9.0
  var b := float(step+1)/9.0
  for i in [-1,0]:
   var pts: Array[Vector3]=[]
   var normals: Array[Vector3]=[]
   for uv:Vector2 in [Vector2(a,i),Vector2(b,i),Vector2(b,i+1),Vector2(a,i+1)]:
    var width := (0.35+sin(PI*uv.x)*1.51)*scale
    pts.append(center+dir*(maxf(0.08,uv.x)*reached)+cross*uv.y*width+Vector3(0,0,-0.70*sin(PI*uv.x)+0.49*absf(uv.y)*uv.x))
    normals.append((Vector3.FORWARD+dir*0.14+cross*uv.y*0.31).normalized())
   Props.quad(st,pts,normals)

static func nursery_pot(r:float,h:float) -> ArrayMesh:
 return Sleeper.lathe([Vector2(0.02,0),Vector2(r*0.63,0),Vector2(r*0.72,0.8),Vector2(r*0.94,h-1),
  Vector2(r,h-0.55),Vector2(r,h+0.0),Vector2(r*0.86,h+0.0),Vector2(r*0.78,h-0.77),
  Vector2(r*0.63,0.9),Vector2(0.02,0.9)],30)

static func shade(world:Node3D,root:Node3D,descriptive:String,mesh:ArrayMesh,material:Material)->void:
 var fore:MeshInstance3D = world.mesh_obj(root,mesh,Vector3.ZERO,Color.WHITE,true)
 fore.name=descriptive
 fore.material_override=material
 fore.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var collision := fore.get_child(0).get_child(0) as CollisionShape3D
 (collision.shape as ConcavePolygonShape3D).backface_collision = true

static func wire_mesh() -> SurfaceTool:
 var build := SurfaceTool.new()
 build.begin(Mesh.PRIMITIVE_TRIANGLES)
 return build

static func block(target:SurfaceTool,p:Vector3,scale:Vector3,bevel:float)->void:
 append_at(target,Props.rounded(scale,bevel),p)
static func path(target:SurfaceTool,route:Array[Vector3],radius:float)->void:
 append_at(target,Props.tube(route,PackedFloat32Array([radius]),10),Vector3.ZERO)
static func append_at(target:SurfaceTool,part:ArrayMesh,origin:Vector3)->void:
 target.append_from(part,0,Transform3D(Basis.IDENTITY,origin))
