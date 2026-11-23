extends SceneTree
const State=preload("res://scripts/case_state.gd")
var game:Node
var errors:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,why:String)->void:
 if not ok:errors.append(why)
func settle(frames:int=3)->void:
 for i in range(frames):
  await physics_frame
  await process_frame
func action(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=down
  root.push_input(e,true)
func read_save()->Dictionary:
 return JSON.parse_string(FileAccess.get_file_as_string(State.PATH)) as Dictionary
func rewrite_save(parsed:Dictionary)->void:
 var f:=FileAccess.open(State.PATH,FileAccess.WRITE)
 f.store_string(JSON.stringify(parsed))
 f.close()

func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("Use a fresh synthetic profile")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 action(KEY_ENTER)
 await settle()
 check(game.mode=="play","Initial safe-default title Enter did not start")
 action(KEY_L)
 await settle()
 check(game.fly.landed,"Test did not land on the real table surface")
 # Headless does not allow native captured mouse look; set a chosen flight
 # heading here, and use the real pause/save and keyboard Continue paths.
 var chosen:=Vector2(-0.43,0.48)
 game.fly.yaw=chosen.x
 game.fly.pitch=chosen.y
 var perch:Vector3=game.fly.global_position
 var findings:=Array(game.state.found).duplicate()
 action(KEY_ESCAPE)
 var save_button:Button
 for n in game.modal.find_children("*","Button",true,false):
  if n.text=="Save & title":
   save_button=n
   break
 if save_button==null:
  push_error("Actual Save & title control missing")
  quit(2);return
 save_button.pressed.emit()
 check(game.mode=="title","Actual save did not return to title")
 var parsed:=read_save()
 var serialized:Variant=parsed.get("view",[])
 check(serialized is Array and serialized.size()==2
  and absf(angle_difference(float(serialized[0]),chosen.x))<0.0001
  and is_equal_approx(float(serialized[1]),chosen.y),"Saved bytes do not carry the two chosen view angles")
 check(parsed.get("version",0)==1,"Optional angles must not migrate existing file format")
 action(KEY_ENTER)
 await settle()
 check(game.mode=="play","Actual saved Enter did not Continue")
 var resumed_yaw:float=game.fly.yaw
 var resumed_pitch:float=game.fly.pitch
 var position_delta:float=perch.distance_to(game.fly.global_position)
 var angle_error:=absf(angle_difference(chosen.x,resumed_yaw))
 check(angle_error<0.0001 and absf(chosen.y-resumed_pitch)<0.0001,
  "Saved stopped-perch view was reset")
 check(position_delta<0.51,"Continue moved away from the actual supported perch")
 check(game.state.found==findings and not game.first_look_armed,"Continue changed case findings or armed fresh hint")
 # A temporary inspection orbit must never replace the normal flight aim.
 game.show_inspection("cup")
 game.fly.inspect_yaw=1.8
 game.fly.inspect_pitch=0.9
 game.save_game()
 var flight_aim:Array=read_save().get("view",[])
 check(flight_aim.size()==2 and absf(angle_difference(float(flight_aim[0]),chosen.x))<0.0001
  and is_equal_approx(float(flight_aim[1]),chosen.y),"Saved aim captured temporary inspection orbit")
 ## Reopen a legacy version-1 save with no optional aim at this exact location.
 parsed.erase("view")
 rewrite_save(parsed)
 game.show_title()
 action(KEY_ENTER)
 await settle()
 check(absf(angle_difference(game.fly.yaw,PI))<0.0001 and is_equal_approx(game.fly.pitch,-0.12),
  "Old v1 save without a view did not retain the original fallback")
 ## An invalid pitch also takes the known fallback rather than forcing the view.
 parsed["view"]=[0.42,99.0]
 rewrite_save(parsed)
 game.show_title()
 action(KEY_ENTER)
 await settle()
 check(absf(angle_difference(game.fly.yaw,PI))<0.0001 and is_equal_approx(game.fly.pitch,-0.12),
  "Invalid optional view did not use the fallback")
 print("CONTINUE_VIEW position_delta_cm=",position_delta," yaw_error_degrees=",rad_to_deg(angle_error),
  " resumed_pitch=",resumed_pitch," saved_view=",read_save().has("view")," issues=",errors)
 game.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 4)
