extends SceneTree
const Fly = preload("res://scripts/fly.gd")
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, text: String) -> void:
 if not value: failures.append(text)

func block(parent: Node3D, position: Vector3, size: Vector3) -> void:
 var body := StaticBody3D.new()
 parent.add_child(body)
 body.position = position
 var collider := CollisionShape3D.new()
 var mesh := BoxShape3D.new()
 mesh.size = size
 collider.shape = mesh
 body.add_child(collider)

func run() -> void:
 var fixture := Node3D.new()
 root.add_child(fixture)
 var focus := Vector3(0,20,20)
 var zoom := 8.0
 var pitch := 0.27
 var up := Vector3(0,zoom*sin(pitch),0)
 var horizontal := zoom*cos(pitch)
 var geometric_front := focus+up+Vector3(0,0,-horizontal)
 var offset_rear := focus+up+Vector3(2,0,horizontal)
 block(fixture,focus,Vector3.ONE)
 block(fixture,geometric_front,Vector3.ONE*1.4)
 block(fixture,offset_rear,Vector3.ONE*1.4)
 var fly := Fly.new()
 fixture.add_child(fly)
 fly.active = false
 fly.set_physics_process(false)
 await physics_frame
 await physics_frame
 var origin := fly.global_position
 fly.inspect_at(focus,zoom)
 fly.camera.h_offset = 0
 fly.inspect_pitch = pitch
 fly.inspect_yaw = 0
 fly.update_camera(0)
 var initial := fly.camera.global_transform
 var actual_rear := focus+up+Vector3(0,0,horizontal)
 check(fly.camera.global_position.is_equal_approx(actual_rear) and fly.inspection_eye_is_clear(),"Free orbit remains literal even if the inspected object is on the focus ray")
 fly.inspect_yaw = PI
 fly.update_camera(0)
 check(fly.camera.global_transform.is_equal_approx(initial),"A request through solid furniture keeps the prior valid view")
 fly.inspect_yaw = PI/2
 fly.update_camera(0)
 var side := focus+up+Vector3(horizontal,0,0)
 check(fly.camera.global_position.is_equal_approx(side) and fly.inspection_eye_is_clear(),"Orbit can continue freely around the obstruction")
 fly.inspect_at(focus,zoom)
 fly.inspect_pitch = pitch
 fly.camera.h_offset = 2.0
 fly.inspect_yaw = PI/2
 fly.update_camera(0)
 var prior := fly.camera.global_transform
 fly.inspect_yaw = 0
 fly.update_camera(0)
 check(fly.camera.global_transform.is_equal_approx(prior) and fly.inspection_eye_is_clear(),"Lens offset is included, even if the unshifted camera base was clear")
 check(fly.global_position==origin,"Inspection never moves the fly")
 fixture.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: free orbit, physical overlap fallback, optical offset, and stationary fly")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
