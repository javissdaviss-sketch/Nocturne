extends RefCounted
## Distinct authored window heads in the 3 carriages. No light, shader
## override to glass, movement, or curtain changes. Within the original bay.
const Finishes := preload("res://scripts/material_library.gd")
const Veneer := preload("res://scripts/fitted_veneer.gd")
const Props := preload("res://scripts/prop_meshes.gd")
const ANCHORS := [210,1220,2060]
const COACH_WALLS := [
 [0.0,360.0,800.0], [840.0,990.0,1390.0,1640.0], [1680.0,2045.0,2480.0]
]
const NAMES := ["BerthTuckedLinenCornice","MeridianWalnutFanCornice","GardenOpalCove"]
static var meshes:Dictionary = {}
static var materials:Dictionary = {}

static func draws_here(car:int,z:int) -> bool:
 return car>=0 and car<ANCHORS.size() and z==ANCHORS[car]

static func plan(car:int,z:float)->Array[Dictionary]:
 var pieces:Array[Dictionary]=[]
 if car<0 or car>=COACH_WALLS.size(): return pieces
 var limits:Array=COACH_WALLS[car]
 var raw_lo:=z-4.0
 var raw_hi:=z+150.0
 for i in range(limits.size()-1):
  # End mounting clearance was measured against the actual transverse
  # structure (thicker shells and narrower internal partitions).
  var lo:=maxf(raw_lo,float(limits[i])+5.70)
  var hi:=minf(raw_hi,float(limits[i+1])-5.70)
  if hi-lo<23.0: continue
  pieces.append({"origin":(lo+hi)*0.5,"half":(hi-lo)*0.5,"begin":lo,"end":hi,"room":i})
 return pieces

static func install(world:Node3D,parent:Node3D,car:int,side:int,z:int)->void:
 for part in plan(car,z):
  build_at(world,parent,car,side,part.origin,part.half,part.room)

static func build(world:Node3D,parent:Node3D,car:int,side:int,z:int)->void:
 # Isolated fixture path used to guarantee baseline cross-section and rays.
 build_at(world,parent,car,side,z+73.0,71.6 if car==0 else 75.0,-1)

static func build_at(world:Node3D,parent:Node3D,car:int,side:int,z:float,half:float,role:int)->void:
 var profile:=Node3D.new()
 profile.name="%s_%d_%d" % [NAMES[car],side,int(z*10)]
 profile.position=Vector3(side*493,0,z)
 profile.set_meta("fitted_window_half_cm",half)
 parent.add_child(profile)
 var measure:="%.3f/%d"%[half,car]
 var dye:="%d/%d/%d"%[car,side,role]
 if not meshes.has(measure): meshes[measure]=geometry(car,half)
 if not materials.has(dye): materials[dye]=finish(car,side,role)
 for i in range(2):
  var node:MeshInstance3D=world.mesh_obj(profile,meshes[measure][i],Vector3.ZERO,Color.WHITE,true)
  node.scale.x=-side
  node.name="WindowHeadRelief" if i==0 else "WindowHeadBeading"
  node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  node.material_override=materials[dye][i]
  var collider:=node.get_child(0).get_child(0) as CollisionShape3D
  var physical:=collider.shape as ConcavePolygonShape3D
  physical.backface_collision=true

static func finish(car:int,side:int,role:int)->Array:
 match car:
  0:
   var cloth:=Color("a09076")
   var timber:=Color("746044")
   if role>=0:
    var recipe:Array=[
     [Color("aa9479"),Color("624f3e")],[Color("a29379"),Color("746044")],
     [Color("a0a095"),Color("756c59")],[Color("8d8b77"),Color("635b48")]]
    var i:=role*2+(1 if side>0 else 0)
    cloth=recipe[i][0]
    timber=recipe[i][1]
   return [Finishes.make(Finishes.Finish.LINEN,cloth),Finishes.make(Finishes.Finish.WALNUT,timber)]
  1:
   var timber:=Color("644d37")
   var edging:=Color("9c8864")
   if role>=0:
    var recipe:Array=[
     [Color("5b634d"),Color("a18a62")],[Color("4d585b"),Color("827a6a")],
     [Color("644d37"),Color("9c8864")],[Color("55684f"),Color("999180")],
     [Color("75614a"),Color("987656")],[Color("4b5556"),Color("8d8370")]]
    var i:=role*2+(1 if side>0 else 0)
    timber=recipe[i][0]
    edging=recipe[i][1]
   return [Veneer.make("edge",timber),Finishes.make(Finishes.Finish.BRASS,edging)]
  _:
   var enamel:=Color("54675e")
   var beading:=Color("9ba393")
   if role>=0:
    var recipe:Array=[
     [Color("556856"),Color("a5a38b")],[Color("68716a"),Color("a09b89")],
     [Color("4d5d54"),Color("a29172")],[Color("54675e"),Color("9ba393")]]
    var i:=role*2+(1 if side>0 else 0)
    enamel=recipe[i][0]
    beading=recipe[i][1]
   return [Finishes.make(Finishes.Finish.STEEL,enamel,false,false,true),Finishes.make(Finishes.Finish.CERAMIC,beading)]

static func bottom(car:int,u:float)->float:
 match car:
  0: return 254.5+0.55*cos(u*TAU*2.0)
  1: return 252.8+6.0*cos(u*PI*0.5)
  _: return 257.2-2.9*cos(u*PI*0.5)

static func position_at(car:int,horizontal:float,section:int,half:float) -> Vector3:
 var u:=horizontal/maxf(half,0.01)
 var y:=bottom(car,u)
 if car==0:
  var cornice := Vector2(251.7,4.4)
  match section:
   0: cornice=Vector2(y-0.6,1.8)
   1: cornice=Vector2(y+0.8,4.0)
   2: cornice=Vector2(y+3.4,5.3)
   3: cornice=Vector2(265.0,5.3)
   4: cornice=Vector2(271.5,3.9)
   5: cornice=Vector2(273.2,1.4)
   _: cornice=Vector2(273.2,-0.5)
  return Vector3(cornice.y,cornice.x,horizontal)
 if car==1:
  var crown:=minf(273.1,267.0+5.0*cos(u*PI*0.5))
  var terraces:Array[Vector2]=[Vector2(y,1.2),Vector2(y+0.70,3.38),Vector2(y+1.80,5.64),
   Vector2(y+4.25,5.64),Vector2(crown-1.5,4.40),Vector2(crown,3.15),Vector2(crown,-0.48)]
  return Vector3(terraces[section].y,terraces[section].x,horizontal)
 var arcs:Array[Vector2]=[Vector2(y,1.0),Vector2(y+0.52,3.4),Vector2(y+2.2,5.73),
  Vector2(y+5.34,6.0),Vector2(269.2,5.66),Vector2(272.4,4.45),Vector2(273.8,-0.5)]
 return Vector3(arcs[section].y,arcs[section].x,horizontal)

static func geometry(car:int,half:float)->Array:
 var shell:=SurfaceTool.new()
 shell.begin(Mesh.PRIMITIVE_TRIANGLES)
 var insets:=SurfaceTool.new()
 insets.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(24):
  var a:=lerpf(-half,half,float(i)/24)
  var b:=lerpf(-half,half,float(i+1)/24)
  for row in range(6):
   var p0:=position_at(car,a,row,half)
   var p1:=position_at(car,b,row,half)
   var p2:=position_at(car,b,row+1,half)
   var p3:=position_at(car,a,row+1,half)
   var n:Vector3=(p1-p0).cross(p3-p0).normalized()
   if n.x<0.0: n=-n
   Props.quad(shell,[p0,p1,p2,p3],[n,n,n,n])
 # Window head meets the wall above the glass in caps; neither sides nor
 # the projecting trim has a visually floating end.
 for z in [-half,half]:
  var n:=Vector3(0,0,signf(z))
  for row in range(6):
   var a:=position_at(car,z,row,half)
   var b:=position_at(car,z,row+1,half)
   Props.quad(shell,[a,b,Vector3(-0.51,b.y,z),Vector3(-0.51,a.y,z)],[n,n,n,n])
 var beading:Array[Vector3]=[]
 for i in range(33):
  var z:=lerpf(-half+1.3,half-1.3,float(i)/32)
  var a:=position_at(car,z,2,half)
  if car==0: beading.append(a+Vector3(0.09,-0.06,0))
  elif car==1: beading.append(a+Vector3(0.21,1.11,0))
  else: beading.append(a+Vector3(0.13,0.91,0))
 insets.append_from(Props.tube(beading,PackedFloat32Array([0.34 if car!=2 else 0.45]),8),0,Transform3D.IDENTITY)
 if car==1:
  # Original fan-incised crescent, shared ends, small point of care.
  for k in range(-5,6):
   var q:=float(k)
   var rail:Array[Vector3]=[
    Vector3(5.61,262.1,q*4.5*half/75.0),Vector3(5.07,265.04,q*5.51*half/75.0),Vector3(4.88,267.4,q*6.7*half/75.0)]
   insets.append_from(Props.tube(rail,PackedFloat32Array([0.28]),6),0,Transform3D.IDENTITY)
 elif car==2:
  for z in [-0.79*half,0.0,0.79*half]:
   var curve:Array[Vector3]=[]
   for i in [2,3,4,5]: curve.append(position_at(car,z,i,half)+Vector3(0.12,0.0,0.0))
   insets.append_from(Props.tube(curve,PackedFloat32Array([0.22]),8),0,Transform3D.IDENTITY)
 return [shell.commit(),insets.commit()]
