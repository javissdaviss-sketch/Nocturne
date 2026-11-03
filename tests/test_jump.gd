extends SceneTree
const Fly = preload("res://scripts/fly.gd")
var failures: Array[String] = []
var fly: CharacterBody3D
func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)
func _initialize() -> void:
 call_deferred("run")
func space(pressed: bool, echo: bool = false) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = KEY_SPACE
 event.keycode = KEY_SPACE
 event.pressed = pressed
 event.echo = echo
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func tap() -> void:
 space(true)
 space(false)
func frames(count: int) -> void:
 for _i in range(count):
  await physics_frame
  await process_frame
func perch() -> void:
 space(false)
 fly.inspection = false
 fly.active = true
 fly.reset_movement()
 fly.position = Vector3(0,6,200)
 check(fly.try_land(),"Test perch is reachable")
 await frames(2)
func run() -> void:
 var floor_body := StaticBody3D.new()
 var shape := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3(40,2,40)
 shape.shape = box
 floor_body.add_child(shape)
 root.add_child(floor_body)
 floor_body.position = Vector3(0,-1,200)
 fly = Fly.new()
 root.add_child(fly)
 fly.active = false
 await frames(2)
 await perch()
 var start_height: float = fly.position.y
 tap()
 check(fly.jumping and not fly.landed,"First Space tap starts a jump")
 await frames(6)
 check(fly.position.y>start_height+0.5,"Jump physically rises off the surface")
 check(fly.jumping and is_equal_approx(fly.wing_l.rotation.z,0.1),"A jump keeps wings at rest")
 await frames(35)
 check(fly.landed and not fly.jumping,"A single tap lands back on the surface")
 check(absf(fly.position.y-start_height)<0.15,"Jump returns to the original surface")

 await perch()
 space(true)
 await frames(5)
 space(true,true)
 check(fly.jumping,"Keyboard repeat does not count as a second tap")
 await frames(35)
 check(fly.landed and not fly.jumping,"Holding Space does not auto-takeoff or repeatedly jump")
 space(false)

 await perch()
 tap()
 await frames(4)
 tap()
 check(not fly.landed and not fly.jumping,"Second quick tap starts free flight")
 check(fly.space_tap_remaining==0.0,"Takeoff consumes the tap window")
 await frames(30)
 check(not fly.landed and not fly.jumping,"Double-tap remains in free flight")
 var flight_height: float = fly.position.y
 space(true)
 await frames(6)
 space(false)
 check(fly.position.y>flight_height+0.5,"Holding Space still ascends during free flight")

 await perch()
 tap()
 await frames(21)
 check(fly.jumping and fly.space_tap_remaining==0.0,"Double-tap window expires during the jump")
 tap()
 check(fly.jumping,"A late tap cannot trigger takeoff")
 await frames(12)
 check(fly.landed,"A late second tap still lands normally")
 tap()
 check(fly.jumping,"A subsequent landed tap starts a fresh jump")

 await perch()
 var ceiling := StaticBody3D.new()
 var ceiling_shape := CollisionShape3D.new()
 var ceiling_box := BoxShape3D.new()
 ceiling_box.size = Vector3(6,0.5,6)
 ceiling_shape.shape = ceiling_box
 ceiling.add_child(ceiling_shape)
 root.add_child(ceiling)
 ceiling.position = Vector3(0,1.25,200)
 await frames(2)
 tap()
 await frames(12)
 check(fly.landed and fly.space_tap_remaining>0.0,"A low ceiling can shorten a jump without losing the second-tap window")
 tap()
 check(not fly.jumping and not fly.landed,"Double-tap still takes off after a ceiling-blocked jump")
 ceiling.queue_free()
 await frames(1)

 await perch()
 fly.active = false
 tap()
 check(fly.landed and not fly.jumping,"Space while paused cannot jump")
 fly.active = true
 fly.inspection = true
 tap()
 check(fly.landed and not fly.jumping,"Space while inspecting cannot jump")
 fly.inspection = false
 check(fly.try_land() and not fly.landed and not fly.jumping,"Explicit takeoff shortcut still works")
 space(false)
 fly.queue_free()
 floor_body.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: single-tap jump and landing, hold/repeat rejection, double-tap flight, timeout, ascent, pause, inspection, explicit takeoff")
 quit(0 if failures.is_empty() else 1)
