extends SceneTree
const State=preload("res://scripts/case_state.gd")
var game:Node
var problems:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
 if not ok:problems.append(message)
func frames(num:int=3)->void:
 for i in range(num):
  await physics_frame
  await process_frame
func action(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=down
  root.push_input(e,true)
func ordinary_rim(cup:Vector3)->Vector3:
 # Leave the optional opening hint's radius then return through the same
 # clear space. Subsequent actions use only the ordinary play controls.
 var start:Vector3=game.fly.global_position
 var toward:=start.direction_to(cup)
 check(game.fly.move_and_collide(toward*-10.0)==null,"Ordinary root approach was obstructed leaving the hint area")
 await frames()
 check(not game.first_look_armed,"Special opening hint did not end on real departure")
 check(game.fly.move_and_collide(toward*10.0)==null,"Ordinary root approach back to rim obstructed")
 await frames()
 check(game.nearest=="" and not game.interaction_is_current("cup"),"Last HUD frame must still be outside normal reach")
 return toward
func actual_approach(cup:Vector3)->Vector3:
 var toward:=await ordinary_rim(cup)
 check(game.fly.move_and_collide(toward*6.5)==null,"Real shape sweep across ordinary reach was blocked")
 game.fly.update_camera(0.0)
 # Do not manually clear nearest or update the game HUD. The only thing that
 # changed between the last HUD pass and the actual E key is real body travel.
 check(game.nearest=="" and game.interaction_is_current("cup"),"Expected only the stale HUD result to lag behind the real new reach")
 return game.fly.global_position
func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("Use an isolated synthetic profile")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 action(KEY_ENTER)
 await frames()
 var target:Vector3=game.world.hotspots.cup.position
 var near:=await actual_approach(target)
 var outside_input_margin:=near.distance_to(target)
 action(KEY_E)
 var ordinary_mode:String=game.mode
 var old_landed:bool=game.fly.landed
 check(ordinary_mode=="inspection" and game.current_id=="cup" and not old_landed,
  "Actual E from normal reachable pose missed inspection (mode="+ordinary_mode+", landed="+str(old_landed)+")")
 check(near.distance_to(game.fly.global_position)<0.02,"E wrongly advanced or landed the body")
 # Negative control: same reachable pose, but now a real collision-mask wall
 # lies between fly and clue, far enough from the clue to avoid its own mesh
 # intersection tolerance.
 game.start_game(true)
 await frames()
 var blocked_near:=await actual_approach(target)
 var obstruction:=StaticBody3D.new()
 game.world.add_child(obstruction)
 obstruction.global_position=blocked_near.lerp(target,0.55)
 var collision:=CollisionShape3D.new()
 var solid:=SphereShape3D.new()
 solid.radius=0.85
 collision.shape=solid
 obstruction.add_child(collision)
 await frames()
 var blocked_marker:bool=game.markers.cup.visible
 check(not blocked_marker and not game.interaction_is_current("cup"),
  "A solid-wall obstruction left the room marker or current physical reach live")
 action(KEY_E)
 check(game.mode=="play" and not game.state.found.has("cup"),
  "Fresh ordinary input found hidden evidence through physical obstruction")
 obstruction.queue_free()
 await frames()
 var old_photo:Vector3=game.world.hotspots.photo.position
 var old_pastry:Vector3=game.world.hotspots.pastry.position
 # The authored main target regions rarely overlap, so use two known fixture
 # records in the real unobstructed room to test the genuine selector rules.
 game.start_game(true)
 await frames()
 var overlap_near:=await actual_approach(target)
 var front:=overlap_near.direction_to(target)
 game.world.hotspots.photo.position=overlap_near+front*8.0
 game.world.hotspots.pastry.position=overlap_near+front*13.0
 await frames()
 check(game.nearest=="photo" and game.markers.photo.visible and game.interaction_is_current("photo"),
  "Overlap fixture did not acquire the original visible eligible target")
 game.world.hotspots.pastry.position=overlap_near+front*5.0
 check(game.interaction_is_current("pastry") and game.nearest=="photo",
  "Newly closer fixture was not live during the same frame")
 action(KEY_E)
 check(game.mode=="inspection" and game.current_id=="photo",
  "Missing-target refresh must not override an already visible live target")
 game.world.hotspots.photo.position=old_photo
 game.world.hotspots.pastry.position=old_pastry
 game.start_game(true)
 await frames()
 overlap_near=await actual_approach(target)
 front=overlap_near.direction_to(target)
 game.world.hotspots.photo.position=overlap_near+front*10.0
 game.world.hotspots.pastry.position=overlap_near+front*6.0
 check(game.nearest=="" and game.interaction_is_current("photo") and game.interaction_is_current("pastry"),
  "Expected two current candidates in the no-marker overlap fixture")
 action(KEY_E)
 check(game.mode=="inspection" and game.current_id=="pastry",
  "No-marker refresh did not preserve nearest eligible target preference")
 game.world.hotspots.photo.position=old_photo
 game.world.hotspots.pastry.position=old_pastry
 game.start_game(true)
 await frames()
 await ordinary_rim(target)
 action(KEY_E)
 check(game.mode=="play" and game.fly.landed and game.state.found.is_empty(),
  "Ordinary out-of-reach E no longer lands on the same real surface")
 print("LIVE_BOUNDARY close_gap_cm=",outside_input_margin," first_E_mode=",ordinary_mode,
  " first_E_landed=",old_landed," blocked_marker_visible=",blocked_marker,
  " issues=",problems)
 game.queue_free()
 await process_frame
 quit(0 if problems.is_empty() else 4)
