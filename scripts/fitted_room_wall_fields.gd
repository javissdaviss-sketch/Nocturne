extends RefCounted
## Actual shallow room-side raised joinery within existing structural wall
## spans. Each car uses a different silhouette and room-led finishing recipe.
## Doesn't widen a doorway, move a light, or touch the corridor wainscot.
const F:=preload("res://scripts/material_library.gd")
const V:=preload("res://scripts/fitted_veneer.gd")
const P:=preload("res://scripts/prop_meshes.gd")
const Id:=preload("res://scripts/room_identity.gd")
const WALL_ROLE:Dictionary={
 "0:-1:0":[0,"594437","967253"],"0:1:0":[1,"746b4f","a39a73"],"0:-1:360":[2,"57605c","9a967e"],"0:1:360":[1,"434f4e","777f77"],
 "1:-1:840":[2,"41574a","9c8156"],"1:1:840":[1,"495056","847c67"],"1:-1:990":[0,"5c4134","a28057"],"1:1:990":[2,"485f50","918872"],
 "1:-1:1390":[1,"716658","9a8771"],"1:1:1390":[1,"485b63","828987"],
 "2:-1:1680":[2,"576d5e","8a9980"],"2:1:1680":[1,"716352","94846a"],"2:-1:2045":[0,"64503c","a38b65"],"2:1:2045":[2,"527067","949d91"]
}
static var cached:Dictionary={}

static func dress(world:Node3D,parent:Node3D,room:Dictionary,x:float,lo:float,hi:float)->bool:
 var side:int=room.side
 if signf(x)!=side or absf(x)<57.9 or hi-lo<29.0: return false
 var spec_id:="%d:%d:%d"%[room.car,side,int(room.lo)]
 # Tea retains its proven original wall surface. Its new thin rounded
 # outline showed a visible striping defect under the held native camera.
 if spec_id=="1:1:990" or not WALL_ROLE.has(spec_id): return false
 var spec:Array=WALL_ROLE[spec_id]
 var skin:=Id.wall(room)
 if skin==null: return false
 if not cached.has(spec_id):
  var trim_tone:=Color(spec[1])
  var fillet_tone:=Color(spec[2])
  var metal_role:bool=room.car==2 or (room.car==0 and side>0 and room.lo>=360.0) or (room.car==1 and side>0 and room.lo>=1390.0)
  cached[spec_id]=[
   skin,
   F.make(F.Finish.STEEL,trim_tone,false,false,true) if metal_role else V.make("field",trim_tone),
   F.make(F.Finish.STEEL,fillet_tone,false,false,true) if metal_role else F.make(F.Finish.BRASS,fillet_tone)]
 var renderers:Array=cached[spec_id]
 var origin:=Vector3(x+side*0.25,153,(lo+hi)*0.5)
 var fields:=Node3D.new()
 fields.name="FittedRoomSideField_%s_%d"%[spec_id.replace(":","_"),int(lo*10)]
 fields.position=origin
 fields.set_meta("fitted_room_wall_role",spec_id)
 parent.add_child(fields)
 var buffers:Array[ArrayMesh]=forms(side,room.car,spec[0],hi-lo)
 for i in range(buffers.size()):
  var trim:MeshInstance3D=world.mesh_obj(fields,buffers[i],Vector3.ZERO,Color.WHITE,true)
  trim.name=["FittedFieldSurface","SolidRoundedBorder","BeadedReturn"][i]
  trim.material_override=renderers[i]
  trim.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var shape:=trim.get_child(0).get_child(0) as CollisionShape3D
  (shape.shape as ConcavePolygonShape3D).backface_collision=true
 return true

static func face_outline(h:float,w:float,kind:int,center:float)->PackedVector2Array:
 var pts:=PackedVector2Array()
 var corner:float=3.8 if kind==0 else (1.55 if kind==1 else 8.2)
 corner=minf(corner,minf(w,h)*0.22)
 for i in range(4):
  var cx:=1 if i in [0,3] else -1
  var cy:=1 if i in [0,1] else -1
  var a:=Vector2(cx*(w*0.5-corner),cy*(h*0.5-corner))
  for k in range(5):
   var phi:=i*PI*0.5+k*PI/8.0
   var next:=a+Vector2(cos(phi),sin(phi))*corner
   # Soft raised arch in greenhouse/guest panels; squared utility bay's
   # lower plank remains flat and no room portal is formed by this mesh.
   if kind==2 and next.y>0.0:
    next.y-=4.35*pow(absf(next.x/(w*0.5)),2.0)
   if kind==0 and next.y>0.0:
    next.y-=1.5*pow(absf(next.x/(w*0.5)),4.0)
   pts.append(next+Vector2(center,0))
 return pts

static func builder()->SurfaceTool:
 var s:=SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 return s

static func forms(side:int,car:int,kind:int,length:float)->Array[ArrayMesh]:
 var supports:=builder()
 var frame:=builder()
 var beads:=builder()
 var divisions:=maxi(1,roundi(length/(81.0 if kind==1 else 99.0)))
 var width:=length/divisions-8.0
 var height:=101.3 if car!=2 else 94.0
 for i in range(divisions):
  var center:=-length*0.5+(i+0.5)*length/divisions
  var suite:Array=[
   [0.00,0.16,0],[0.69,0.41,1],[1.32,1.17,1],[1.90,1.70,1],
   [2.38,1.86,2],[2.75,1.70,2],[3.22,1.23,1],[3.85,0.81,1],
   [4.55,0.52,0],[5.30,0.45,0]]
  var targets:Array=[supports,frame,beads]
  var prior:=PackedVector2Array()
  var deep:=0.0
  for step:Array in suite:
   var shrink:float=float(step[0])*2.0
   var ring:=face_outline(height-shrink,width-shrink,kind,center)
   if not prior.is_empty():
    for j in range(ring.size()):
     var k:=(j+1)%ring.size()
     place(targets[step[2]],[
      Vector3(deep*side,prior[j].y,prior[j].x),Vector3(deep*side,prior[k].y,prior[k].x),
      Vector3(step[1]*side,ring[k].y,ring[k].x),Vector3(step[1]*side,ring[j].y,ring[j].x)
     ],side)
   prior=ring
   deep=step[1]
  var tris:=Geometry2D.triangulate_polygon(prior)
  for t in range(0,tris.size(),3):
   var a:=prior[tris[t]]
   var b:=prior[tris[t+1]]
   var c:=prior[tris[t+2]]
   place(supports,[Vector3(deep*side,a.y,a.x),Vector3(deep*side,b.y,b.x),
    Vector3(deep*side,c.y,c.x),Vector3(deep*side,c.y,c.x)],side)
 return [supports.commit(),frame.commit(),beads.commit()]

static func place(target:SurfaceTool,p:Array[Vector3],side:int)->void:
 var v:Vector3=(p[1]-p[0]).cross(p[3]-p[0]).normalized()
 if v.x*side<0.0:v=-v
 if v.is_zero_approx():return
 P.quad(target,p,[v,v,v,v])
