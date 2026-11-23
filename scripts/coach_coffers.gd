extends RefCounted
## One occupied ceiling bay per carriage, on the same architrave centres.
## Existing light fittings remain in service, no decorative light or collision
## projects below the existing upper wall/rack clearance.
const Finishes:=preload("res://scripts/material_library.gd")
const Shapes:=preload("res://scripts/prop_meshes.gd")
const Fixtures:=preload("res://scripts/reception_worktops.gd")
const NAME:=["CrewTwinLuggageCoves","MeridianSatinFanCoffer","GardenIronAndOpalRibs"]
static var models:Dictionary={}
static var looks:Dictionary={}

static func install(world:Node3D,parent:Node3D,car:int) -> Node3D:
 if not models.has(car): models[car]=forms(car)
 if not looks.has(car): looks[car]=finish(car)
 var room:=Node3D.new()
 room.name=NAME[car]
 parent.add_child(room)
 room.position=Vector3(0,282,car*840+109)
 for i in range(2):
  var part:MeshInstance3D=world.mesh_obj(room,models[car][i],Vector3.ZERO,Color.WHITE,true)
  part.name="CofferForm" if i==0 else "InsetLips"
  part.material_override=looks[car][i]
  part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var contact:=part.get_child(0).get_child(0) as CollisionShape3D
  (contact.shape as ConcavePolygonShape3D).backface_collision=true
 return room

static func finish(car:int)->Array:
 var finish_kind:Array=[Finishes.Finish.WALNUT,Finishes.Finish.WALNUT,Finishes.Finish.STEEL]
 var trim_kind:Array=[Finishes.Finish.BRASS,Finishes.Finish.BRASS,Finishes.Finish.CERAMIC]
 var tint:Array=[Color("514538"),Color("48382d"),Color("53635c")]
 var trim:Array=[Color("827452"),Color("9e8351"),Color("89948a")]
 return [Finishes.make(finish_kind[car],tint[car],false,false,car==2),Finishes.make(trim_kind[car],trim[car])]

static func forms(car:int)->Array:
 var shape:=Fixtures.begin()
 var trim:=Fixtures.begin()
 if car==0:
  for side in [-1,1]:
   var profile:Array[Vector2]=[]
   for i in range(15):
    var r:=i/14.0
    profile.append(Vector2(side*(9.5+r*18.3),1.40+5.0*sin(r*PI)+2.0*r))
   extrusion(shape,profile,-21.6,21.6)
   for x in [10,28]:
    Fixtures.wire(trim,[Vector3(side*x,1.54,-20.6),Vector3(side*x,1.54,20.6)],0.40)
   var front:Array[Vector3]=[]
   for p in profile: front.append(Vector3(p.x,p.y-0.21,20.50))
   Fixtures.wire(trim,front,0.31)
 elif car==1:
  var profile:Array[Vector2]=[]
  for i in range(21):
   var x:=-30.5+61.0*i/20.0
   profile.append(Vector2(x,1.6+6.25*cos(x/31.0*PI/2)))
  extrusion(shape,profile,-22.8,22.8)
  for z in [-20.8,20.8]:
   var bead:Array[Vector3]=[]
   for p in profile:
    bead.append(Vector3(p.x,p.y-0.36,z))
   Fixtures.wire(trim,bead,0.59)
  for x in [-23.0,-16.0,-8.0,0.0,8.0,16.0,23.0]:
   var wide:=float(x)*0.94
   Fixtures.wire(trim,[
    Vector3(wide*0.18,6.4,-15.8),Vector3(wide*0.56,7.15-0.029*absf(x),-4.2),
    Vector3(wide,7.15-0.058*absf(x),9.0),Vector3(wide*1.1,7.12-0.101*absf(x),17.4)],0.31)
 else:
  var profile:Array[Vector2]=[]
  for i in range(21):
   var x:=-31.0+62.0*i/20.0
   profile.append(Vector2(x,1.4+7.55*cos(x/31.0*PI/2)))
  for z in [-15.0,15.0]:
   var crossbeam:Array[Vector3]=[]
   for p in profile: crossbeam.append(Vector3(p.x,p.y+1.46,z))
   Fixtures.wire(shape,crossbeam,1.95)
   var inner:Array[Vector3]=[]
   for p in profile: inner.append(Vector3(p.x,p.y+0.02,z-0.6))
   Fixtures.wire(trim,inner,0.58)
  # One opal profile with visible metal side flanges, no emitter.
  extrusion(trim,[Vector2(-6.1,6.1),Vector2(-4.2,5.5),Vector2(4.2,5.5),Vector2(6.1,6.1)],-14.7,14.7)
  for x in [-6.8,6.8]:
   Fixtures.wire(shape,[Vector3(x,6.94,-15.0),Vector3(x,6.94,15.0)],0.72)
 return [shape.commit(),trim.commit()]

static func extrusion(surf:SurfaceTool,curve:Array[Vector2],z0:float,z1:float)->void:
 for i in range(curve.size()-1):
  var a:=curve[i]
  var b:=curve[i+1]
  var edge:=b-a
  var normal:=Vector3(edge.y,-edge.x,0).normalized()*signf(edge.x)
  Shapes.quad(surf,[Vector3(a.x,a.y,z0),Vector3(b.x,b.y,z0),Vector3(b.x,b.y,z1),Vector3(a.x,a.y,z1)],[normal,normal,normal,normal])
 for z in [z0,z1]:
  var n:=Vector3(0,0,-1 if z==z0 else 1)
  for i in range(curve.size()-1):
   var a:=curve[i]
   var b:=curve[i+1]
   Shapes.quad(surf,[Vector3(a.x,a.y,z),Vector3(b.x,b.y,z),Vector3(b.x,11,z),Vector3(a.x,11,z)],[n,n,n,n])
