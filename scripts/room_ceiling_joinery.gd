extends RefCounted
## Real low-profile coffer moulding in each outer room. The original roof,
## glazing, case lights, pipes and door heights are unchanged.
const Stone:=preload("res://scripts/material_library.gd")
const Grain:=preload("res://scripts/fitted_veneer.gd")
const Winding:=preload("res://scripts/prop_meshes.gd")
const RECIPES:Dictionary={
 "0:-1:0":[0,"b7aa8c","564435","91765a"],"0:1:0":[1,"a7a48d","695d45","9d967c"],
 "0:-1:360":[2,"9ca6a2","686f65","b0aa98"],"0:1:360":[1,"929e9c","424f50","899194"],
 "1:-1:840":[2,"9aab95","465846","9b835e"],"1:1:840":[1,"949092","4a5461","918a79"],
 "1:-1:990":[0,"bba68a","624638","b29a6e"],"1:1:990":[2,"9daf9c","4b6251","a69b84"],
 "1:-1:1390":[1,"b8ac92","736451","a29984"],"1:1:1390":[1,"9babb0","52656e","929d9d"],
 "2:-1:1680":[2,"a2baa8","53665d","919c90"],"2:1:1680":[1,"a6ab9e","65736b","90988e"],
 "2:-1:2045":[0,"a4a08c","584a3c","9c876d"],"2:1:2045":[2,"a6bcb4","526c66","9faeab"]
}
static var surface_cache:Dictionary={}
static var style_cache:Dictionary={}

static func build(world:Node3D,parent:Node3D,car:int,side:int,lo:float,hi:float)->Node3D:
 var role:="%d:%d:%d"%[car,side,int(lo)]
 if not RECIPES.has(role):return null
 var item:Array=RECIPES[role]
 var span:=hi-lo-42.0
 var model_name:="%d_%s"%[int(item[0]),str(span)]
 if not surface_cache.has(model_name):surface_cache[model_name]=profile(int(item[0]),span)
 if not style_cache.has(role):
  var sides_are_metal:=car==2 or (car!=2 and int(item[0])==1 and side>0 and lo>0)
  var face:=Stone.make(Stone.Finish.PLASTER,Color(item[1]))
  var casing:=Stone.make(Stone.Finish.STEEL,Color(item[2]),false,false,true) if sides_are_metal else Grain.make("table",Color(item[2]))
  var bead:=Stone.make(Stone.Finish.STEEL,Color(item[3]),false,false,true) if sides_are_metal else Stone.make(Stone.Finish.BRASS,Color(item[3]))
  style_cache[role]=[face,casing,bead]
 var module:=Node3D.new()
 module.name="FittedCabinCeiling_"+role.replace(":","_")
 module.position=Vector3(side*332.0,294.0,(lo+hi)*0.5)
 module.set_meta("ceiling_role",role)
 parent.add_child(module)
 for k in range(3):
  var mesh:MeshInstance3D=world.mesh_obj(module,surface_cache[model_name][k],Vector3.ZERO,Color.WHITE,true)
  mesh.name=["RecessedCeilingInfill","CofferTimberProfile","CofferRoundBead"][k]
  mesh.material_override=style_cache[role][k]
  mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  var exact:=mesh.get_child(0).get_child(0) as CollisionShape3D
  (exact.shape as ConcavePolygonShape3D).backface_collision=true
 return module

static func sheet()->SurfaceTool:
 var result:=SurfaceTool.new()
 result.begin(Mesh.PRIMITIVE_TRIANGLES)
 return result

static func shape(half:Vector2,kind:int)->PackedVector2Array:
 var corners:=PackedVector2Array()
 var radius:=23.0 if kind==0 else (8.0 if kind==1 else 34.0)
 radius=minf(radius,minf(half.x,half.y)*0.55)
 for q in range(4):
  var sign_x:=1.0 if q in [0,3] else -1.0
  var sign_z:=1.0 if q in [0,1] else -1.0
  var center:=Vector2(sign_x*(half.x-radius),sign_z*(half.y-radius))
  for s in range(8):
   var angle:=q*PI/2.0+s*PI/14.0
   var p:=center+Vector2(cos(angle),sin(angle))*radius
   if kind==2:
    p.x-=sign_x*7.6*pow(absf(p.y/half.y),3.0)
   if kind==0:
    p.y-=sign_z*4.2*pow(absf(p.x/half.x),2.0)
   corners.append(p)
 return corners

static func profile(kind:int,z_width:float)->Array[ArrayMesh]:
 var edges:=[sheet(),sheet(),sheet()]
 var record:Array=[
  [0.0,0.22,1],[1.4,2.16,1],[3.2,4.2,1],[4.8,5.25,2],
  [5.9,6.35,2],[6.7,5.70,2],[8.1,3.88,1],[11.0,2.26,1],[14.3,1.27,0]]
 var prev:=PackedVector2Array()
 var before:=0.0
 for point:Array in record:
  var half:=Vector2(126,z_width*0.5)-Vector2.ONE*float(point[0])
  var rim:=shape(half,kind)
  var y:float=-point[1]
  if not prev.is_empty():
   for i in range(rim.size()):
    var n:=(i+1)%rim.size()
    panel(edges[int(point[2])],[Vector3(prev[i].x,before,prev[i].y),Vector3(prev[n].x,before,prev[n].y),
     Vector3(rim[n].x,y,rim[n].y),Vector3(rim[i].x,y,rim[i].y)])
  prev=rim
  before=y
 var points:=Geometry2D.triangulate_polygon(prev)
 for i in range(0,points.size(),3):
  var a:=prev[points[i]]
  var b:=prev[points[i+1]]
  var c:=prev[points[i+2]]
  var one:=Vector3(a.x,before,a.y)
  var two:=Vector3(b.x,before,b.y)
  var three:=Vector3(c.x,before,c.y)
  panel(edges[0],[one,two,three,three])
 return [edges[0].commit(),edges[1].commit(),edges[2].commit()]

static func panel(target:SurfaceTool,corner:Array[Vector3])->void:
 var n:Vector3=(corner[1]-corner[0]).cross(corner[3]-corner[0]).normalized()
 if n.y>0:n=-n
 if n.is_zero_approx():return
 Winding.quad(target,corner,[n,n,n,n])
