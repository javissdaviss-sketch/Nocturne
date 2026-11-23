extends RefCounted
## Real trim cross-sections. Side and head share a handed shape and stay
## strictly in the old 9x3 aperture border. No new light, signs or door leaf.
const F:=preload("res://scripts/material_library.gd")
const V:=preload("res://scripts/fitted_veneer.gd")
const P:=preload("res://scripts/prop_meshes.gd")
static var meshes:Dictionary={}
static var finishes:Dictionary={}

static func add(world:Node3D,parent:Node3D,car:int,center:Vector3,size:Vector3) -> Node3D:
 var head:=size.z>size.y
 var left:=center.x<0.0
 var key:="%d/%d/%d/%s"%[car,int(head),int(left),str(size)]
 if not meshes.has(key): meshes[key]=models(car,size,head,left)
 if not finishes.has(car): finishes[car]=tones(car)
 var wrap:=Node3D.new()
 wrap.name="FoldedBerthArchitrave" if car==0 else "EnamelGardenArchitrave"
 parent.add_child(wrap,true)
 wrap.position=center
 for i in range(2):
  var piece:MeshInstance3D=world.mesh_obj(wrap,meshes[key][i],Vector3.ZERO,Color.WHITE,true)
  piece.name="ShapedBearing" if i==0 else "AppliedContinuityBead"
  piece.material_override=finishes[car][i]
  if i==1: piece.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var shape:=piece.get_child(0).get_child(0) as CollisionShape3D
  (shape.shape as ConcavePolygonShape3D).backface_collision=true
 return wrap

static func tones(car:int)->Array:
 if car==0: return [V.make("field",Color("5b4939")),F.make(F.Finish.BRASS,Color("9e8563"))]
 return [F.make(F.Finish.STEEL,Color("485b56"),false,false,true),F.make(F.Finish.STEEL,Color("9ba398"),false,false,true)]

static func profile(car:int)->Array:
 # (corridor-facing section depth, crosswise half-height/width). Not a
 # second visible box: the true bearing has a folded shoulder and bore.
 if car==0: return [Vector2(-4.50,-0.82),Vector2(-4.38,-1.15),Vector2(-3.93,-1.44),Vector2(-3.46,-1.5),
  Vector2(-2.88,-1.5),Vector2(-2.51,-1.32),Vector2(-1.90,-1.09),Vector2(-1.06,-1.07),
  Vector2(-0.45,-1.38),Vector2(0.18,-1.50),Vector2(4.0,-1.50),Vector2(4.5,-1.28),
  Vector2(4.50,1.28),Vector2(4.0,1.50),Vector2(0.18,1.50),Vector2(-0.45,1.38),
  Vector2(-1.06,1.07),Vector2(-1.90,1.09),Vector2(-2.51,1.32),Vector2(-2.88,1.50),
  Vector2(-3.46,1.50),Vector2(-3.93,1.44),Vector2(-4.38,1.15),Vector2(-4.5,0.82)]
 return [Vector2(-4.5,-0.67),Vector2(-4.36,-0.96),Vector2(-3.90,-0.98),
  Vector2(-3.57,-1.44),Vector2(-2.92,-1.5),Vector2(-2.12,-1.50),Vector2(-1.88,-1.15),
  Vector2(-0.60,-1.15),Vector2(-0.36,-1.44),Vector2(0.38,-1.5),Vector2(4.20,-1.50),
  Vector2(4.50,-1.16),Vector2(4.50,1.16),Vector2(4.20,1.50),Vector2(0.38,1.50),
  Vector2(-0.36,1.44),Vector2(-0.60,1.15),Vector2(-1.88,1.15),Vector2(-2.12,1.5),
  Vector2(-2.92,1.5),Vector2(-3.57,1.44),Vector2(-3.90,0.98),Vector2(-4.36,0.96),Vector2(-4.50,0.67)]

static func models(car:int,size:Vector3,head:bool,left:bool)->Array:
 var body:=SurfaceTool.new()
 body.begin(Mesh.PRIMITIVE_TRIANGLES)
 var trim:=SurfaceTool.new()
 trim.begin(Mesh.PRIMITIVE_TRIANGLES)
 var cross:=profile(car)
 var half:=size.z*0.5 if head else size.y*0.5
 var orient:=Transform3D(Basis(Vector3(-1.0 if left else 1.0,0,0),
  Vector3(0,1,0) if head else Vector3(0,0,1),Vector3(0,0,1) if head else Vector3(0,1,0)),Vector3.ZERO)
 for i in range(cross.size()):
  var a:Vector2=cross[i]
  var b:Vector2=cross[(i+1)%cross.size()]
  var edge:Vector2=b-a
  var n:=orient.basis*Vector3(edge.y,-edge.x,0).normalized()
  # Small shallow chamfers close the end grain as actual geometry.
  P.quad(body,[orient*Vector3(a.x,a.y,-half+0.16),orient*Vector3(b.x,b.y,-half+0.16),
   orient*Vector3(b.x,b.y,half-0.16),orient*Vector3(a.x,a.y,half-0.16)],[n,n,n,n])
  for s in [-1,1]:
   var m:=orient.basis*Vector3(0,0,s)
   P.quad(body,[orient*Vector3(a.x,a.y,s*(half-0.16)),orient*Vector3(b.x,b.y,s*(half-0.16)),
    orient*Vector3(b.x*0.97,b.y*0.96,s*half),orient*Vector3(a.x*0.97,a.y*0.96,s*half)],[m,m,m,m])
 var polygon:=PackedVector2Array()
 for a:Vector2 in cross: polygon.append(a*Vector2(0.97,0.96))
 var idx:=Geometry2D.triangulate_polygon(polygon)
 for s in [-1,1]:
  var outward:=orient.basis*Vector3(0,0,s)
  for i in range(0,idx.size(),3):
   var a:=orient*Vector3(polygon[idx[i]].x,polygon[idx[i]].y,s*half)
   var b:=orient*Vector3(polygon[idx[i+1]].x,polygon[idx[i+1]].y,s*half)
   var c:=orient*Vector3(polygon[idx[i+2]].x,polygon[idx[i+2]].y,s*half)
   P.quad(body,[a,b,c,c],[outward,outward,outward,outward])
 for radius in [-1.0,1.0]:
  var edge:=float(radius)*(0.70 if car==0 else 0.59)
  var depth:=-4.33 if car==0 else -4.345
  var rail:Array[Vector3]=[orient*Vector3(depth,edge,-half+0.6),orient*Vector3(depth,edge,half-0.6)]
  trim.append_from(P.tube(rail,PackedFloat32Array([0.155]),8),0,Transform3D.IDENTITY)
 return [body.commit(),trim.commit()]
