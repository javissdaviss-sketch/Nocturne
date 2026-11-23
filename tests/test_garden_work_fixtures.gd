extends SceneTree
const Assets := preload("res://scripts/garden_purpose_assets.gd")
class Stage extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var world := Stage.new()
 root.add_child(world)
 var potting := Assets.build(world,world,Vector3(-120,0,0),false)
 var exhibition := Assets.build(world,world,Vector3(120,0,0),true)
 var problems: Array[String] = []
 for group in [potting,exhibition]:
  var field := AABB()
  var counts := 0
  for part: MeshInstance3D in group.get_children():
   var visible := part.mesh.get_aabb()
   field=visible if not field.has_surface() else field.merge(visible)
   counts+=part.mesh.get_faces().size()/3
   var actual := part.get_child(0).get_child(0) as CollisionShape3D
   if not actual.shape.backface_collision: problems.append("thin mesh is not a true two-sided contact")
   if part.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: problems.append("secondary prop adds a shadow pass")
  if not AABB(Vector3(-29.5,-0.03,-19),Vector3(59,126.03 if group==exhibition else 91.03,38)).encloses(field): problems.append("planned clear envelope exceeded: "+str(field))
  if absf(field.position.y)>0.02 or not counts in range(6000,56001): problems.append("not grounded or inappropriate geometry size: "+str(counts))
 var flowers: MeshInstance3D = exhibition.get_node("ExhibitCoralPetals")
 var bloom_bbox := flowers.mesh.get_aabb()
 if bloom_bbox.size.z<7.8 or flowers.mesh.get_faces().size()/3 not in range(2100,2501):
  problems.append("sculpted petals do not preserve intended dimensional depth and budget: "+str(bloom_bbox))
 await physics_frame
 await physics_frame
 var space := world.get_world_3d().direct_space_state
 var tray := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-108,82,0),Vector3(-108,68,0)))
 var stand := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(134,91,0),Vector3(134,81,0)))
 var aperture := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(120,56,-30),Vector3(120,56,30)))
 if tray.is_empty() or absf(tray.position.y-75.05)>0.07: problems.append("open potting tray doesn't retain actual working base")
 if stand.is_empty() or absf(stand.position.y-86.25)>0.07: problems.append("exhibit stand not an actual supportive surface")
 if not aperture.is_empty(): problems.append("ornamental frame has blocked its real open centre")
 if problems.is_empty(): print("PASS: distinct grounded potting tray and display, correct solid supports, true open curved frame and dimension budget.")
 else:
  for issue in problems: push_error(issue)
 world.queue_free()
 quit(0 if problems.is_empty() else 1)
