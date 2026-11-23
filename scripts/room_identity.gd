extends RefCounted
## Distinct wall joinery for the Nocturne's inhabited rooms. All motifs are
## centimetre-scale relief on an established transverse bulkhead, not decals.
## Two non-shadowing surfaces per room, plus the tea cabinet’s ceramic batch.
## Visible relief uses the actual contact mesh.

const Finishes := preload("res://scripts/material_library.gd")
const Props := preload("res://scripts/prop_meshes.gd")
const Sleep := preload("res://scripts/sleeping_assets.gd")
const Veneer := preload("res://scripts/fitted_veneer.gd")
static var wall_wood: Dictionary = {}
const F := Finishes.Finish
const MERIDIAN := {
 "1:-1:840": [ "ConciergeFascia",F.MARBLE,"4c5a46", F.WALNUT,"2c4b36",F.BRASS,"9a8056"],
 "1:1:840": [ "CloakroomLockers",F.LEATHER,"3c4148", F.STEEL,"40505f",F.STEEL,"858783"],
 "1:-1:990": [ "DiningSunburst",F.DAMASK,"573d47", F.WALNUT,"5b493e",F.BRASS,"9d805c"],
 "1:1:990": [ "TeawareShelves",F.LINEN,"454f49", F.WALNUT,"314c43",F.BRASS,"a1a093"],
 "1:-1:1390": [ "PantryCanisterRack",F.CERAMIC,"716e5b", F.STEEL,"45413a",F.BRASS,"986e55"],
 "1:1:1390": [ "StewardVentHousing",F.STEEL,"465464", F.STEEL,"3e4852",F.STEEL,"7c8279"]
}

const RESIDENCES := {
 "0:-1:0": ["WritingBerthTambour",F.WALNUT,"543e35",F.WALNUT,"553e35",F.BRASS,"987b5f"],
 "0:1:0": ["CrewKitShelf",F.LINEN,"797259",F.WALNUT,"777358",F.STEEL,"68756c"],
 "0:-1:360": ["CoastPorthole",F.LINEN,"6d7576",F.WALNUT,"5d6059",F.BRASS,"a49b84"],
 "0:1:360": ["EngineeringInstrumentBay",F.STEEL,"3d4c4c",F.STEEL,"313a40",F.STEEL,"646860"]
}

const ARCHIVES := {
 "2:-1:1680": ["OrchidVitrineRibs",F.CERAMIC,"627463",F.STEEL,"46584d",F.BRASS,"8b7e5a"],
 "2:1:1680": ["PottingDrainboard",F.PLASTER,"a19075",F.TERRACOTTA,"6f5341",F.STEEL,"7f8481"],
 "2:-1:2045": ["HeritageSeedDrawers",F.WALNUT,"554a3b",F.WALNUT,"7d6c54",F.BRASS,"8d7a54"],
 "2:1:2045": ["ReserveCanopy",F.CERAMIC,"95a09a",F.STEEL,"4c6061",F.STEEL,"8b9592"]
}

static func garden(side: int, lo: float) -> Dictionary:
 if lo < 2045:
  if side < 0: return {"profile":"orchid","wood":Color("4a5144"),"inset":Color("a9a48a"),"metal":Color("8b7854"),"field":F.CERAMIC,"detail":F.BRASS}
  return {"profile":"potting","wood":Color("665447"),"inset":Color("855d49"),"metal":Color("788382"),"field":F.TERRACOTTA,"detail":F.STEEL}
 if side < 0: return {"profile":"heritage","wood":Color("554835"),"inset":Color("65513f"),"metal":Color("ad8c61"),"field":F.WALNUT,"detail":F.BRASS}
 return {"profile":"reserve","wood":Color("485655"),"inset":Color("92a6a0"),"metal":Color("7f9390"),"field":F.CERAMIC,"detail":F.STEEL}

static func style(room: Dictionary) -> Array:
 var key := "%d:%d:%d"%[room.car,room.side,room.lo]
 return RESIDENCES.get(key,MERIDIAN.get(key,ARCHIVES.get(key,[])))

static func service(side: int, lo: float) -> Dictionary:
 if lo < 990:
  if side < 0: return {"casework":"concierge","frame":Color("365248"),"panel":Color("30463a"),"stone":Color("686e5c")}
  return {"casework":"cloak","frame":Color("414d62"),"panel":Color("373e49"),"stone":Color("666057")}
 if side < 0: return {"casework":"pantry","frame":Color("655c4e"),"panel":Color("837763"),"stone":Color("9b8b6b")}
 return {"casework":"steward","frame":Color("414c55"),"panel":Color("333e4b"),"stone":Color("6c746c")}

static func sleeping(side: int, lo: float) -> Dictionary:
 if is_zero_approx(lo):
  if side < 0: return {"frame":Color("4a332e"),"cover":Color("653845"),"linen":Color("d9c8ad"),"binding":Color("ad876c"),"outline":"fan"}
  return {"frame":Color("747057"),"cover":Color("53583f"),"linen":Color("c5bea8"),"binding":Color("909176"),"outline":"bolster"}
 if side < 0: return {"frame":Color("655e4f"),"cover":Color("69777d"),"linen":Color("dfd6c4"),"binding":Color("a1957b"),"outline":"round"}
 return {"frame":Color("383e3d"),"cover":Color("454d45"),"linen":Color("999887"),"binding":Color("777d6b"),"outline":"stepped"}

static func bulkhead_liner_inset(car: int, boundary: float) -> float:
 # Shell boundary boxes are 10 cm wide. On internal 5 cm partitions the
 # normal 3.5 cm liner already clears the physical finish.
 var ends := [Vector2(0,800),Vector2(840,1640),Vector2(1680,2480)]
 if car < 0 or car >= ends.size(): return 3.5
 var limits: Vector2 = ends[car]
 return 5.28 if is_equal_approx(boundary,limits.x) or is_equal_approx(boundary,limits.y) else 3.5

static func wall(room: Dictionary) -> Material:
 var spec := style(room)
 if spec.is_empty(): return null
 if spec[1]==F.WALNUT:
  var key: String = spec[0]
  if not wall_wood.has(key): wall_wood[key] = Veneer.make("field",Color(spec[2]))
  return wall_wood[key]
 return Finishes.make(spec[1],Color(spec[2]),false,false,spec[1]==F.STEEL)

static func mount(room:Dictionary)->Transform3D:
 # A berth's signature fitting belongs on the wall seen on entering it.
 # Three aft-entry berths were looking towards the lower-Z bulkhead while
 # their fittings were all on the wall behind the entrance. Keep each
 # original shape and face its occupied bay, rather than duplicating it.
 var towards_positive:bool=room.car==0 and float(room.get("entry",room.lo))>(room.lo+room.hi)*0.5
 var end:float=room.lo if towards_positive else room.hi
 var sign_z:=1.0 if towards_positive else -1.0
 var surface_z:=end+sign_z*(bulkhead_liner_inset(room.car,end)+0.5)
 var rotation:=Basis(Vector3.UP,PI) if towards_positive else Basis.IDENTITY
 return Transform3D(rotation,Vector3(room.side*350.0,160.0,surface_z))

static func draw(world: Node3D,parent: Node3D,room: Dictionary) -> void:
 var spec := style(room)
 if spec.is_empty(): return
 # The exposed insert projects only inward from the room's established
 # transverse finish. Keeping centre X=±350 avoids the existing 285 pilaster.
 var motif := Node3D.new()
 motif.name = spec[0]
 parent.add_child(motif)
 motif.transform = mount(room)
 var frame := SurfaceTool.new()
 var metal := SurfaceTool.new()
 frame.begin(Mesh.PRIMITIVE_TRIANGLES)
 metal.begin(Mesh.PRIMITIVE_TRIANGLES)
 render(motif.name,frame,metal)
 var i := 0
 for batch in [frame,metal]:
  var mesh: MeshInstance3D = world.mesh_obj(motif,batch.commit(),Vector3.ZERO,Color.WHITE,true)
  mesh.name = "Finish" if i==0 else "Relief"
  mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  mesh.material_override = Finishes.make(spec[3+i*2],Color(spec[4+i*2]),false,false,i==0 and spec[3]==F.STEEL)
  i += 1
 if motif.name=="TeawareShelves":
  var wares: MeshInstance3D = world.mesh_obj(motif,teaware(),Vector3.ZERO,Color.WHITE,true)
  wares.name = "TeacupsAndSaucers"
  wares.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  wares.material_override = Finishes.make(F.CERAMIC,Color("b5aa8f"))

static func render(kind: String,frame: SurfaceTool,metal: SurfaceTool) -> void:
 match kind:
  "WritingBerthTambour":
   chamfer_slab(frame,Vector2(0,0),Vector2(79,60),9.0,2.5)
   for i in range(11):
    var x := -31.0+i*6.2
    var h := 15.0+12*cos(x/37.0*PI*0.5)
    rail(frame,Vector2(x,-22),Vector2(x,h),2.9,3.4+i%2*1.2)
   for y in [-27.0,25.0]: rail(metal,Vector2(-34,y),Vector2(34,y),1.8,5.0)
   rail(metal,Vector2(-11,-19),Vector2(11,-19),2.4,5.8)
  "CrewKitShelf":
   chamfer_slab(frame,Vector2(0,-6),Vector2(86,49),10.0,2.2)
   rail(frame,Vector2(-40,23),Vector2(40,23),4.5,5.9)
   for x in [-35.,-12.,12.,35.]:
    rail(metal,Vector2(x,-21),Vector2(x,21),1.85,4.5)
    rail(metal,Vector2(x-3,-12),Vector2(x+3,-12),2.4,5.8)
   rail(frame,Vector2(-36,-27),Vector2(36,-27),3,4.4)
  "CoastPorthole":
   disc(frame,Vector2(0,0),34,36,3.0)
   ring(metal,Vector2(0,0),33,26,40,4.0)
   ring(metal,Vector2(0,0),23.6,22.4,40,4.5)
   for i in range(7):
    var theta := TAU*i/7
    disc(frame,Vector2(cos(theta),sin(theta))*29.4,1.6,10,5.4)
   rail(frame,Vector2(-22,-17),Vector2(22,-17),1.65,3.5)
  "EngineeringInstrumentBay":
   chamfer_slab(frame,Vector2.ZERO,Vector2(84,67),3,3.6)
   chamfer_slab(frame,Vector2(-15,9),Vector2(40,37),6,5.0)
   for i in range(4):
    rail(metal,Vector2(10,19-i*10),Vector2(32,19-i*10),2.25,5.5)
   for x in [-28,-15,-2]:
    ring(metal,Vector2(x,-22),3.3,2.1,12,4.7)
   rail(metal,Vector2(-6,5),Vector2(-20,13),1.3,5.7)
  "OrchidVitrineRibs":
   fan(frame,Vector2(0,-29),40,0.14,PI-0.14,24,2.8)
   arch(metal,Vector2(0,-29),38,34,43,2.5,4.6)
   arch(metal,Vector2(0,-29),31,25,36,1.72,4.4)
   for x in [-21,0,21]:
    rail(frame,Vector2(x,-24),Vector2(x,5+(15 if x==0 else 0)),3.1,4.1)
   rail(metal,Vector2(-37,-29),Vector2(37,-29),2.2,5.1)
  "PottingDrainboard":
   chamfer_slab(frame,Vector2(0,3),Vector2(87,65),4,2.4)
   chamfer_slab(frame,Vector2(-15,-1),Vector2(48,43),8,4.2)
   chamfer_slab(metal,Vector2(-15,-1),Vector2(37,31),5,5.5)
   for i in range(8): rail(metal,Vector2(13,-26+i*7),Vector2(35,-25+i*7),1.3,5.25)
   ring(metal,Vector2(-16,-8),4,2,12,5.9)
  "HeritageSeedDrawers":
   for y in [-22.0,0.0,22.0]:
    for x in [-21.0,21.0]:
     chamfer_slab(frame,Vector2(x,y),Vector2(39,19),3.2,2.9)
     chamfer_slab(frame,Vector2(x,y),Vector2(33,12.5),3.5,4.35)
     rail(metal,Vector2(x-3.8,y),Vector2(x+3.8,y),1.65,5.8)
   rail(metal,Vector2(-44,-36),Vector2(44,-36),2.45,4.1)
  "ReserveCanopy":
   chamfer_slab(frame,Vector2(0,-6),Vector2(83,52),6,2.6)
   for x in [-25.5,0.0,25.5]:
    arch(metal,Vector2(x,-9),13,10,32,1.7,4.4)
    rail(metal,Vector2(x-12.9,-29),Vector2(x-12.9,-9),1.6,4.6)
    rail(metal,Vector2(x+12.9,-29),Vector2(x+12.9,-9),1.6,4.6)
   rail(frame,Vector2(-42,-30),Vector2(42,-30),2.6,5.1)
  "ConciergeFascia":
   stamp(frame,[Vector2(-41,-35),Vector2(41,-35),Vector2(41,5),Vector2(34,5),Vector2(34,16),Vector2(26,16),Vector2(26,26),Vector2(-26,26),Vector2(-26,16),Vector2(-34,16),Vector2(-34,5),Vector2(-41,5)],3.3)
   for i in range(3):
    var x := float(i)*7.0
    rail(metal,Vector2(-36+x,-22.0+x),Vector2(36-x,-22+x),1.5,4.1)
   rail(metal,Vector2(-23,25),Vector2(23,25),1.7,3.9)
  "CloakroomLockers":
   for x in [-29.0,0.0,29.0]:
    chamfer_slab(frame,Vector2(x,-3.0),Vector2(25.0,61.0),4.5,4.4)
    rail(metal,Vector2(x+7.0,-11.0),Vector2(x+7.0,-1.0),1.6,5.1)
    for div in range(3):
     rail(metal,Vector2(x-7.5,-23.0+div*3.2),Vector2(x+6.5,-23.0+div*3.2),0.82,4.7)
   rail(metal,Vector2(-45,33),Vector2(45,33),2.5,3.2)
  "DiningSunburst":
   fan(frame,Vector2(0,-24),40.0,0.0,PI,24,3.4)
   fan(frame,Vector2(0,-24),26.0,0.0,PI,20,4.2)
   for i in range(13):
    var theta := 0.13+(PI-0.26)*float(i)/12.0
    var direction := Vector2(cos(theta),sin(theta))
    rail(metal,Vector2(0,-24)+direction*7.0,Vector2(0,-24)+direction*36.0,1.15,4.65)
   fan(metal,Vector2(0,-24),8.5,0.0,PI,12,5.4)
   rail(frame,Vector2(-44,-27),Vector2(44,-27),3.5,4.5)
  "TeawareShelves":
   # Open tea wall cabinet with a back, two returned side panels, and a
   # real rounded shelf surface. No plate silhouettes on a flat plaque.
   chamfer_slab(frame,Vector2(0,0),Vector2(83,63),11.0,2.0)
   for x in [-38.5,38.5]:
    chamfer_slab(frame,Vector2(x,-1.4),Vector2(4.4,53.2),1.55,11.6)
   for y in [-24.0,5.0,26.0]:
    chamfer_slab(frame,Vector2(0,y),Vector2(78.5,2.8),0.88,11.6)
    rail(metal,Vector2(-35,y+0.2),Vector2(35,y+0.2),0.76,11.85)
  "PantryCanisterRack":
   chamfer_slab(frame,Vector2(0,0),Vector2(87,61),2.4,2.0)
   for y in [-25.0,4.0]:
    rail(frame,Vector2(-41,y),Vector2(41,y),3.6,6.4)
    for i in range(4):
     var x := -29.0+i*19.0
     var h := 11.0+float(i%3)*3.4
     chamfer_slab(metal,Vector2(x,y+2.0+h*0.5),Vector2(11,h),1.5,5.0)
     rail(frame,Vector2(x-6,y+h+2.0),Vector2(x+6,y+h+2.0),1.6,5.8)
  "StewardVentHousing":
   chamfer_slab(frame,Vector2(0,1),Vector2(77,72),9.0,3.5)
   chamfer_slab(frame,Vector2(0,1),Vector2(67,62),6.0,4.7)
   for i in range(9):
    var x := -26.0+6.5*i
    rail(metal,Vector2(x,-19),Vector2(x,23),1.6,5.3 if i%2 else 5.8)
   for y in [-25,28]: rail(metal,Vector2(-26,y),Vector2(26,y),1.6,5.1)

static func teaware() -> ArrayMesh:
 var forms := SurfaceTool.new()
 forms.begin(Mesh.PRIMITIVE_TRIANGLES)
 var saucer := Sleep.lathe([
  Vector2(0.004,0.0),Vector2(2.42,0.0),Vector2(3.79,0.22),Vector2(4.05,0.40),
  Vector2(4.08,0.60),Vector2(3.89,0.66),Vector2(3.21,0.42),Vector2(0.004,0.39)
 ],20)
 var cup := Sleep.lathe([
  Vector2(0.004,0.0),Vector2(1.95,0.0),Vector2(2.12,0.33),Vector2(2.34,1.16),
  Vector2(2.7,2.56),Vector2(2.69,3.08),Vector2(2.53,3.20),Vector2(2.33,3.14),
  Vector2(2.26,2.58),Vector2(1.93,1.15),Vector2(1.78,0.38),Vector2(0.004,0.36)
 ],24)
 for spec in [[-19.25,-24.0],[16.0,-24.0],[-4.4,5.0]]:
  var p := Vector3(spec[0],spec[1]+1.4,-7.0)
  forms.append_from(saucer,0,Transform3D(Basis.IDENTITY,p))
  forms.append_from(cup,0,Transform3D(Basis.IDENTITY,p+Vector3.UP*0.39))
  var from := p+Vector3(2.5,2.58,0)
  var loop := Props.tube([from,from+Vector3(0.75,0.35,0),from+Vector3(1.44,0.12,0),
   from+Vector3(1.55,-0.64,0),from+Vector3(1.0,-1.25,0),from+Vector3(-0.17,-1.21,0)],PackedFloat32Array([0.26]),10)
  forms.append_from(loop,0,Transform3D.IDENTITY)
 return forms.commit()

static func chamfer_slab(st: SurfaceTool, p: Vector2, size: Vector2, cut: float, depth: float) -> void:
 var half := size*0.5
 var contour := [Vector2(-half.x+cut,-half.y),Vector2(half.x-cut,-half.y),Vector2(half.x,-half.y+cut),Vector2(half.x,half.y-cut),Vector2(half.x-cut,half.y),Vector2(-half.x+cut,half.y),Vector2(-half.x,half.y-cut),Vector2(-half.x,-half.y+cut)]
 for i in range(contour.size()): contour[i] += p
 stamp(st,contour,depth)

static func arch(st: SurfaceTool,p: Vector2,rx: float,ry: float,height: float,width: float,depth: float) -> void:
 var outline: Array = []
 var scale := height/maxf(ry,1.0)
 for i in range(25):
  var a := PI*i/24.0
  outline.append(p+Vector2(rx*cos(a),ry*sin(a)*scale))
 for i in range(24,-1,-1):
  var a := PI*i/24.0
  outline.append(p+Vector2((rx-width)*cos(a),(ry-width)*sin(a)*scale))
 stamp(st,outline,depth)

static func disc(st: SurfaceTool,p: Vector2,radius: float,steps: int,depth: float) -> void:
 var contour: Array = []
 for i in range(steps):
  var a := TAU*float(i)/steps
  contour.append(p+Vector2(cos(a),sin(a))*radius)
 stamp(st,contour,depth)

static func ring(st: SurfaceTool,p: Vector2,radius: float,inner: float,steps: int,depth: float) -> void:
 for i in range(steps):
  var a := TAU*i/steps
  var b := TAU*(i+1)/steps
  var aa := Vector2(cos(a),sin(a))
  var bb := Vector2(cos(b),sin(b))
  # Join the top panels continuously, with actual bevel sides at each radius.
  var oa := p+aa*radius
  var ob := p+bb*radius
  var ia := p+aa*inner
  var ib := p+bb*inner
  triangle(st,point(oa,depth),point(ob,depth),point(ib,depth),Vector3.FORWARD)
  triangle(st,point(oa,depth),point(ib,depth),point(ia,depth),Vector3.FORWARD)
  for j in [0,1]:
   var lo := oa if j==0 else ia
   var hi := ob if j==0 else ib
   var n2 := (aa+bb).normalized()*(1 if j==0 else -1)
   var n := Vector3(n2.x,n2.y,0)
   triangle(st,point(lo,depth-1.4),point(hi,depth-1.4),point(hi,depth),n)
   triangle(st,point(lo,depth-1.4),point(hi,depth),point(lo,depth),n)

static func fan(st: SurfaceTool,p: Vector2,radius: float,from: float,to: float,steps: int,depth: float) -> void:
 var pts: Array = [p]
 for i in range(steps+1):
  var a := lerpf(from,to,float(i)/steps)
  pts.append(p+Vector2(cos(a),sin(a))*radius)
 stamp(st,pts,depth)

static func rail(st: SurfaceTool,a: Vector2,b: Vector2,width: float,depth: float) -> void:
 var tangent := (b-a).normalized()
 var n := Vector2(-tangent.y,tangent.x)*width*0.5
 stamp(st,[a-n+tangent*0.25,b-n-tangent*0.25,b+n-tangent*0.25,a+n+tangent*0.25],depth)

static func stamp(st: SurfaceTool, pts: Array, depth: float) -> void:
 # Clockwise render faces and accurate side normals. Back seam sinks
 # into the wall finish; concave fronts are explicitly triangulated.
 var xy := PackedVector2Array(pts)
 var tri := Geometry2D.triangulate_polygon(xy)
 for i in range(0,tri.size(),3):
  var a := point(xy[tri[i]],depth)
  var b := point(xy[tri[i+1]],depth)
  var c := point(xy[tri[i+2]],depth)
  triangle(st,a,b,c,Vector3.FORWARD)
 for i in range(xy.size()):
  var a := xy[i]
  var b := xy[(i+1)%xy.size()]
  var n2 := Vector2(b.y-a.y,a.x-b.x).normalized()
  var n := Vector3(n2.x,n2.y,0)
  triangle(st,point(a,-0.70),point(b,-0.70),point(b,depth),n)
  triangle(st,point(a,-0.70),point(b,depth),point(a,depth),n)

static func point(p: Vector2, depth: float) -> Vector3:
 return Vector3(p.x,p.y,-depth)

static func triangle(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,n: Vector3) -> void:
 if (b-a).cross(c-a).length_squared() < 0.00001: return
 var order := [a,c,b] if (b-a).cross(c-a).dot(n)>0 else [a,b,c]
 for p: Vector3 in order:
  st.set_normal(n)
  st.set_uv(Vector2(p.x,p.y)*0.01)
  st.add_vertex(p)
