extends SceneTree
## Enter/E opens real panels and viewport Tab/Enter operates their controls.
## No need for rendering, mouse capture, copied save or outside resources.
const State=preload("res://scripts/case_state.gd")
const Data=preload("res://scripts/case_data.gd")
var game:Node
var issues:Array[String]=[]
var hit_checks:=0
func _initialize()->void:call_deferred("run")
func want(ok:bool,reason:String)->void:
 if not ok:
  issues.append(reason)
  printerr("INSPECTION_KEYS_FAIL: ",reason)
func frames(count:int=2)->void:
 for i in range(count):
  await physics_frame
  await process_frame
func tap(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code;e.physical_keycode=code;e.pressed=down
  root.push_input(e,true)
func focus_text()->String:
 var widget:=root.gui_get_focus_owner()
 return widget.text if widget is Button else ""
func UI(text:String)->Button:
 for n in game.modal.find_children("*","Button",true,false):
  if n.text==text:return n
 return null
func fit(control:Control)->Rect2:
 var r:=control.get_global_rect()
 var stretch:=root.get_stretch_transform()
 var origin:=stretch*r.position
 var end:=stretch*r.end
 return Rect2(origin,end-origin)
func inspect_buttons()->void:
 var seen:Array[Rect2]=[]
 for n in game.modal.find_children("*","Button",true,false):
  var current:=fit(n)
  want(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(current),"Narrow hit area outside viewport: "+n.text)
  for prior in seen:want(not current.intersects(prior),"Overlapping hit targets: "+n.text)
  seen.append(current)
  hit_checks+=1
func click(button:Button)->void:
 if button==null:return
 var point:=button.get_global_rect().get_center()
 for down in [true,false]:
  var m:=InputEventMouseButton.new()
  m.position=point;m.global_position=point;m.button_index=MOUSE_BUTTON_LEFT;m.pressed=down
  m.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
  root.push_input(m,true)
  await process_frame
func tab_to(text:String)->void:
 for i in range(8):
  tap(KEY_TAB)
  await process_frame
  if focus_text()==text:return
 want(false,"Tab cannot reach "+text)
func near(id:String,pose:Vector3,offset:Vector3)->void:
 if game.mode!="play":
  want(false,"Previous panel did not resume flight before "+id+" (mode "+game.mode+")")
  game.resume_game()
 game.fly.active=false
 game.fly.inspection=false
 game.fly.position=pose
 game.fly.velocity=Vector3.ZERO
 var target:Vector3=game.world.hotspots[id].position
 game.fly.camera.global_position=pose+offset
 game.fly.camera.look_at(target)
 game.nearest=""
 await frames()
 want(game.interaction_is_current(id),"Fixture did not reach "+id)
 tap(KEY_E)
 await process_frame
 want(game.mode=="inspection" and game.current_id==id,"Actual E did not open "+id)
 inspect_buttons()
 want(focus_text()=="Return to flight   [E / Esc]","Missing safe return focus at "+id)
 print("KEY_NEAR id=",id," mode=",game.mode," record=",game.current_id," focus=",focus_text()," errors=",issues)
func choose(target:int)->void:
 var select:=root.gui_get_focus_owner() as OptionButton
 if select==null:want(false,"No focused symbol list");return
 var popup:=select.get_popup()
 tap(KEY_ENTER)
 await process_frame
 if not popup.visible:want(false,"Keyboard did not open the list");return
 var tries:=0
 while popup.get_focused_item()!=target and tries<7:
  tap(KEY_DOWN)
  await process_frame
  tries+=1
 want(popup.get_focused_item()==target,"Cannot highlight symbol choice")
 tap(KEY_ENTER)
 await process_frame
 want(select.selected==target and not popup.visible,"Keyboard did not choose symbol")
func run()->void:
 if FileAccess.file_exists(State.PATH):quit(2);return
 root.size=Vector2i(960,540)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await frames()
 want(root.size==Vector2i(960,540) and game.mode=="play","Expected exact fresh narrow viewport")
 await near("cup",Vector3(-88,95,1250),Vector3(0,2,-4))
 var pose:Vector3=game.fly.global_position
 var before:String=FileAccess.get_file_as_string(State.PATH)
 await tab_to("Study the mark")
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="trace_macro" and focus_text()=="Back to inspection   [E / Esc]","Keyboard cannot study or safely leave the mark")
 inspect_buttons()
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="inspection" and focus_text()=="Return to flight   [E / Esc]","Safe macro reopen did not return to inspection")
 await click(UI("Study the mark"))
 want(game.mode=="trace_macro","Mouse cannot open study after keyboard reopen")
 await click(UI("Back to inspection   [E / Esc]"))
 want(game.mode=="inspection","Mouse cannot reopen the prior panel")
 await click(UI("Return to flight   [E / Esc]"))
 want(game.mode=="play" and game.fly.global_position.distance_to(pose)<0.15 and FileAccess.get_file_as_string(State.PATH)==before,
  "Study/back/return changed physical location or case bytes")
 await near("latch",Vector3(102,12,1460),Vector3(-5,0,0))
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="play" and not game.state.cabinet_open,"Default Enter released the cabinet")
 await near("latch",Vector3(102,12,1460),Vector3(-5,0,0))
 await tab_to("BRIDGE THE CONTACT")
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="play" and game.state.cabinet_open and not game.world.cabinet_door.visible,"Deliberate keyboard bridge did not open original cabinet")
 await near("dispatch",Vector3(-100,98,2220),Vector3(0,2,-4))
 await tab_to("EXAMINE SYMBOL LOCK")
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="lock" and focus_text()=="Back to flight","Default lock focus is not safe Back")
 inspect_buttons()
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="play" and not game.state.dispatch_open,"Default Enter opened dispatch")
 await near("dispatch",Vector3(-100,98,2220),Vector3(0,2,-4))
 await tab_to("EXAMINE SYMBOL LOCK")
 tap(KEY_ENTER)
 await process_frame
 inspect_buttons()
 for id in [1,2,3]:
  await tab_to("Choose symbol…")
  await choose(id)
 await tab_to("Release drawer")
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="play" and game.state.dispatch_open and not game.world.drawer.visible,"Keyboard could not complete original symbol lock")
 await near("night_relay",Vector3(103,86,292.5),Vector3(-3,1,0))
 want(is_instance_valid(game.night_relay_pulse) and game.night_relay_pulse.disabled,"Undiagnosed relay did not show a disabled pulse")
 tap(KEY_ENTER)
 await process_frame
 want(game.mode=="play" and not game.state.nursery_restored,"Default Enter sent an early pulse")
 await near("nursery_sensor",Vector3(377,50,2069),Vector3(0,1,-3))
 tap(KEY_ENTER)
 await process_frame
 await near("night_relay",Vector3(103,86,292.5),Vector3(-3,1,0))
 await tab_to("Choose a circuit…")
 await choose(3)
 await tab_to("Send test pulse")
 tap(KEY_ENTER)
 await process_frame
 want(game.state.nursery_restored and is_instance_valid(game.night_relay_status) and game.night_relay_status.text=="AIR • FLOW RESTORED","Diagnosed relay deliberately chosen keyboard pulse failed")
 print("INSPECTION_KEYS_DONE actual_hit_checks=",hit_checks," issues=",issues)
 game.queue_free()
 await process_frame
 quit(0 if issues.is_empty() and hit_checks>=28 else 1)
