extends SceneTree
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)
func _initialize() -> void:
 call_deferred("run")
func motion() -> void:
 var e := InputEventMouseMotion.new()
 e.position = Vector2(640,400)
 e.global_position = e.position
 e.relative = Vector2(40,20)
 Input.parse_input_event(e)
func click(index: MouseButton, pressed: bool = true) -> void:
 var e := InputEventMouseButton.new()
 e.position = Vector2(640,400)
 e.global_position = e.position
 e.button_index = index
 e.pressed = pressed
 Input.parse_input_event(e)
func run() -> void:
 if DisplayServer.get_name()=="headless":
  printerr("Mouse regression requires a real display. Use xvfb-run -a godot --audio-driver Dummy --script res://tests/test_mouse.gd")
  quit(2)
  return
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_game(true)
 await process_frame
 # Reproduce the original problem: a full-screen GUI control consumes mouse events.
 # Gameplay input must still receive motion before GUI event handling.
 var blocker := Control.new()
 blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 blocker.mouse_filter = Control.MOUSE_FILTER_STOP
 game.ui.add_child(blocker)
 await process_frame
 var yaw_before: float = game.fly.yaw
 var pitch_before: float = game.fly.pitch
 motion()
 await process_frame
 check(not is_equal_approx(game.fly.yaw,yaw_before),"Mouse changes yaw through a full-screen HUD")
 check(not is_equal_approx(game.fly.pitch,pitch_before),"Mouse changes pitch through a full-screen HUD")
 var zoom_before: float = game.fly.distance
 click(MOUSE_BUTTON_WHEEL_UP)
 await process_frame
 check(game.fly.distance<zoom_before,"Wheel changes camera distance through the HUD")
 game.show_pause()
 yaw_before = game.fly.yaw
 motion()
 await process_frame
 check(is_equal_approx(game.fly.yaw,yaw_before),"Pause prevents mouse look")
 game.resume_game()
 yaw_before = game.fly.yaw
 motion()
 await process_frame
 check(not is_equal_approx(game.fly.yaw,yaw_before),"Resume restores mouse look")
 game.show_inspection("cup")
 var orbit_before: float = game.fly.inspect_yaw
 motion()
 await process_frame
 check(is_equal_approx(game.fly.inspect_yaw,orbit_before),"Inspection leaves the cursor free until right-drag")
 click(MOUSE_BUTTON_RIGHT)
 motion()
 await process_frame
 check(not is_equal_approx(game.fly.inspect_yaw,orbit_before),"Right-drag orbits the inspected prop")
 click(MOUSE_BUTTON_RIGHT,false)
 await process_frame
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"Releasing right mouse restores the inspection cursor")
 blocker.queue_free()
 if failures.is_empty(): print("PASS: mouse look and zoom through GUI, pause/resume, inspection right-drag and release")
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
