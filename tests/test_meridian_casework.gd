extends SceneTree
const Casework := preload("res://scripts/cabinet_assets.gd")
const Looks := preload("res://scripts/room_identity.gd")
class Stage extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var world := Stage.new()
 root.add_child(world)
 var unlike: Dictionary = {}
 var issues: Array[String] = []
 for side in [-1,1]:
  for lo in [840.0,1390.0]:
   var p := Vector3(side*410,0,lo+85)
   var old := Casework.service_counter(world,world,p,120,side)
   var look := Looks.service(side,lo)
   var changed := Casework.service_counter(world,world,p,120,side,look)
   var rack := changed.get_node("ProfiledCounterHutch") as MeshInstance3D
   var base := rack.get_aabb()
   var fingerprints := [rack.mesh.get_faces().size(),base]
   unlike[str(fingerprints)]=true
   if base.position.y>95.9 or base.end.y>196.1: issues.append("hutch must be seated on the physical worktop and stay in stock height")
   var thickness := changed.get_node("FormedCounterReveal") as MeshInstance3D
   if rack.get_child_count()!=1 or thickness.get_child_count()!=1: issues.append("decor exposed but not solid")
   if not pool_bounds(old).grow(0.6).encloses(pool_bounds(changed)): issues.append("counter footprint expanded: "+str(look.casework))
   if changed.get_meta("joinery")!=look.casework: issues.append("wrong role")
   old.queue_free()
   changed.queue_free()
 if unlike.size()!=4: issues.append("not four distinct actual counter silhouettes")
 if issues.is_empty(): print("PASS: four distinct measured counters, physically attached cabinet faces and hutches, original occupied volumes.")
 else:
  for issue in issues: push_error(issue)
 await process_frame
 world.queue_free()
 quit(0 if issues.is_empty() else 1)

func pool_bounds(n: Node3D) -> AABB:
 var acc := AABB()
 var found := false
 for m: Node in n.find_children("*","MeshInstance3D",true,false):
  var b: AABB = (n.global_transform.affine_inverse()*m.global_transform)*m.get_aabb()
  acc=b if not found else acc.merge(b)
  found=true
 return acc
