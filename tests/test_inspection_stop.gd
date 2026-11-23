extends SceneTree
const State=preload("res://scripts/case_state.gd")
var game:Node
var checks:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,why:String)->void:
 if not ok:checks.append(why)
func settle(frames:int=3)->void:
 for i in range(frames):
  await physics_frame
  await process_frame
func physical(code:Key,pressed:bool)->void:
 var e:=InputEventKey.new()
 e.keycode=code
 e.physical_keycode=code
 e.pressed=pressed
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func action(code:Key)->void:
 for pressed in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=pressed
  root.push_input(e,true)
func approach(cup:Vector3)->bool:
 physical(KEY_W,true)
 for tick in range(12):
  await settle(1)
  if game.fly.global_position.distance_to(cup)<game.reach("cup"):
   return game.interaction_is_current("cup")
 return false
func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("Use a fresh synthetic profile")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 action(KEY_ENTER)
 await settle()
 check(game.mode=="play","Actual first title Enter did not start")
 var cup:Vector3=game.world.hotspots.cup.position
 check(await approach(cup),"Physical first W did not reach the cup")
 physical(KEY_W,false)
 var entered:Vector3=game.fly.global_position
 var incoming:float=game.fly.velocity.length()
 check(incoming>15.0 and not Input.is_physical_key_pressed(KEY_W),"Repro must release W with earlier momentum")
 action(KEY_E)
 var before_yaw:float=game.fly.yaw
 var before_pitch:float=game.fly.pitch
 check(game.mode=="inspection" and game.current_id=="cup","Physical E did not enter the ordinary inspection")
 await settle(8)
 check(entered.distance_to(game.fly.global_position)<0.02,"Body moved while inspection was open")
 var saved:=FileAccess.get_file_as_bytes(State.PATH)
 action(KEY_E)
 check(game.mode=="play" and entered.distance_to(game.fly.global_position)<0.02,
  "Inspection return teleported on the input frame")
 check(is_equal_approx(game.fly.yaw,before_yaw) and is_equal_approx(game.fly.pitch,before_pitch),
  "Inspection return changed physical aim")
 await settle(24)
 var drift:float=entered.distance_to(game.fly.global_position)
 check(drift<0.06,"Released-key inspection exit drifted "+str(drift)+" cm")
 check(FileAccess.get_file_as_bytes(State.PATH)==saved,"A stationary return changed the saved finding")
 var still:Vector3=game.fly.global_position
 physical(KEY_D,true)
 await settle(8)
 physical(KEY_D,false)
 check(still.distance_to(game.fly.global_position)>0.8,"New movement after returning ceased to work")
 ## Deliberately held movement keeps the original inspection/pause response.
 game.start_game(true)
 await settle()
 check(await approach(cup),"Held-input control did not reach physical first clue")
 var held_vel:Vector3=game.fly.velocity
 action(KEY_E)
 check(game.mode=="inspection","Held-input control did not open inspection")
 await settle(3)
 check(Input.is_physical_key_pressed(KEY_W),"Held-input control lost its held key")
 action(KEY_E)
 check(game.mode=="play" and held_vel.distance_to(game.fly.velocity)<0.01,
  "Held movement no longer resumes its prior input response")
 var pause_velocity:Vector3=game.fly.velocity
 game.show_pause()
 game.resume_game()
 check(Input.is_physical_key_pressed(KEY_W) and pause_velocity.distance_to(game.fly.velocity)<0.01,
  "Returning from pause while still holding W lost the existing response")
 physical(KEY_W,false)
 ## Ordinary landing and ballistic jumping must not be converted to a hover.
 game.start_game(true)
 await settle()
 action(KEY_L)
 await settle()
 var grounded_velocity:Vector3=game.fly.velocity
 check(game.fly.landed,"Landing safeguard did not hit a real surface")
 game.show_inspection("cup")
 action(KEY_E)
 check(game.fly.landed and grounded_velocity.distance_to(game.fly.velocity)<0.01,
  "Leaving inspection discarded existing ground contact")
 game.fly.press_space()
 check(game.fly.jumping,"Jump safeguard did not enter its existing physical mode")
 var jump_velocity:Vector3=game.fly.velocity
 game.show_inspection("cup")
 action(KEY_E)
 check(game.fly.jumping and jump_velocity.distance_to(game.fly.velocity)<0.01,
  "Leaving inspection discarded existing jump velocity")
 print("INSPECTION_RESUME input_released_drift_cm=",drift," incoming_speed_cm_s=",incoming,
  " preserved_held_speed_cm_s=",held_vel.length()," issues=",checks)
 game.queue_free()
 await process_frame
 quit(0 if checks.is_empty() else 4)
