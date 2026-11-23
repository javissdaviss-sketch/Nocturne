extends SceneTree
const Lift = preload("res://scripts/seed_lift.gd")
const Fly = preload("res://scripts/fly.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
 if not ok: failures.append(why)

func run() -> void:
 var owner: Node3D
 var lift: Node3D
 var full_world := "--world" in OS.get_cmdline_user_args()
 if full_world:
  var World = load("res://scripts/world.gd")
  owner = World.new()
  root.add_child(owner)
  lift = owner.seed_lift
 else:
  owner = Node3D.new()
  root.add_child(owner)
  lift = Lift.new()
  owner.add_child(lift)
  lift.build()
 var fly := Fly.new()
 owner.add_child(fly)
 fly.active = false
 fly.set_physics_process(false)
 await physics_frame
 await physics_frame
 var points: Array[Vector3] = []
 for local in Lift.INTAKE_PATH: points.append(lift.to_global(local))
 fly.global_position = points[0]
 check(fly.position_is_clear(points[0]),"The entrance approach is clear of existing garden props")
 for destination in points.slice(1):
  var hit := fly.move_and_collide(destination-fly.global_position)
  check(hit==null and fly.global_position.distance_to(destination)<0.08,"The real fly can traverse the physical inward turn at "+str(destination))
 var mid := points[-1]
 check(fly.try_land() and fly.landed and fly.global_position.y < mid.y,"The actual fly sweep can land level on the balance spoon")
 var space := owner.get_world_3d().direct_space_state
 var floor_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(fly.global_position,fly.global_position+Vector3.DOWN*0.45,1))
 check(not floor_hit.is_empty() and floor_hit.get("collider")==lift.spoon_body,"Landing support is the real named spoon, not the shell")
 fly.take_off()
 # Automatic take-off does not have to place the user in an exact pole. Every
 # way back starts from above the spoon and follows the same open two turns.
 var supported := fly.move_and_collide(points[-1]-fly.global_position)
 check(supported==null,"The fly can rise away from the spoon")
 var back := points.duplicate()
 back.reverse()
 for destination in back.slice(1):
  var reverse_hit := fly.move_and_collide(destination-fly.global_position)
  check(reverse_hit==null and fly.global_position.distance_to(destination)<0.08,"The real return path stays open at "+str(destination))
 fly.global_position = points[0]
 check(fly.move_and_collide(points[-1]-points[0],true)!=null,"A straight shortcut must hit the lower baffle")
 fly.global_position = lift.to_global(Vector3(0,6,-33))
 check(fly.move_and_collide(Vector3(0,0,22),true)!=null,"Glass is physically solid, not a shortcut")
 var broad_probe := SphereShape3D.new()
 broad_probe.radius = 3.2
 var probe := PhysicsShapeQueryParameters3D.new()
 probe.shape = broad_probe
 probe.transform.origin = points[0]
 probe.motion = points[1]-points[0]
 probe.collision_mask = 1
 var safe := space.cast_motion(probe)
 check(safe[0]<0.92,"A radius 3.2 cm probe cannot enter the real 6 cm lower opening")
 if full_world:
  var own_bodies:Array[RID]=[]
  for body:StaticBody3D in lift.find_children("*","StaticBody3D",true,false):
   own_bodies.append(body.get_rid())
  for strap_id in ["LeftWallStrap","RightWallStrap"]:
   var strap:MeshInstance3D=lift.get_node_or_null(strap_id) as MeshInstance3D
   if not is_instance_valid(strap):
    check(false,"Both actual wall contact straps must exist")
    continue
   var shape:=strap.get_child(0).get_child(0) as CollisionShape3D
   var block:=shape.shape as BoxShape3D
   if not is_instance_valid(block):
    check(false,"Missing exact strap contact shape")
    continue
   var center:=shape.global_position
   var target:=PhysicsRayQueryParameters3D.create(center-Vector3.BACK*0.25,center+Vector3.BACK*8,1,own_bodies)
   target.hit_back_faces=true
   var wall:=space.intersect_ray(target)
   if wall.is_empty():
    check(false,"No contact wall beyond the fitted strap")
    continue
   var gap:float=wall.position.z-(center.z+block.size.z*0.5)
   check(gap<=0.002 and gap>=-0.12,"Rear strap should seat into liner by under 1.2mm, not float or overrun")
   check(is_equal_approx(center.z-block.size.z*0.5,lift.global_position.z-0.20),"Front/case envelope moved")
   print("Mounted ",strap_id," signed face gap (cm)=",gap)
 owner.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: physical two-turn in/out and spoon, no shortcut through baffles or glass, wide probe blocked; actual_world=",full_world)
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
