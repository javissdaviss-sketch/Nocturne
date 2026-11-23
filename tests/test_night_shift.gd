extends SceneTree
## Run with isolated user data. Exercise real fly sweeps, E, and test-pulse buttons.
const Data = preload("res://scripts/case_data.gd")
const State = preload("res://scripts/case_state.gd")
var game: Node3D
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)

func frames(count: int) -> void:
 for step in range(count):
  await physics_frame
  await process_frame

func position_for_inspection(point: Vector3, target: Vector3) -> void:
 game.fly.active = false
 game.fly.inspection = false
 game.fly.restore_pending = false
 game.fly.position = point
 game.fly.velocity = Vector3.ZERO
 var away := (point-target).normalized()
 game.fly.camera.position = point+away*3+Vector3(0,1,0)
 game.fly.camera.look_at(target)

func press_e() -> void:
 var inspect := InputEventKey.new()
 inspect.pressed = true
 inspect.keycode = KEY_E
 game._unhandled_input(inspect)

func light_on() -> bool:
 return game.world.night_task_diffuser.get_meta("nursery_task_light_on",false) == true

func front_camera(control: String, point: Vector3) -> void:
 var eye: Vector3 = game.fly.camera.get_camera_transform().origin
 var front := eye.x<point.x-1.0 if control=="night_relay" else eye.z<point.z-1.0
 var space := game.world.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
 var collision := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye,point,1))
 check(front and (collision.is_empty() or collision.position.distance_to(point)<1.1),"Actual optical camera starts at the unobstructed front face: "+control)

func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading": await game.investigation_ready
 game.start_game(true)
 var intact_world: int = game.world.get_instance_id()
 var lights_before: int = game.world.find_children("*","Light3D",true,false).size()
 var collision_before: Dictionary = game.world.collision_stats.duplicate()
 check(not light_on() and not game.state.nursery_diagnosed,"Initial task light and diagnostic status are off")
 var relay := Data.NIGHT_RELAY_POINT
 var sensor := Data.NURSERY_SENSOR_POINT
 position_for_inspection(Vector3(132,85,292.5),relay)
 await frames(2)
 check(game.nearest!="night_relay" and not game.interaction_is_current("night_relay"),"Radio cannot be used through its rear")
 var space := game.world.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
 var rear_radio := space.intersect_ray(PhysicsRayQueryParameters3D.create(game.fly.position,relay,1))
 check(not rear_radio.is_empty(),"The original radio body blocks a rear sight line")
 position_for_inspection(Vector3(98,86,292.5),relay)
 await frames(2)
 check(not game.interaction_is_current("night_relay"),"The radio remains out of fly reach from further away")
 var flight: KinematicCollision3D = game.fly.move_and_collide(Vector3(5,0,0))
 check(flight==null and game.fly.position.x>102.9,"Actual fly fits the front radio approach")
 await frames(2)
 check(game.nearest=="night_relay","Aim and reach detect the original radio front")
 press_e()
 check(game.mode=="inspection" and game.current_id=="night_relay","E opens actual relay inspection")
 front_camera("night_relay",relay)
 check(not game.state.nursery_diagnosed and game.night_relay_pulse.disabled and game.night_relay_status.text.contains("Live Reserve (08)"),
  "A radio found first leads to the garden without changing status")
 game.resume_game()
 position_for_inspection(Vector3(377,49,2082),sensor)
 await frames(2)
 check(game.nearest!="nursery_sensor" and not game.interaction_is_current("nursery_sensor"),"Sensor cannot be read through its rear")
 var rear_sensor := space.intersect_ray(PhysicsRayQueryParameters3D.create(game.fly.position,sensor,1))
 check(not rear_sensor.is_empty(),"An existing surface occludes the rear sensor approach")
 position_for_inspection(Vector3(377,50,2064),sensor)
 await frames(2)
 check(not game.interaction_is_current("nursery_sensor"),"Sensor does not respond across the room")
 flight = game.fly.move_and_collide(Vector3(0,0,5))
 check(flight==null and game.fly.position.z>2068.9,"Actual fly fits the front sensor approach")
 await frames(2)
 check(game.nearest=="nursery_sensor","Actual line of sight finds the sensor housing from the front")
 press_e()
 check(game.mode=="inspection" and game.current_id=="nursery_sensor" and game.state.nursery_diagnosed,
  "Reading the sensor is the only way the diagnosis is logged")
 front_camera("nursery_sensor",sensor)
 var sensor_copy:=false
 for text in game.modal.find_children("*","Label",true,false):
  if text.text.contains("Crew Berth (06)"):sensor_copy=true
 check(sensor_copy,"Actual diagnosed sensor tells player the signed Crew Berth route")
 check(not light_on() and not game.state.nursery_restored,"Reading alone does not restore power")
 game.resume_game()
 position_for_inspection(Vector3(103,86,292.5),relay)
 await frames(2)
 press_e()
 check(game.mode=="inspection" and game.current_id=="night_relay" and not game.night_relay_pulse.disabled,
  "Diagnosed sensor unlocks deliberate relay choice")
 var before: String = FileAccess.get_file_as_string(State.PATH)
 game.night_relay_pulse.pressed.emit()
 check(game.night_relay_status.text=="Choose a circuit first.","An empty pulse does nothing")
 for wrong in [1,2]:
  game.night_relay_choice.select(wrong)
  game.night_relay_pulse.pressed.emit()
  check(game.night_relay_status.text.contains("Nothing changed"),"Incorrect circuit leaves the task unchanged")
 check(not light_on() and FileAccess.get_file_as_string(State.PATH)==before,"Wrong and empty inputs do not write a success")
 game.night_relay_choice.select(3)
 game.night_relay_pulse.pressed.emit()
 check(game.night_relay_status.text=="AIR • FLOW RESTORED" and light_on() and game.state.nursery_restored,
  "Explicit AIR pulse restores the existing fixture")
 check(game.state.found.count("nursery_restored")==1 and game.state.evidence_count()==0,"Optional journal note cannot stand in for a case clue")
 check(not game.state.cabinet_open and not game.state.dispatch_open and not game.state.complete,
  "The optional task is independent of the case and both puzzles")
 check(game.world.find_children("*","Light3D",true,false).size()==lights_before and game.world.collision_stats==collision_before,
  "Restoration changes neither collision nor dynamic-light count")
 game.night_relay_pulse.pressed.emit()
 check(game.night_relay_status.text=="Airflow already restored." and game.state.found.count("nursery_restored")==1,
  "Repeating the pulse duplicates no journal entry")
 game.start_game(false)
 check(light_on() and game.state.nursery_diagnosed and game.state.nursery_restored and game.state.found.count("nursery_restored")==1,
  "Continue reapplies restored status and journal")
 game.start_game(true)
 check(game.world.get_instance_id()==intact_world,"A new case reuses unchanged geometry")
 check(not light_on() and not game.state.nursery_diagnosed and not game.state.nursery_restored and not game.state.found.has("nursery_restored"),
  "New Investigation clears optional flags, the journal and reused fixture")
 check(Data.ESSENTIAL.size()==6 and Data.solved(0,0,["cup","chemical","ledger","note"]),"Original proof remains sufficient, and the count stays six")
 if failures.is_empty(): print("PASS: real front/rear LOS and fly approaches, deliberate AIR puzzle, stable fixture, isolated case, Continue and fresh reset")
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
