extends SceneTree
const State=preload("res://scripts/case_state.gd")
var game:Node
var errors:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,why:String)->void:
 if not ok:errors.append(why)
func key(code:Key)->void:
 var event:=InputEventKey.new()
 event.keycode=code
 event.physical_keycode=code
 event.pressed=true
 game._unhandled_input(event)
func button_with(text:String)->Button:
 for n:Button in game.modal.find_children("*","Button",true,false):
  if n.text==text:return n
 return null
func settle()->void:
 await physics_frame
 await process_frame
 await physics_frame
func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("Resolved view requires a fresh isolated case profile.")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 game.start_game(true)
 await settle()
 game.show_ending()
 check(button_with("Linger in the archive")==null and not is_instance_valid(game.resolved_archive_camera),"Unresolved ending should not expose any view")
 game.state.complete=true
 game.show_ending()
 check(button_with("Linger in the archive")==null and game.get_viewport().get_camera_3d()==game.fly.camera,"Legacy closed drawer fallback should keep ordinary ending")
 # Exercise the original physical drawer action and actual success response,
 # without substituting a new solver. Original smoke independently discovers
 # all clues/routes; this fixture sets its known evidence for navigation.
 game.world.unlock_dispatch()
 game.state.dispatch_open=true
 game.state.complete=false
 game.resume_game()
 game.fly.global_position=Vector3(-92,98,1244)
 game.fly.safe_position=game.fly.global_position
 game.fly.yaw=1.31
 game.fly.pitch=0.09
 game.fly.update_camera(0.0)
 var body_before:Vector3=game.fly.global_position
 var camera_before:Transform3D=game.fly.camera.global_transform
 var yaw:float=game.fly.yaw
 var pitch:float=game.fly.pitch
 for id in ["cup","chemical","ledger","note"]:game.state.discover(id)
 game.show_deduction()
 game.suspect_select.select(1)
 game.motive_select.select(1)
 for id in ["cup","chemical","ledger","note"]:game.evidence_checks[id].button_pressed=true
 game.submit_case()
 var unchanged:=FileAccess.get_file_as_bytes(State.PATH)
 check(game.mode=="ending" and game.state.complete and game.get_viewport().get_camera_3d()==game.fly.camera,"Original proved verdict unexpectedly re-aimed or failed to complete")
 var open:=button_with("Linger in the archive")
 check(is_instance_valid(open) and game.resolved_archive_eye().is_finite(),"Actual resolved scene did not offer a validated optional view")
 if not is_instance_valid(open):
  print("Resolved archive view issues=",errors)
  quit(1);return
 open.pressed.emit()
 var first:Camera3D=game.resolved_archive_camera
 check(game.mode=="ending_view" and is_instance_valid(first) and first==root.get_camera_3d() and first!=game.fly.camera,"Optional action didn't choose a separate real Camera3D")
 check(game.fly.global_position==body_before and game.fly.camera.global_transform==camera_before and not game.fly.active,"Static view changed the original player position, pose or camera")
 key(KEY_ESCAPE)
 check(game.mode=="ending" and not is_instance_valid(game.resolved_archive_camera) and root.get_camera_3d()==game.fly.camera,
  "Escape should return to the unchanged verdict and normal camera")
 var retry:=button_with("Linger in the archive")
 if is_instance_valid(retry):retry.pressed.emit()
 else:check(false,"The same resolved view cannot be opened again voluntarily")
 var back_to_train:=button_with("Return to the train")
 if is_instance_valid(back_to_train):back_to_train.pressed.emit()
 else:check(false,"Missing direct return to train")
 check(game.mode=="play" and game.fly.active and root.get_camera_3d()==game.fly.camera and game.fly.global_position==body_before and
  game.fly.yaw==yaw and game.fly.pitch==pitch,"Return to normal train released new state or changed input direction")
 check(FileAccess.get_file_as_bytes(State.PATH)==unchanged,"Optional resting view wrote to the original saved verdict")
 # Mask every known authored eye in this isolated world. The existing ending
 # should remain, rather than using a camera inside new physical art.
 for pos:Vector3 in game.RESOLVED_ARCHIVE_EYES:
  var barrier:=StaticBody3D.new()
  var block:=CollisionShape3D.new()
  var cube:=BoxShape3D.new()
  cube.size=Vector3(1,1,1)
  block.shape=cube
  barrier.add_child(block)
  game.world.add_child(barrier)
  barrier.global_position=pos
 await settle()
 game.show_ending()
 check(button_with("Linger in the archive")==null and game.mode=="ending","Camera did not fail safely after physical views became blocked")
 print("Resolved archive view issues=",errors)
 game.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 1)
