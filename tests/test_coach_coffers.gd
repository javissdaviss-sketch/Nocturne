extends SceneTree
const Coffer:=preload("res://scripts/coach_coffers.gd")
class Stage extends "res://scripts/world.gd":
 func _ready()->void: pass
func _initialize()->void: call_deferred("run")
func run()->void:
 var base:=Stage.new()
 root.add_child(base)
 var faults:Array[String]=[]
 var counts:=[]
 var model:=[]
 for car in range(3):
  var target:=Coffer.install(base,base,car)
  model.append(target)
  var triangles:=0
  for form:MeshInstance3D in target.get_children():
   if not AABB(Vector3(-33.5,0.5,-23.1),Vector3(67,12.8,46.2)).encloses(form.get_aabb()): faults.append("runs outside the protected ceiling bay: "+str(form.get_aabb()))
   if form.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF or form.get_child_count()!=1: faults.append("no new shadow light/pass or loose geometry")
   triangles += form.mesh.get_faces().size()/3
  if triangles<80 or triangles>1900: faults.append("unexpected decoration density: "+str(triangles))
  counts.append(triangles)
 if counts[0]==counts[1] or counts[1]==counts[2] or counts[0]==counts[2]: faults.append("coffers need three different physical forms")
 await physics_frame
 await physics_frame
 var space:=base.get_world_3d().direct_space_state
 for car in range(3):
  var deck:Node3D=model[car]
  var x:=16.0 if car==0 else 0.0
  var under:=space.intersect_ray(PhysicsRayQueryParameters3D.create(deck.to_global(Vector3(x,-4,0)),deck.to_global(Vector3(x,0,0))))
  var above:=space.intersect_ray(PhysicsRayQueryParameters3D.create(deck.to_global(Vector3(x,0,0)),deck.to_global(Vector3(x,15,0))))
  if not under.is_empty() or above.is_empty(): faults.append("ceiling bay isn't physically seated or lower fly clearance changed")
 if faults.is_empty(): print("PASS: three bounded physical ceiling signatures, no casting, lower flight volume preserved; triangles ",counts)
 else:
  for issue in faults: push_error(issue)
 quit(0 if faults.is_empty() else 1)
