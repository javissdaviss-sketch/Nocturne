extends SceneTree
const Fascias := preload("res://scripts/vestibule_fascias.gd")
class Stage extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var world := Stage.new()
 root.add_child(world)
 Fascias.dress(world,795.3,false,false)
 Fascias.dress(world,844.7,false,true,0.24)
 Fascias.dress(world,1635.3,true,false)
 Fascias.dress(world,1684.7,true,true)
 var issue: Array[String] = []
 var triangle_total := 0
 for form: Node3D in world.get_children():
  if form.get_child_count()!=2: issue.append("incorrect draw groups")
  for item: MeshInstance3D in form.get_children():
   var mesh := item.mesh
   triangle_total += mesh.get_faces().size()/3
   if mesh.get_aabb().size.z>8.4: issue.append("projecting fascia too deep")
   if item.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: issue.append("detail creates shadow passes")
 await physics_frame
 await physics_frame
 var space := world.get_world_3d().direct_space_state
 for zz in [800,1640]:
  for y in [5.0,25.0,115.0,200.0,218.0,221.0]:
   for x in [-53.0,-36.0,0.0,36.0,53.0]:
    if not trace(space,Vector3(x,y,zz-50),Vector3(x,y,zz+50)).is_empty(): issue.append("profile blocked true opening %s" % Vector3(x,y,zz))
  if trace(space,Vector3(60,116,zz-30),Vector3(60,116,zz+8)).is_empty(): issue.append("new jamb has no actual contact")
  if trace(space,Vector3(60,116,zz+70),Vector3(60,116,zz+20)).is_empty(): issue.append("rear jamb has no actual contact")
 # The nearby 07 reception portal begins at z847. Model, not just
 # physics, must clear this volume when both mirrored room doors are used.
 for x in [-1,1]:
  for z in [847.0,847.35,848.0,850.5]:
   for y in [7.0,14.0,55.0,110.0,160.0]:
    if not trace(space,Vector3(x*47,y,z),Vector3(x*71,y,z)).is_empty(): issue.append("rear fascia interferes with reception at %s" % Vector3(x,y,z))
 if triangle_total>3900: issue.append("Excessive ornamental mesh budget")
 if issue.is_empty():
  print("PASS: two distinct dressed vestibules, 100 clear through and reception edge rays, real fronts and backs, %d nonshadowed triangles."%triangle_total)
 else:
  for f in issue: push_error(f)
 world.queue_free()
 quit(0 if issue.is_empty() else 1)

func trace(space:PhysicsDirectSpaceState3D,from:Vector3,to:Vector3)->Dictionary:
 return space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to))
