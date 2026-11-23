extends SceneTree
const Trace = preload("res://scripts/trace_notes.gd")
const SaveState = preload("res://scripts/case_state.gd")
var game: Node3D
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, text: String) -> void:
 if not value:
  failures.append(text)
  printerr("FAIL: ",text)
func frames() -> void:
 await physics_frame
 await process_frame
 await physics_frame
 await process_frame
func key(id: Key) -> void:
 var event := InputEventKey.new()
 event.keycode = id
 event.pressed = true
 game._unhandled_input(event)

func prepared_fly(at: Vector3,what: Vector3) -> void:
 game.resume_game()
 game.fly.active = false
 game.fly.restore_pending = false
 game.fly.reset_movement()
 game.fly.global_position = at
 game.fly.camera.global_position = at+Vector3(-3,2,-4)
 game.fly.camera.look_at(what)

func actual_button(text: String) -> Button:
 for node in game.modal.find_children("*","Button",true,false):
  if node.text.contains(text): return node
 return null

func compare_view(id: String) -> void:
 var mark: Dictionary = Trace.MACROS[id]
 var before: Transform3D = game.fly.camera.global_transform
 var position: Vector3 = game.fly.global_position
 var bytes := FileAccess.get_file_as_bytes(SaveState.PATH)
 var study := actual_button("Study the mark")
 check(study!=null,"Only legitimate normal E reveals the macro control for "+id)
 if study==null: return
 study.pressed.emit()
 check(game.mode=="trace_macro" and game.fly.inspection_eye_is_clear(),"Macro uses a real clear eye for "+id)
 var eye: Vector3 = game.fly.camera.get_camera_transform().origin
 var space := game.world.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
 var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye,mark.focus,1))
 check(eye.distance_to(mark.focus)<13.0 and (hit.is_empty() or hit.position.distance_to(mark.focus)<0.35),"Close focus ray reaches the actual mark instead of a wall or rim: "+id)
 check(game.fly.global_position==position and FileAccess.get_file_as_bytes(SaveState.PATH)==bytes,"Opening a new view neither moves the player nor saves: "+id)
 key(KEY_ESCAPE)
 check(game.mode=="inspection" and game.current_id==id and game.fly.camera.global_transform.is_equal_approx(before),"Back restores actual pre-study inspection pose for "+id)
 check(FileAccess.get_file_as_bytes(SaveState.PATH)==bytes,"Back does not replace field records or photos")

func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading": await game.investigation_ready
 game.start_game(true)
 var cup: Vector3 = game.world.hotspots.cup.position
 prepared_fly(Vector3(-88,95,1250),cup)
 await frames()
 check(game.nearest=="cup","Existing real cup finding remains accessible")
 key(KEY_E)
 check(game.mode=="inspection" and game.state.found.has("cup"),"Actual E finds the original cup")
 compare_view("cup")

 # A synthetically discovered bottle and logical flag must not show the
 # macro through a still-present door; then restore the unmodified real case.
 var before_fake: Array = game.state.found.duplicate()
 game.state.found.append("chemical")
 game.state.cabinet_open = true
 game.current_id = "chemical"
 game.show_trace_macro("chemical")
 check(game.mode=="inspection" and not game.trace_is_discovered("chemical"),"The closed physical cabinet defeats an artificial found ID and logical flag")
 game.state.found = before_fake
 game.state.cabinet_open = false
 var latch: Vector3 = game.world.hotspots.latch.position
 prepared_fly(Vector3(65,12,1460),latch)
 await frames()
 check(game.fly.move_and_collide(Vector3(37,0,0))==null,"The unchanged duct admits the real fly to the latch")
 game.fly.camera.global_position = Vector3(99,15,1458)
 game.fly.camera.look_at(latch)
 await frames()
 check(game.nearest=="latch","Reach and LOS route to the actual contact")
 key(KEY_E)
 var release := actual_button("BRIDGE THE CONTACT")
 check(release!=null,"Real E offers the actual mechanical release")
 if release!=null: release.pressed.emit()
 await frames()
 check(not game.world.cabinet_door.visible and game.state.cabinet_open,"Existing release both physically and logically opens the original cabinet")

 var bottle: Vector3 = game.world.hotspots.chemical.position
 prepared_fly(Vector3(101,50,1460),bottle)
 await frames()
 check(game.nearest=="chemical","Existing actual bottle remains accessible after the real unlock")
 key(KEY_E)
 if game.current_id=="chemical" and game.mode=="inspection": compare_view("chemical")
 else: check(false,"Existing E did not lead to original bottle")
 game.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: actual E and original latch gate, physically clear cup/bottle macro, unchanged saved state and view return")
 quit(0 if failures.is_empty() else 1)
