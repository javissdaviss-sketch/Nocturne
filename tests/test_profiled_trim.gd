extends SceneTree
const Profile = preload("res://scripts/profiled_interior.gd")
const Layout = preload("res://scripts/train_layout.gd")
const World = preload("res://scripts/world.gd")
var issues: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool,what: String) -> void:
 if not ok: issues.append(what)

func run() -> void:
 var profile := Profile.new()
 root.add_child(profile)
 for side in [-1,1]:
  profile.backing(side,side*52.0,1130,75)
  profile.dado(side,side*52.0,45,1130,42)
  profile.pilaster(side,1164)
  profile.parked_leaf(side,1215)
 profile.finish()
 var budget: Dictionary = profile.get_meta("profile_budget")
 check(budget.triangles>1000 and budget.triangles<1600 and budget.surfaces==5,"Actual rounded profiles remain batch-bounded")
 for node in profile.get_children():
  if node is MeshInstance3D:
   var shape := node.get_child(0).get_child(0) as CollisionShape3D
   check(shape.shape is ConcavePolygonShape3D and shape.shape.backface_collision,"Physical contact uses the very same drawn shape")
   check(node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,"High-frequency trim does not add costly shadow passes")
 var world_builder := World.new()
 var doorway := Layout.new()
 root.add_child(doorway)
 var extent := Vector3(9,224,3)
 doorway.portal_trim(world_builder,1,Vector3(-55,112,1100),extent)
 var arch := doorway.get_node("RoundedMeridianArchitrave") as MeshInstance3D
 check(arch.mesh.get_aabb().size.is_equal_approx(extent),"Rounded jamb stays in the original footprint")
 check(arch.mesh.surface_get_array_len(0)>36,"Jamb is actual new geometry, not a surface tint")
 await physics_frame
 await physics_frame
 var space := profile.get_world_3d().direct_space_state
 for side in [-1,1]:
  var rail_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,13.5,1130),Vector3(side*54,13.5,1130),1))
  check(not rail_hit.is_empty() and absf(rail_hit.position.x)>49.5 and absf(rail_hit.position.x)<50.15,"The profile's projecting trim is actually contactable")
  var cavity_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,45,1130),Vector3(side*54,45,1130),1))
  check(not cavity_hit.is_empty() and absf(absf(cavity_hit.position.x)-50.93)<0.04,"Recessed centre is a real face 1.36cm behind the bead")
  var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,47,1105),Vector3(side*54,47,1105),1))
  check(not ground.is_empty() and absf(absf(ground.position.x)-51.55)<0.04,"Visible continuous backing remains solid")
  var rail_end := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,100,1164),Vector3(side*52,100,1164),1))
  check(not rail_end.is_empty() and absf(absf(rail_end.position.x)-48.18)<0.08,"The brass beaded face sits within old corridor depth")
 print("PROFILED_MESH ",JSON.stringify(budget)," issues=",issues)
 world_builder.free()
 doorway.queue_free()
 profile.queue_free()
 await process_frame
 quit(0 if issues.is_empty() else 1)
