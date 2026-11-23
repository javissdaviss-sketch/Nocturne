extends SceneTree
const Joinery := preload("res://scripts/profiled_interior.gd")
func _initialize() -> void: call_deferred("run")

func run() -> void:
 var profiles := Joinery.new()
 root.add_child(profiles)
 var faults: Array[String]=[]
 for car in range(3):
  var z:=500.0+car*810.0
  for side in [-1,1]:
   profiles.backing(side,side*52.0,z,60,car)
   profiles.dado(side,side*52.0,45.0,z,40,car)
 profiles.finish()
 var budget: Dictionary=profiles.get_meta("profile_budget")
 if budget.surfaces!=12 or budget.triangles>2800: faults.append("three sets of batching should remain bounded, not full rooms multiplied")
 await physics_frame
 await physics_frame
 var space:=profiles.get_world_3d().direct_space_state
 for car in range(3):
  var z:=500.0+car*810.0
  for side in [-1,1]:
   var middle:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,45,z),Vector3(side*54.0,45,z)))
   var far:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,45,z-29),Vector3(side*54.0,45,z-29)))
   var high:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,104,z),Vector3(side*54.0,104,z)))
   if middle.is_empty() or absf(absf(middle.position.x)-(51.22 if car==2 else 50.93))>0.05:
    faults.append("distinct physical inset not found for "+str(car))
   if far.is_empty() or absf(absf(far.position.x)-51.55)>0.04 or not high.is_empty(): faults.append("backing reaches into a protected room shoulder")
 var keys: Array = profiles.banks.keys()
 for group in ["Sleeper:field","Garden:field","field"]:
  if not keys.has(group): faults.append("material and shape family missing")
 if faults.is_empty(): print("PASS: three distinct actual panel profiles, physical recessed centres and exact backing, no higher aisle intrusion, ",budget.triangles," sample triangles in 12 groups.")
 else:
  for issue in faults: push_error(issue)
 profiles.queue_free()
 quit(0 if faults.is_empty() else 1)
