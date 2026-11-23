extends SceneTree
const Decor:=preload("res://scripts/railside_hotel_relief.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var templ:=Decor.make_records()
 var failing:=[]
 var y0:=INF
 var y1:=-INF
 var x0:=INF
 var x1:=-INF
 var tones:={}
 for point in templ:
  var p:Vector3=point.p
  tones[point.c]=true
  if absf(p.x)<124.0 and absf(p.y)<43.0:
   failing.append("surround enters area physically occupied by existing sign")
  y0=minf(y0,p.y)
  y1=maxf(y1,p.y)
  x0=minf(x0,p.x)
  x1=maxf(x1,p.x)
 if tones.size()<6 or x1-x0<290 or y1-y0<165 or templ.size()/3>560:
  failing.append("decorative relief shape/range budget invalid")
 var mesh:=SurfaceTool.new()
 mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
 for side in [-1,1]:
  Decor.append_batch(mesh,side,Vector3(side*1168.0,162.0,785.0))
 var actual:=mesh.commit()
 var verts:PackedVector3Array=actual.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 for v in verts:
  if absf(v.x)<1158.0 or v.z<614 or v.z>956 or v.y<82 or v.y>277:
   failing.append("scene relief leaves actual track-side mounting envelope")
 if failing.is_empty():print("PASS: kept left and right neon faces unobscured, distant true layered stone, per-lot ",templ.size()/3," triangles.")
 else:
  for item in failing:push_error(item)
 quit(0 if failing.is_empty() else 1)
