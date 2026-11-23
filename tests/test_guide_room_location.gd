extends SceneTree
## Exact location and optical fixture for the opt-in Carriage Guide only.
const Guide=preload("res://scripts/carriage_guide.gd")
const Signs=preload("res://scripts/door_purpose_plates.gd")
const Save=preload("res://scripts/case_state.gd")
var game:Node
var issues:Array[String]=[]
var captions_checked:=0
var bounds_rejected:=0
func _initialize()->void:call_deferred("run")
func want(ok:bool,message:String)->void:
 if not ok:issues.append(message)
func key(which:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=which;e.physical_keycode=which;e.pressed=down
  root.push_input(e,true)
func room_caption(at:Vector3,yaw:float,pitch:float,needle:String)->String:
 game.fly.global_position=at
 game.fly.yaw=yaw;game.fly.pitch=pitch
 game.show_notebook("guide")
 await process_frame
 var reading:Label
 for line in game.modal.find_children("*","Label",true,false):
  if line.text.begins_with("You’re here:"):
   reading=line
   break
 if reading==null:
  issues.append("Guide location could not be found")
  return ""
 if not needle.is_empty():want(reading.text.ends_with(needle),"Guide text does not end with expected location: "+reading.text+" / "+needle)
 else:want(not reading.text.contains("Facing door:") and not reading.text.contains("Room:"),"Unexpected precise location: "+reading.text)
 var r:=reading.get_global_rect()
 var stretch:=root.get_stretch_transform()
 var pixel_start:=stretch*r.position
 var pixel_end:=stretch*(r.position+Vector2(r.size.x,reading.get_line_height(0)))
 want(reading.get_line_count()==1 and reading.get_visible_line_count()==1 and
  Rect2(Vector2.ZERO,Vector2(root.size)).encloses(Rect2(pixel_start,pixel_end-pixel_start)),"The actual label doesn't fit the window: "+reading.text)
 captions_checked+=1
 return reading.text
func run()->void:
 if FileAccess.file_exists(Save.PATH):quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 game.start_game(true)
 game.set_process(false)
 game.fly.set_physics_process(false)
 var space:PhysicsDirectSpaceState3D=game.get_world_3d().direct_space_state
 var rooms:Array=game.guide_rooms()
 var original:=FileAccess.get_file_as_bytes(Save.PATH)
 for res in [Vector2i(960,540),Vector2i(1280,800)]:
  root.size=res
  await process_frame
  want(root.size==res and rooms.size()==14,"Incorrect actor or viewport fixture")
  for room in rooms:
   var side:float=room.side
   var z:float=room.entry
   var text:String=Signs.PURPOSE[Signs.key(room.car,room.side,room.lo)]
   var inside:=Vector3(side*134.0,105.0,z)
   var corridor:=Vector3(0.0,105.0,z)
   var toward:float=-side*PI/2.0
   want(game.fly.position_is_clear(inside) and game.fly.position_is_clear(corridor),"Chosen location intersects production geometry "+text)
   await room_caption(inside,0.0,-0.12,"Room: "+text)
   await room_caption(corridor,toward,0.0,"Facing door: "+text)
   if res.x==960:
    await room_caption(corridor,0.0,0.0,"")
    await room_caption(corridor,toward,1.0,"")
    var outside:=Vector3(0.0,105.0,z+float(room.width)*0.5+7.0)
    await room_caption(outside,toward,0.0,"")
    bounds_rejected+=3
  for outside in [Vector3(0,105,820),Vector3(0,105,1660),Vector3(0,230,1150),Vector3(-120,298,1240)]:
   await room_caption(outside,PI/2.0,0.0,"")
   bounds_rejected+=1
 # Both opposite facing rooms in one opening section must resolve their own label.
 await room_caption(Vector3(0,105,889),PI/2.0,0.0,"Facing door: CONCIERGE")
 await room_caption(Vector3(0,105,889),-PI/2.0,0.0,"Facing door: CLOAKROOM")
 # Closed optical route: an otherwise valid aperture is not listed through
 # a static body. Test control only, no fixture geometry leaves this process.
 var screen:=StaticBody3D.new()
 var blocker:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=Vector3(2,28,25)
 blocker.shape=box
 screen.add_child(blocker)
 game.add_child(screen)
 screen.position=Vector3(-25,105,1150)
 await physics_frame
 await process_frame
 await room_caption(Vector3(0,105,1150),PI/2.0,0.0,"")
 bounds_rejected+=1
 screen.queue_free()
 await physics_frame
 await process_frame
 await room_caption(Vector3(0,105,1150),PI/2.0,0.0,"Facing door: MERIDIAN DINING")
 # Existing actual keyboard pin workflow preserves the optional readout.
 for i in range(10):
  var focused:=root.gui_get_focus_owner()
  if is_instance_valid(focused) and focused.get_meta("carriage_pin",-1)==2:
   key(KEY_ENTER)
   await process_frame
   break
  key(KEY_TAB)
  await process_frame
 want(game.carriage_pin==2 and game.mode=="notebook","Known room prevents existing pin")
 var pinned:=await room_caption(Vector3(0,105,1150),PI/2.0,0.0,"Facing door: MERIDIAN DINING")
 want(not pinned.to_lower().contains("cup") and game.state.found.is_empty() and FileAccess.get_file_as_bytes(Save.PATH)==original,
  "Readout exposed a finding or wrote progress")
 game.state.discover("cup")
 game.show_deduction()
 game.suspect_select.select(2)
 game.motive_select.select(3)
 game.evidence_checks.cup.button_pressed=true
 game.review_deduction_evidence()
 await room_caption(Vector3(-134,105,1150),0.0,0.0,"Room: MERIDIAN DINING")
 game.close_notebook()
 want(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==3
  and game.evidence_checks.cup.button_pressed and game.carriage_pin==2,
  "Room identity or pin changed the unsent draft")
 print("GUIDE_LOCATIONS_DONE projected_panels=",captions_checked," negative_controls=",bounds_rejected," issues=",issues)
 game.queue_free()
 await process_frame
 quit(0 if issues.is_empty() and captions_checked>=110 else 4)
