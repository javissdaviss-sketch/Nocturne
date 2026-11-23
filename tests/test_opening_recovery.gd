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
func tap(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=down
  root.push_input(e,true)
func flight_step(target:Vector3)->void:
 var collision:KinematicCollision3D=game.fly.move_and_collide(target-game.fly.global_position)
 check(collision==null and game.fly.global_position.distance_to(target)<0.03,
  "Actual fly shape met an obstacle at room sweep "+str(target))
 await frames(1)
func plain_notebook_text()->String:
 var lines:=PackedStringArray()
 for l in game.modal.find_children("*","Label",true,false):
  lines.append(l.text)
 return "\n".join(lines)
func choose_recovery()->bool:
 tap(KEY_ESCAPE)
 await process_frame
 if game.mode!="pause":return false
 for seek in range(8):
  var selected:=root.gui_get_focus_owner() as BaseButton
  if selected!=null and selected.text=="Return to a safe perch":
   tap(KEY_ENTER)
   return true
  tap(KEY_TAB)
  await process_frame
 return false
func click_recovery()->void:
 # Independent baseline control if keyboard focus cannot reach the action.
 if game.mode!="pause":return
 for button in game.modal.find_children("*","Button",true,false):
  if button.text!="Return to a safe perch":continue
  var at:Vector2=button.get_global_rect().get_center()
  for down in [true,false]:
   var event:=InputEventMouseButton.new()
   event.position=at
   event.global_position=at
   event.button_index=MOUSE_BUTTON_LEFT
   event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
   event.pressed=down
   root.push_input(event,true)
  return
func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("Use an isolated synthetic profile")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await frames()
 var origin:Vector3=game.fly.global_position
 var aim:Vector3=game.world.hotspots.cup.position
 # Real 3D sweeps along each side of the existing dining doors in carriage
 # 07; no camera teleport or fake occlusion for the original wrong turn.
 for point in [Vector3(-75,143,1225),Vector3(-75,143,1150),Vector3(0,143,1150),
  Vector3(0,143,1240),Vector3(104,143,1240)]:
  await flight_step(point)
 check(game.fly.global_position.x>55.0 and game.state.found.is_empty() and not game.first_look_armed,
  "Expected a real wrong room, with no discovered record or opening prompt")
 # Headless cannot capture native mouse-look; supply the test player's
 # deliberately wrong heading without replacing the actual keyboard menus.
 game.fly.yaw=0.0
 game.fly.pitch=0.32
 tap(KEY_J)
 await process_frame
 var text:=plain_notebook_text()
 check(game.mode=="notebook" and text.contains("Start with the cup beside him."),
  "Ordinary first-flight J did not state the known basic objective")
 check(not text.to_lower().contains("symbol lock") and not text.to_lower().contains("cable opening")
  and not text.to_lower().contains("hidden ledger"),"Initial notebook revealed an undiscovered route")
 tap(KEY_J)
 await process_frame
 check(game.mode=="play","J did not return to the existing flight")
 # Ordinary pause/Enter is just Resume, without moving or aiming the fly.
 var wrong_room:Vector3=game.fly.global_position
 tap(KEY_ESCAPE)
 await process_frame
 var default_pause:=root.gui_get_focus_owner() as BaseButton
 check(game.mode=="pause" and default_pause!=null and default_pause.text=="Resume flight",
  "Pause did not default to a safe non-destructive action")
 tap(KEY_ENTER)
 await frames(1)
 check(game.mode=="play" and game.fly.global_position.distance_to(wrong_room)<0.03
  and is_zero_approx(game.fly.yaw) and is_equal_approx(game.fly.pitch,0.32)
  and not game.first_look_armed,"Plain Pause→Enter changed the flight position, aim or cue")
 var prior_bytes:=FileAccess.get_file_as_bytes(State.PATH)
 var chosen:=await choose_recovery()
 check(chosen,"Lost player cannot select safe perch from pause by keyboard")
 if not chosen:click_recovery()
 await frames()
 var yaw:float=game.fly.yaw
 var pitch:float=game.fly.pitch
 var forward:=Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
 var alignment:=forward.dot(origin.direction_to(aim))
 check(game.mode=="play" and game.fly.global_position.distance_to(origin)<0.03,
  "Existing return-to-perch location changed")
 check(game.first_look_armed and alignment>0.9999 and game.prompt.text.contains("Move towards the cup"),
  "Recovery of an untouched case did not restore the useful first direction and known cue")
 check(game.state.found.is_empty() and FileAccess.get_file_as_bytes(State.PATH)==prior_bytes,
  "Deliberate safe-perch recovery fabricated a finding or saved a reset")
 # Experienced players should arrive at the same perch with their own aim
 # and no new opening cue; discovering a record is not a trigger to reset it.
 game.state.discover("cup")
 tap(KEY_TAB)
 check(game.mode=="deduction","Could not prepare actual unsent deduction")
 game.suspect_select.select(2)
 game.motive_select.select(3)
 game.evidence_checks.cup.button_pressed=true
 tap(KEY_ESCAPE)
 var draft:Dictionary=game.deduction_draft.duplicate(true)
 check(game.mode=="play" and not draft.is_empty(),"Existing draft did not retain its controls")
 game.first_look_armed=false
 game.fly.yaw=0.65
 game.fly.pitch=-0.2
 var found_recover:=await choose_recovery()
 check(found_recover,"Recovery unavailable after finding a record")
 if not found_recover:click_recovery()
 await frames()
 check(is_equal_approx(game.fly.yaw,0.65) and is_equal_approx(game.fly.pitch,-0.2)
  and not game.first_look_armed and game.state.found.has("cup"),
  "Experienced recovery overwrote their aim, discovery or disabled cue")
 check(game.deduction_draft==draft,"Recovery erased or changed an active unsent draft")
 tap(KEY_TAB)
 check(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==3
  and game.evidence_checks.cup.button_pressed,"Actual reopened deduction lost prior controls")
 print("OPENING_RECOVERY route=actual_two_doorways keyboard=",chosen," initial_notebook=",text.contains("Start with the cup beside him."),
  " returned_alignment=",alignment," issues=",problems)
 game.queue_free()
 await process_frame
 quit(0 if problems.is_empty() else 4)
