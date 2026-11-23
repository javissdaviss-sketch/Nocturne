extends RefCounted
## Original Art Deco elevation relief for one track-side hotel, not a flat
## sign plate. World-space batched geometry; no lights, collision or RNG.
const WIDTH:=272.0
const RECESS:=6.35
static var authored:Array[Dictionary]=[]

static func make_records()->Array[Dictionary]:
 if not authored.is_empty():return authored
 var result:=SurfaceTool.new()
 result.begin(Mesh.PRIMITIVE_TRIANGLES)
 # Stepped, stone pilasters form the fixed sign surround outside its halo.
 for side in [-1,1]:
  rolled_strip(result,side*139.0,-72.0,69.0)
  rolled_strip(result,side*151.0,-61.0,77.0)
  slab(result,Vector2(side*145.0,-65.0),Vector2(25,14),5.7,8.5,Color("96816a"))
  slab(result,Vector2(side*144.0,67.0),Vector2(25,15),6.1,9.7,Color("83785f"))
 # Rolled header corners and three graduated terrazzo tiers.
 slab(result,Vector2(0,67.5),Vector2(WIDTH,13),4.0,12.5,Color("a3947c"))
 slab(result,Vector2(0,80.5),Vector2(220,15),6.0,9.8,Color("91806a"))
 slab(result,Vector2(0,93),Vector2(143,17),7.0,7.5,Color("a08a70"))
 slab(result,Vector2(0,106),Vector2(59,13),5.0,5.9,Color("937f63"))
 for i in range(7):
  var u:=float(i)-3.0
  var bar:=u*18.0
  slab(result,Vector2(bar,86+12*cos(u*0.41)),Vector2(4.6,31-3.5*absf(u)),1.1,10.25,Color("605d55"))
 # Dark glass/casing shadow gap below the original sign, above street.
 slab(result,Vector2(0,-55),Vector2(259,9),3.0,4.7,Color("544d43"))
 var mesh:=result.commit()
 var data:=mesh.surface_get_arrays(0)
 var positions:PackedVector3Array=data[Mesh.ARRAY_VERTEX]
 var normals:PackedVector3Array=data[Mesh.ARRAY_NORMAL]
 var colors:PackedColorArray=data[Mesh.ARRAY_COLOR]
 for i in range(positions.size()): authored.append({"p":positions[i],"n":normals[i],"c":colors[i]})
 return authored

static func append_batch(out:SurfaceTool,side:int,sign_pos:Vector3)->void:
 var t:=Transform3D(Basis(Vector3.UP,-side*PI*0.5),sign_pos+Vector3(side*RECESS,0,0))
 for v in make_records():
  out.set_color(v.c)
  out.set_normal(t.basis*v.n)
  out.add_vertex(t*v.p)

static func attach(parent:Node3D,mesh:ArrayMesh)->void:
 var assembly:=MeshInstance3D.new()
 assembly.name="GraduatedHotelCarvedStone"
 assembly.mesh=mesh
 assembly.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var material:=StandardMaterial3D.new()
 material.vertex_color_use_as_albedo=true
 material.roughness=0.72
 material.metallic=0.0
 assembly.material_override=material
 parent.add_child(assembly)

static func rolled_strip(out:SurfaceTool,x:float,lo:float,hi:float)->void:
 var p0:=Vector3.ZERO
 var p1:=Vector3.ZERO
 var cool:=Color("8d7e6c")
 for i in range(15):
  var a:=float(i)*PI/14.0
  var edge:=Vector3(x+5.45*cos(a),lo+3.4*sin(a),3.0+5.0*sin(a))
  var top:=Vector3(edge.x,hi-2.4*sin(a),edge.z)
  if i>0:
   var n:=Vector3(cos(a-PI/28.0),0,sin(a-PI/28.0)).normalized()
   polygon(out,[p0,p1,top,edge],n,cool)
  p0=edge
  p1=top

static func slab(out:SurfaceTool,at:Vector2,size:Vector2,chamfer:float,depth:float,tone:Color)->void:
 var r:=size*0.5
 var poly:=[Vector2(-r.x+chamfer,-r.y),Vector2(r.x-chamfer,-r.y),Vector2(r.x,-r.y+chamfer),
  Vector2(r.x,r.y-chamfer),Vector2(r.x-chamfer,r.y),Vector2(-r.x+chamfer,r.y),
  Vector2(-r.x,r.y-chamfer),Vector2(-r.x,-r.y+chamfer)]
 # Cap and returned bevel are actual wide surfaces, not decal slots.
 for i in range(poly.size()):
  var a:Vector2=at+poly[i]
  var b:Vector2=at+poly[(i+1)%poly.size()]
  var n:=Vector3((b-a).y,-(b-a).x,0.5).normalized()
  polygon(out,[Vector3(a.x,a.y,depth),Vector3(b.x,b.y,depth),Vector3(at.x,at.y,depth),Vector3(at.x,at.y,depth)],Vector3.BACK,tone)
  polygon(out,[Vector3(a.x,a.y,depth),Vector3(b.x,b.y,depth),
   Vector3(b.x,b.y,0),Vector3(a.x,a.y,0)],n,tone.darkened(0.13))

static func polygon(out:SurfaceTool,p:Array[Vector3],n:Vector3,tone:Color)->void:
 var single:=p[2].is_equal_approx(p[3])
 var order:=[0,1,2] if single else [0,1,2,0,2,3]
 if (p[1]-p[0]).cross(p[2]-p[0]).dot(n)>0.0:
  order=[0,2,1] if single else [0,2,1,0,3,2]
 for i in order:
  out.set_color(tone)
  out.set_normal(n)
  out.add_vertex(p[i])
