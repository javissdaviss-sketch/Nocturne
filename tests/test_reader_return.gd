extends SceneTree
## Audit actual flight inputs across two reading menus and ordinary pause.
## Initial legal pose is staged per scenario; all movement is engine driven.
const Save=preload("res://scripts/case_state.gd")
var game:Node
var errors:Array[String]=[]
var modal_offsets:Dictionary={}
var drops:Array[String]=[]
func _initialize()->void:call_deferred("run")
func want(ok:bool,reason:String)->void:
 if not ok:errors.append(reason)
func tick(n:int=3)->void:
 for i in range(n):
  await physics_frame
  await process_frame
func key(code:Key,down:bool)->void:
 var e:=InputEventKey.new()
 e.keycode=code;e.physical_keycode=code;e.pressed=down
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func tap(code:Key)->void:
 key(code,true);key(code,false)
func stage()->void:
 # Clear mid-aisle in the existing three-carriage world.
 game.fly.restore_position(Vector3(0,120,1040))
 game.fly.yaw=0.0
 game.fly.pitch=-0.17
 await tick()
func thrust()->void:
 key(KEY_W,true)
 await tick(13)
func focus_guide()->bool:
 for i in range(12):
  var target:=root.gui_get_focus_owner()
  if target is Button and target.text=="CARRIAGE GUIDE":
   tap(KEY_ENTER)
   await process_frame
   return game.notebook_page=="guide"
  tap(KEY_TAB)
  await process_frame
 return false
func run()->void:
 if FileAccess.file_exists(Save.PATH):quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await tick()
 for trial in [["notebook",KEY_J,KEY_J],["deduction",KEY_TAB,KEY_TAB],["pause",KEY_ESCAPE,KEY_ENTER]]:
  var mode:String=trial[0]
  for keep_direction in [false,true]:
   await stage()
   await thrust()
   var speed:float=game.fly.velocity.length()
   var stopped:Vector3=game.fly.global_position
   tap(trial[1])
   await tick()
   want(game.mode==mode,"Unexpected modal during "+mode)
   if not keep_direction:key(KEY_W,false)
   await tick(9)
   var save_before:=FileAccess.get_file_as_bytes(Save.PATH)
   if mode=="notebook":
    want(await focus_guide(),"Could not open actual nested Guide")
   elif mode=="deduction":
    game.suspect_select.select(2)
    game.motive_select.select(3)
    tap(KEY_J)
    await tick()
    want(game.mode=="notebook","Deduction did not open its nested Notebook")
    tap(KEY_J)
    await tick()
    want(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==3,
     "Nested note review changed the unsent deduction")
   want(game.fly.global_position.distance_to(stopped)<0.1,"World moved while reading "+mode)
   tap(trial[2])
   await tick(12)
   var point:Vector3=game.fly.global_position
   var travelled:=stopped.distance_to(point)
   var current:float=game.fly.velocity.length()
   var held:bool=Input.is_physical_key_pressed(KEY_W)
   var visible_looking:bool=absf(game.fly.yaw)<0.0001 and absf(game.fly.pitch+0.17)<0.0001
   var label:="%s/%s"%[mode,"held" if keep_direction else "released"]
   modal_offsets[label]=travelled
   want(game.mode=="play" and visible_looking and held==keep_direction,"Exit changed aim/input in "+label)
   if keep_direction:
    want(travelled>14.0 and current>speed and point.z<stopped.z,"Exit ignored ongoing deliberate throttle in "+label)
   elif travelled>0.05 or current>0.001:
    drops.append(label)
   if mode=="deduction":
    want(game.deduction_draft.get("suspect",-1)==2 and game.deduction_draft.get("motive",-1)==3,
     "Returning to flight lost unsent deductions")
   want(FileAccess.get_file_as_bytes(Save.PATH)==save_before,"Reading mode changed save bytes")
   print("READ_RETURN ",label," incoming=",speed," travel=",travelled," outgoing=",current)
   key(KEY_W,false)
 # With the guard already fired at return, a new direction still moves.
 await stage()
 await thrust()
 tap(KEY_J)
 await tick()
 key(KEY_W,false)
 tap(KEY_J)
 await tick(3)
 var moving_from:Vector3=game.fly.global_position
 key(KEY_D,true)
 await tick(10)
 key(KEY_D,false)
 var moved:Vector3=game.fly.global_position-moving_from
 want(moved.x>5.0 and absf(moved.z)<0.05,"Newly pressed D did not move along the normal new heading")

 # Existing L, Space hop, outer pause, and vertical motion still settle.
 game.fly.restore_position(Vector3(0,6,1040))
 await tick()
 tap(KEY_L)
 await tick()
 var floor_pose:Vector3=game.fly.global_position
 want(game.fly.landed,"Fixture could not land on original runner")
 tap(KEY_SPACE)
 await tick(6)
 want(game.fly.jumping and game.fly.global_position.y>floor_pose.y+0.5,"Existing first jump did not start")
 tap(KEY_ESCAPE)
 await tick(2)
 var jumping_velocity:Vector3=game.fly.velocity
 var in_air:Vector3=game.fly.global_position
 await tick(8)
 want(game.fly.jumping and game.fly.velocity.is_equal_approx(jumping_velocity) and game.fly.global_position.is_equal_approx(in_air),"Pause changed frozen hop")
 tap(KEY_ENTER)
 await tick(30)
 want(game.fly.landed and not game.fly.jumping and absf(game.fly.global_position.y-floor_pose.y)<0.15,"Resume did not finish original hop")

 # Plain Continue uses the same stored orientation and offers no fresh cue.
 await stage()
 game.fly.safe_position=game.fly.global_position
 game.fly.yaw=0.44
 game.fly.pitch=-0.21
 game.save_game()
 game.show_title()
 await process_frame
 tap(KEY_ENTER)
 await tick()
 want(game.mode=="play" and absf(game.fly.yaw-0.44)<0.001 and absf(game.fly.pitch+0.21)<0.001 and not game.first_look_armed,"Ordinary Continue changed orientation/guidance")
 print("READ_RETURN_DONE natural_drift=",drops," baseline_errors=",errors)
 game.queue_free()
 await process_frame
 quit(0 if errors.is_empty() and drops.is_empty() else 4)
