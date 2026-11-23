extends SceneTree
## Actual optional Rain Post first, reload, deliberate recovery and original finding.
const Save=preload("res://scripts/case_state.gd")
const Data=preload("res://scripts/case_data.gd")
var game:Node
var issues:Array[String]=[]
func _initialize()->void:call_deferred("run")
func require(ok:bool,message:String)->void:
 if not ok:issues.append(message)
func tick(n:int=2)->void:
 for i in range(n):
  await physics_frame
  await process_frame
func tap(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code;e.physical_keycode=code;e.pressed=down
  root.push_input(e,true)
func face(yaw:float,pitch:float)->Vector3:
 return Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
func enter_recovery()->bool:
 tap(KEY_ESCAPE)
 await process_frame
 for i in range(8):
  var focus:=root.gui_get_focus_owner()
  if focus is Button and focus.text=="Return to a safe perch":
   tap(KEY_ENTER)
   await tick()
   return game.mode=="play"
  tap(KEY_TAB)
  await process_frame
 return false
func reading(id:String,position:Vector3)->void:
 var point:Vector3=game.world.hotspots[id].position
 game.fly.active=false
 game.fly.position=position
 game.fly.reset_movement()
 game.fly.camera.global_position=position+(position-point).normalized()*2+Vector3(0.5,1,0)
 game.fly.camera.look_at(point)
 game.nearest=""
 await tick()
 require(game.interaction_is_current(id),"Physical interaction gates did not accept "+id)
 tap(KEY_E)
 await process_frame
 require(game.mode=="inspection" and game.current_id==id and game.state.found.has(id),"Actual E did not record "+id)
 tap(KEY_E)
 await process_frame
 require(game.mode=="play","Actual E did not close inspection "+id)
func run()->void:
 if FileAccess.file_exists(Save.PATH):quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await tick()
 var origin:Vector3=game.fly.global_position
 var cup:Vector3=game.world.hotspots.cup.position
 var rain:Vector3=game.world.hotspots.rain_07.position
 await reading("rain_07",Vector3(signf(rain.x)*39.5,rain.y,rain.z))
 require(game.state.found==["rain_07"] and game.state.evidence_count()==0 and not game.first_look_armed,"Reading an optional note touched case progress")
 require(game.investigation_lead()=="Vale is dead. Start with the cup beside him.","Optional discovery took over the main case lead")
 # Normal Pause→Enter, and a true Save & title→Continue, must not point to cup.
 game.fly.yaw=0.33
 game.fly.pitch=-0.21
 var near_rain:Vector3=game.fly.global_position
 tap(KEY_ESCAPE)
 await process_frame
 tap(KEY_ENTER)
 await tick()
 require(game.fly.global_position.distance_to(near_rain)<0.05 and not game.first_look_armed and absf(game.fly.yaw-0.33)<0.001,"Plain pause reoriented the player")
 game.fly.safe_position=near_rain
 game.save_game()
 game.show_title()
 await process_frame
 tap(KEY_ENTER)
 await tick()
 require(game.mode=="play" and game.state.found==["rain_07"] and not game.first_look_armed,"Normal Continue changed the saved note or rearmed guidance")
 require(absf(game.fly.yaw-0.33)<0.001 and absf(game.fly.pitch+0.21)<0.001,"Ordinary Continue reoriented optional-only save")
 var bytes:=FileAccess.get_file_as_bytes(Save.PATH)
 var used:=await enter_recovery()
 var actual_yaw:float=game.fly.yaw
 var actual_pitch:float=game.fly.pitch
 var alignment:=face(actual_yaw,actual_pitch).dot(origin.direction_to(cup))
 var cue:bool=game.first_look_armed and game.prompt.text.contains("Move towards the cup")
 require(used and game.fly.global_position.distance_to(origin)<0.03 and alignment>0.9999 and cue,"Deliberate safe perch failed to restore untouched case orientation after an optional find")
 require(game.state.found==["rain_07"] and FileAccess.get_file_as_bytes(Save.PATH)==bytes,"Recovery erased or rewrote optional notes")
 # A real original cup reading is a committed case event, even with side notes.
 await reading("cup",Vector3(-88,95,1250))
 game.fly.yaw=0.41
 game.fly.pitch=-0.18
 require(await enter_recovery(),"No safe perch with original case progress")
 require(not game.first_look_armed and absf(game.fly.yaw-0.41)<0.001 and game.state.found==["rain_07","cup"],
  "Recovery rearmed guidance or lost evidence after a genuine original finding")
 var originals:Array=game.state.found.duplicate()
 var known_optional:Array=Data.RAIN_POSTS.keys()+Data.JOURNAL_ONLY.keys()
 game.state.found.assign(known_optional)
 require(game.opening_case_unstarted(),"Combining established side story entries blocks the untouched case")
 for original in Data.CLUES.keys()+Data.TALKS.keys()+Data.PROPS.keys():
  game.state.found.assign(known_optional+[original])
  require(not game.opening_case_unstarted(),"Optional context bypasses original finding "+original)
 game.state.found.assign(originals)
 print("OPTIONAL_RECOVERY actual_rain=",game.state.found.has("rain_07")," before_case_cue=",cue," alignment=",alignment," errors=",issues)
 game.queue_free()
 await process_frame
 quit(0 if issues.is_empty() else 4)
