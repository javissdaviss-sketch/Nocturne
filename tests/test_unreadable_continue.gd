extends SceneTree
## Synthetic corrupted primary save plus a presumptive untouched recovery temp.
## Actual title Continue must not write either one in the future corrected build.
const State=preload("res://scripts/case_state.gd")
var game:Node
var issues:Array[String]=[]
func _initialize()->void:call_deferred("run")
func tap(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code;e.physical_keycode=code;e.pressed=down
  root.push_input(e,true)
func save_raw(path:String,bytes:PackedByteArray)->bool:
 var file:=FileAccess.open(path,FileAccess.WRITE)
 if file==null:return false
 file.store_buffer(bytes)
 file.close()
 return true
func require(ok:bool,reason:String)->void:
 if not ok:issues.append(reason)
func inspect_status(damaged:PackedByteArray,recovery:PackedByteArray)->void:
 var focused:=root.gui_get_focus_owner() as Button
 var feedback:=false
 for label in game.modal.find_children("*","Label",true,false):
  if label.text.contains("hasn’t changed your save"):
   feedback=label.get_line_count()<=3 and label.get_visible_line_count()==label.get_line_count()
 require(game.mode=="save_unavailable" and not game.fly.active and feedback and is_instance_valid(focused) and focused.text=="Back to title  [Esc]",
  "Failure must show safe Back and legible status instead of playing")
 require(FileAccess.get_file_as_bytes(State.PATH)==damaged and FileAccess.get_file_as_bytes(State.PATH+".tmp")==recovery,
  "Unreadable Continue modified primary or temporary bytes")
func focused_text()->String:
 var control:=root.gui_get_focus_owner() as Button
 return control.text if is_instance_valid(control) else ""
func run()->void:
 if FileAccess.file_exists(State.PATH) or FileAccess.file_exists(State.PATH+".tmp"):
  quit(2);return
 var damaged:='{"version":1,"found":["cup","note"'.to_utf8_buffer()
 var recovery:='{"version":1,"found":["cup","note"],"position":[0,120,1040],"view":[0.33,-0.21]}'.to_utf8_buffer()
 if not save_raw(State.PATH,damaged) or not save_raw(State.PATH+".tmp",recovery):
  quit(2);return
 root.size=Vector2i(960,540)
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 await process_frame
 require(root.size==Vector2i(960,540),"Expected real narrow viewport")
 require(focused_text()=="Continue" and not State.new().load_from(),"Expected real saved Continue and pure rejection by parser")
 tap(KEY_ENTER)
 await process_frame
 inspect_status(damaged,recovery)
 # Cross the normal auto-save threshold in the same actual process code.
 game.save_clock=20.0
 game._process(0.25)
 inspect_status(damaged,recovery)
 tap(KEY_ENTER)
 await process_frame
 require(game.mode=="title" and focused_text()=="Continue","Default Back did not return to the ordinary title")
 tap(KEY_ENTER)
 await process_frame
 inspect_status(damaged,recovery)
 tap(KEY_ESCAPE)
 await process_frame
 require(game.mode=="title","Escape did not safely back out")
 # Same title: deliberately seek the New Case action by keyboard.
 for i in range(6):
  if focused_text().begins_with("BEGIN INVESTIGATION"):break
  tap(KEY_TAB)
  await process_frame
 require(focused_text().begins_with("BEGIN INVESTIGATION"),"No deliberate new case action")
 tap(KEY_ENTER)
 await process_frame
 require(game.mode=="new_case_confirm" and focused_text().begins_with("Cancel"),"New Case lost its explicit safe confirmation")
 tap(KEY_ENTER)
 await process_frame
 require(game.mode=="title" and FileAccess.get_file_as_bytes(State.PATH)==damaged and FileAccess.get_file_as_bytes(State.PATH+".tmp")==recovery,
  "Cancel overwrote synthetic save")
 # Valid bytes provided by this fixture still continue normally.
 require(save_raw(State.PATH,recovery),"Could not create separate valid synthetic control")
 tap(KEY_ENTER)
 await physics_frame
 await process_frame
 require(game.mode=="play" and game.state.found==["cup","note"] and absf(game.fly.yaw-0.33)<0.001 and absf(game.fly.pitch+0.21)<0.001,
  "Readable case no longer continues with original findings and aim")
 # Real close notification from the refusal panel must not bypass the rule.
 require(save_raw(State.PATH,damaged) and save_raw(State.PATH+".tmp",recovery),"Could not reset synthetic test files")
 game.show_title()
 await process_frame
 tap(KEY_ENTER)
 await process_frame
 inspect_status(damaged,recovery)
 game.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
 await process_frame
 require(game.quitting and FileAccess.get_file_as_bytes(State.PATH)==damaged and FileAccess.get_file_as_bytes(State.PATH+".tmp")==recovery,
  "Closing the window wrote protected bytes")
 print("UNREADABLE_SAVE_DONE narrow=",root.size," exact_primary_and_tmp_unchanged=",FileAccess.get_file_as_bytes(State.PATH)==damaged and FileAccess.get_file_as_bytes(State.PATH+".tmp")==recovery," issues=",issues)
 if not issues.is_empty():quit(4)
 # The genuine close handler will quit after its independent 150ms delay.
