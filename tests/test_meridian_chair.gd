extends SceneTree
## A local chair pair with the production generator and real mesh physics.
class SeatStage extends "res://scripts/world.gd":
 func _ready() -> void:
  pass

func _initialize() -> void:
 call_deferred("check")

func check() -> void:
 var world := SeatStage.new()
 root.add_child(world)
 var control := world.seat(Vector3(-90,0,0))
 var chair := world.seat(Vector3.ZERO,Color("5b3948"),"meridian")
 var shell := chair.get_node("MeridianBookmatchedShell") as MeshInstance3D
 var pad := chair.get_node("MeridianCrownedShoulder") as MeshInstance3D
 var cord := chair.get_node("MeridianInsetWelt") as MeshInstance3D
 var control_bounds := bounds(control)
 var sculpted_bounds := bounds(chair)
 var tolerance := 0.12
 var permitted := control_bounds.grow(tolerance)
 var issues: Array[String] = []
 if not permitted.encloses(sculpted_bounds): issues.append("new chair exceeded original silhouette: %s > %s" % [sculpted_bounds,control_bounds])
 var nominal := triangles(shell.mesh)+triangles(pad.mesh)+triangles(cord.mesh)
 if nominal < 1000 or nominal > 2200: issues.append("silhouette triangle budget %d" % nominal)
 if cord.mesh.get_aabb().size.x < 48 or cord.mesh.get_aabb().size.y < 46: issues.append("piping has not followed full pad perimeter")
 await physics_frame
 await physics_frame
 var space := world.get_world_3d().direct_space_state
 var front := ray(space,Vector3(0,68,5),Vector3(0,68,37))
 var rear := ray(space,Vector3(0,68,39),Vector3(0,68,18))
 var shoulder := ray(space,Vector3(-31,89,8),Vector3(-31,89,39))
 if front.is_empty() or front.collider.get_parent() != pad: issues.append("front upholstery not physically solid")
 if rear.is_empty() or rear.collider.get_parent() != shell: issues.append("back shell not physically solid")
 if not shoulder.is_empty(): issues.append("pulled-in shoulder remains invisibly solid")
 if issues.is_empty():
  print("PASS: shaped, physically matching chair within original AABB; geometry triangles ",nominal,", real two-side contacts and clear shoulder.")
 else:
  for issue in issues: push_error(issue)
 world.queue_free()
 quit(0 if issues.is_empty() else 1)

func ray(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> Dictionary:
 return space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b))

func bounds(parent: Node3D) -> AABB:
 var answer := AABB()
 var first := true
 for child in parent.get_children():
  if child is MeshInstance3D:
   var child_bounds: AABB = child.transform*child.get_aabb()
   answer = child_bounds if first else answer.merge(child_bounds)
   first = false
 return answer

func triangles(mesh: Mesh) -> int:
 return mesh.get_faces().size()/3
