extends SceneTree
const Sleep:=preload("res://scripts/sleeping_assets.gd")
class Isolated extends "res://scripts/world.gd":
 func _ready()->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var w:=Isolated.new()
 root.add_child(w)
 var roles:=["fan","bolster","round","stepped"]
 var errors:Array[String]=[]
 var old:=Sleep.blanket_mesh("classic")
 var permitted:=old.get_aabb().grow(0.8)
 var fits:Dictionary={}
 var beds:Dictionary={}
 for i in range(roles.size()):
  var role:String=roles[i]
  var bed:=Sleep.build_bed(w,w,Vector3(i*162.0,0,0),{"outline":role})
  beds[role]=bed
  var blanket:=bed.get_node("FittedBlanket") as MeshInstance3D
  var top:=bed.get_node("FoldedTopSheet") as MeshInstance3D
  var runner:Node=bed.get_node_or_null("LooseBedThrow")
  var range_box:=blanket.get_aabb()
  fits[str(range_box)]=true
  if not permitted.encloses(range_box):
   errors.append(role+": blanket went outside prior tested bed volume "+str(range_box))
  if bed.find_children("PlacedSleeperPillow*","MeshInstance3D",false,false).size()!=[2,1,2,1][i]:
   errors.append(role+": wrong grounded pillow arrangement")
  if (runner!=null)!=Sleep.has_runner(role):
   errors.append(role+": inappropriate loose throw")
  if blanket.mesh.get_faces().size()>old.get_faces().size() or top.mesh.get_faces().size()==0:
   errors.append(role+": cloth complexity or folded geometry invalid")
  for point:Vector3 in blanket.mesh.get_faces():
   if point.y<Sleep.mattress_top_at(point.x,point.z)+0.31:
    errors.append(role+": cloth physically intersects mattress")
    break
  blanket.create_trimesh_collision()
 if fits.size()!=4:errors.append("not four measured profile shapes")
 await physics_frame
 await physics_frame
 var space:=w.get_world_3d().direct_space_state
 for role in roles:
  var bed:Node3D=beds[role]
  for spot in [Vector2(0,0),Vector2(24,57),Vector2(-24,30),Vector2(59,15)]:
   var start:=bed.to_global(Vector3(spot.x,78.2,spot.y))
   var result:=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,start-Vector3.UP*21,1))
   if result.is_empty() or result.position.y<61.31 or result.position.y>66.3:
    errors.append(role+": actual draped support test missed/inconsistent "+str(spot))
 print("Bedding shapes issues=",errors)
 w.queue_free()
 quit(0 if errors.is_empty() else 1)
