extends SceneTree
const State=preload("res://scripts/case_state.gd")
var game:Node
var errors:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(test:bool,detail:String)->void:
 if not test:errors.append(detail)
func settle(n:int=3)->void:
 for i in range(n):
  await physics_frame
  await process_frame
func viewport_key(code:Key,pressed:bool)->void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=pressed
 root.push_input(event,true)
func key(code:Key)->void:
 for is_down in [true,false]:
  viewport_key(code,is_down)
  await process_frame
func steer(pressed:bool)->void:
 var event:=InputEventKey.new()
 event.keycode=KEY_W
 event.physical_keycode=KEY_W
 event.pressed=pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()
func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("First look requires a fresh synthetic save profile")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 await key(KEY_ENTER)
 await settle()
 check(game.mode=="play","Fresh Enter from title did not start the real case")
 var spawn:=Vector3(-75,88,1225)
 var cup:Vector3=game.world.hotspots.cup.position
 var target_distance:=spawn.distance_to(cup)
 var pitch:float=game.fly.pitch
 var yaw:float=game.fly.yaw
 var facing:=Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
 check(game.fly.global_position.distance_to(spawn)<0.02,"Fresh spawn moved")
 check(facing.dot(spawn.direction_to(cup))>0.9999,"First fresh view does not point towards its known clue")
 check(target_distance>game.reach("cup") and game.first_look_cue_is_current() and game.prompt.text.contains("Move towards the cup") and game.prompt.text.contains("L   Land"),"Initial cue must describe existing reach and separate L")
 await key(KEY_E)
 check(game.mode=="play" and not game.fly.landed and game.state.found.is_empty() and game.toast_label.text.contains("Get a little closer"),"Early E should clarify and not inspect or land")
 # A real intervening solid disables the specific guidance. No marker or
 # custom E path may grant the cup through the blocker.
 var barrier:=StaticBody3D.new()
 var obstacle:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(5,7,1.5)
 obstacle.shape=box
 barrier.add_child(obstacle)
 game.world.add_child(barrier)
 barrier.global_position=spawn.lerp(cup,0.43)
 await settle()
 check(not game.first_look_cue_is_current() and not game.interaction_is_current("cup"),"Cue ignored the real line of sight/reach gate")
 barrier.queue_free()
 await settle()
 # One short real game movement reaches the existing cue threshold. An E
 # before the next rendered HUD update still revalidates the same physics.
 steer(true)
 for tick in range(12):
  await settle(1)
  if game.fly.global_position.distance_to(cup)<game.reach("cup"):break
 steer(false)
 var entered:Vector3=game.fly.global_position
 check(entered.distance_to(cup)<game.reach("cup") and game.interaction_is_current("cup"),"A short W movement did not enter normal cup reach")
 game.nearest=""
 await key(KEY_E)
 check(game.mode=="inspection" and game.current_id=="cup" and game.state.found.has("cup"),"Real eligible E did not take priority over first look")
 check(not game.first_look_armed,"Opening cue should be over once an interaction occurs")
 var before_yaw:float=game.fly.yaw
 var before_pitch:float=game.fly.pitch
 # The viewport dispatch is synchronous. Check the unchanged return pose
 # before the next physics tick advances existing flight momentum.
 viewport_key(KEY_E,true)
 check(game.mode=="play" and game.fly.global_position.distance_to(entered)<0.2 and is_equal_approx(game.fly.yaw,before_yaw) and is_equal_approx(game.fly.pitch,before_pitch),"Inspection return teleported or re-aimed the real player")
 viewport_key(KEY_E,false)
 var original_count:int=game.state.found.size()
 game.state.saved_position=[-85.0,90.0,1200.0]
 game.state.remember_view(-1.05,0.31)
 game.state.save_to()
 game.show_title()
 await key(KEY_ENTER)
 await settle()
 check(game.mode=="play","Enter from a saved title did not continue the physical case")
 check(not game.first_look_armed and not game.first_look_cue_is_current() and absf(angle_difference(game.fly.yaw,-1.05))<0.0001 and is_equal_approx(game.fly.pitch,0.31),"Continue did not retain its existing aim independently of first look")
 check(game.state.found.size()==original_count and game.fly.global_position.distance_to(Vector3(-85,90,1200))<0.15,"Continue lost its actual saved place or evidence")
 # Explicit L retains ordinary landing and dismisses the nonmandatory cue.
 game.start_game(true)
 await settle()
 await key(KEY_L)
 check(game.fly.landed and not game.first_look_armed,"Explicit L should keep existing landing")
 game.start_game(true)
 await settle()
 game.fly.global_position=spawn+Vector3(0,0,-9)
 await settle()
 check(not game.first_look_armed,"Walking away should permanently end the local cue")
 game.fly.global_position=spawn
 await settle()
 check(not game.first_look_cue_is_current() and not game.prompt.text.contains("Move towards the cup"),"Coming back from outside the local context restarted the cue")
 print("First look actual game issues=",errors," start_gap=",target_distance," approach_gap=",entered.distance_to(cup))
 game.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 1)
