extends SceneTree
## Compare exact live sculpture footprints back against the unchanged built room.
const World := preload("res://scripts/world.gd")

func _initialize() -> void: call_deferred("run")
func run() -> void:
 var world := World.new()
 root.add_child(world)
 await physics_frame
 await physics_frame
 var space := world.get_world_3d().direct_space_state
 var issues: Array[String] = []
 var specs := [
  ["OrchidExhibitionStand",Vector3(-157,0,1892),12.73,12.73,126.0,Vector3(-109,103,1869)],
  ["PottingWorkBench",Vector3(151,0,1822),23.5,14.0,91.0,Vector3(109,91,1846)]
 ]
 for spec in specs:
  var node := world.get_node_or_null("CompartmentLayout/"+spec[0]) as Node3D
  if node==null or not node.global_position.is_equal_approx(spec[1]):
   issues.append("physical mount is not in its measured location")
   continue
  var exclude: Array[RID]=[]
  for child in node.find_children("*","StaticBody3D",true,false):
   exclude.append(child.get_rid())
  var body := BoxShape3D.new()
  body.size=Vector3(59,spec[4],38)
  var check := PhysicsShapeQueryParameters3D.new()
  check.shape=body
  check.exclude=exclude
  check.transform.origin=node.global_position+Vector3(0,body.size.y*0.5+2.55,0)
  check.margin=0.28
  var hits := space.intersect_shape(check,4)
  if not hits.is_empty(): issues.append("placed fixture conflicts: "+str(hits[0].collider.get_path()))
  for dx in [-float(spec[2]),float(spec[2])]:
   for dz in [-float(spec[3]),float(spec[3])]:
    var support_point: Vector3 = node.global_position+Vector3(dx,0,dz)
    var query := PhysicsRayQueryParameters3D.create(support_point+Vector3(0,2.2,0),support_point-Vector3(0,1.0,0))
    query.exclude=exclude
    var hit := space.intersect_ray(query)
    if hit.is_empty() or absf(hit.position.y-support_point.y)>0.025:
     issues.append("planted feet not in real floor plane: "+str(support_point))
  var radius := SphereShape3D.new()
  radius.radius=0.32
  var camera := PhysicsShapeQueryParameters3D.new()
  camera.shape=radius
  camera.transform.origin=spec[5]
  if not space.intersect_shape(camera,4).is_empty(): issues.append("art photo origin blocked near "+str(node.name))
 if world.hotspots.label.position!=Vector3(102,80,1905) or world.hotspots.orchid.position!=Vector3(-100,82,2020):
  issues.append("real case clues moved")
 if issues.is_empty(): print("PASS: both full garden fittings clear existing physical room, eight planted feet, original clue anchors and both camera origins clear.")
 else:
  for f in issues: push_error(f)
 world.queue_free()
 await process_frame
 quit(0 if issues.is_empty() else 1)
