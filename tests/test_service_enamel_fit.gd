extends SceneTree
const World=preload("res://scripts/world.gd")
const Enamel=preload("res://scripts/service_enamel_fit.gd")
const Trace=preload("res://scripts/trace_notes.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var failures:Array[String]=[]
 var shelf:=Enamel.pressed_tray()
 var a:=shelf.get_aabb()
 if not a.position.is_equal_approx(Vector3(83.5,33.5,1411.5)) or not a.end.is_equal_approx(Vector3(160.5,36.5,1540.5)):
  failures.append("Original closed shelf envelope was not retained")
 if shelf.get_surface_count()!=2 or shelf.surface_get_material(0)==null or shelf.surface_get_material(1)==null:
  failures.append("Rolled edge is not physically split from shelf finish")
 if OS.get_cmdline_user_args().has("--component-only"):
  print("Service lining component issues=",failures)
  quit(0 if failures.is_empty() else 1)
  return
 var world:=World.new()
 root.add_child(world)
 await physics_frame
 await physics_frame
 var space:=world.get_world_3d().direct_space_state
 var fitted:=world.get_node_or_null("StationaryCupboardLining") as Node3D
 if not is_instance_valid(fitted) or fitted.find_children("*","Light3D",true,false).size()!=0:
  failures.append("Missing art or added scene light")
  quit(2);return
 # Keep actual shelf at the exact existing physical support level alongside
 # the evidence, and do not touch the authored original evidence anchor.
 var body:=world.find_child("EvidenceBottleGlass",true,false) as MeshInstance3D
 if not is_instance_valid(body) or not body.global_position.is_equal_approx(Vector3(121,36.5,1460)):
  failures.append("Original bottle geometry was shifted")
 for x in [113,129,151]:
  var support:=PhysicsRayQueryParameters3D.create(Vector3(x,38,1460),Vector3(x,35.9,1460),1)
  var contact:=space.intersect_ray(support)
  if contact.is_empty() or not fitted.is_ancestor_of(contact.collider) or absf(contact.position.y-36.5)>0.025:
   failures.append("Original flat load-bearing level missing at "+str(x))
 var sphere:=SphereShape3D.new()
 sphere.radius=0.16
 var sweep:=PhysicsShapeQueryParameters3D.new()
 sweep.shape=sphere
 sweep.collision_mask=1
 sweep.transform.origin=Vector3(65,12,1460)
 sweep.motion=Vector3(37,0,0)
 if space.cast_motion(sweep)[0]<0.999 or not world.cabinet_door.visible:
  failures.append("Original real under-door crawl or closed door was modified")
 # Known ordinary and macro lenses retain clear original physical content
 # once the actual original door opens. No material can act as a clue/guard.
 world.unlock_cabinet()
 await physics_frame
 await physics_frame
 var shape:=SphereShape3D.new()
 shape.radius=0.15
 var eye_check:=PhysicsShapeQueryParameters3D.new()
 eye_check.shape=shape
 eye_check.collision_mask=1
 var lenses:Dictionary=Trace.MACROS["chemical"]
 for original:Vector3 in lenses.eyes:
  eye_check.transform.origin=original
  if not space.intersect_shape(eye_check,1).is_empty():failures.append("Macro lens blocked at "+str(original))
 print("Service enamel actual cabinet issues=",failures," support y=36.5; native appearance separate")
 world.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
