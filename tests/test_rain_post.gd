extends SceneTree
## Isolated playable regression for three existing-wall notes and the World tab.
const Data = preload("res://scripts/case_data.gd")
const State = preload("res://scripts/case_state.gd")
var game: Node3D
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)

func frames(count: int) -> void:
 for step in range(count):
  await physics_frame
  await process_frame

func place(point: Vector3, target: Vector3) -> void:
 game.fly.active = false
 game.fly.inspection = false
 game.fly.restore_pending = false
 game.fly.position = point
 game.fly.velocity = Vector3.ZERO
 game.fly.camera.position = point+(point-target).normalized()*2+Vector3(0,1,0)
 game.fly.camera.look_at(target)

func press_e() -> void:
 var event := InputEventKey.new()
 event.keycode = KEY_E
 event.pressed = true
 game._unhandled_input(event)

func panel_has(text: String) -> bool:
 for label in game.modal.find_children("*","Label",true,false):
  if label.text.contains(text): return true
 return false

func check_post_status(expected: Array) -> void:
 game.show_notebook("world")
 var matched := 0
 for button in game.modal.find_children("*","Button",true,false):
  if not button.has_meta("rain_post_id"): continue
  matched += 1
  var id: String = button.get_meta("rain_post_id")
  check(button.disabled == (not expected.has(id)), "Only a physically read post can open in the World tab: "+id)
  check(button.text.ends_with("Read" if expected.has(id) else "Unread"), "Explicit and correct read status: "+id)
 check(matched==3,"The World tab has all three locations")
 check(panel_has("The scraps tell you who lives there.") == (expected.size()==3),"The quiet closing line appears only after all three reads")

func read_post(id: String) -> void:
 var target: Vector3 = game.world.hotspots[id].position
 var side := signf(target.x)
 game.resume_game()
 var front := Vector3(side*39.5,target.y,target.z)
 place(front,target)
 await frames(2)
 check(game.nearest==id and game.prompt.text.contains("Rain post"),"The real E prompt routes only to the aimed-for pocket: "+id)
 press_e()
 check(game.mode=="inspection" and game.current_id==id and game.state.found.has(id),"E reads the original note from its front: "+id)
 check(panel_has(Data.RAIN_POSTS[id].text),"The collected note contains its complete authored text: "+id)
 var view_before: Vector3 = game.fly.camera.position
 var inspect_yaw: float = game.fly.inspect_yaw
 check(signf(target.x)*view_before.x<48 and not game.fly.active,"The fixed camera remains on the corridor side: "+id)
 var motion := InputEventMouseMotion.new()
 motion.relative = Vector2(700,300)
 game.fly._input(motion)
 await frames(2)
 check(is_equal_approx(game.fly.inspect_yaw,inspect_yaw) and game.fly.camera.position.is_equal_approx(view_before),"Inspection camera cannot orbit through the wall: "+id)
 check(not FileAccess.file_exists(game.state.evidence_photo_path(id)),"Reading the post does not create a field photograph")

func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading": await game.investigation_ready
 game.start_game(true)
 var intact_world: int = game.world.get_instance_id()
 check(game.world.hotspots.size()==21 and Data.ESSENTIAL.size()==6,"Original 18 plus three optional posts; original proof count is unchanged")
 var paper: Node = game.world.get_node("RainPostPockets")
 check(paper.get_meta("solid_geometry_exclude",false) and paper.find_children("*","StaticBody3D",true,false).is_empty(),"Mounted posts add nothing to the solid corridor")
 check_post_status([])
 game.show_notebook("rain_08")
 check(not panel_has(Data.RAIN_POSTS.rain_08.title),"Unreached notes cannot be opened by a direct journal request")
 game.resume_game()
 var space := game.world.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
 for id in Data.RAIN_POSTS:
  var target: Vector3 = game.world.hotspots[id].position
  var side := signf(target.x)
  place(Vector3(side*62,target.y,target.z),target)
  await frames(2)
  var occlusion := space.intersect_ray(PhysicsRayQueryParameters3D.create(game.fly.position,target,1))
  check(not occlusion.is_empty() and game.nearest!=id and not game.interaction_is_current(id),"The original wall occludes the back of the post: "+id)
  place(Vector3(0,target.y,target.z),target)
  await frames(2)
  check(not game.interaction_is_current(id),"Mid-aisle cannot read a distant note: "+id)
  place(Vector3(side*35,target.y,target.z),target)
  await frames(2)
  var approach: KinematicCollision3D = game.fly.move_and_collide(Vector3(side*4.5,0,0))
  check(approach==null and is_equal_approx(game.fly.position.x,side*39.5),"Original corridor admits the real fly to the pocket: "+id)
  var wall: KinematicCollision3D = game.fly.move_and_collide(Vector3(side*20,0,0))
  check(wall!=null,"The player still cannot enter the wall: "+id)
 var read: Array = []
 for id in ["rain_08","rain_06","rain_07"]:
  await read_post(id)
  read.append(id)
  check_post_status(read)
 await read_post("rain_08")
 check(game.state.found.count("rain_08")==1 and game.state.evidence_count()==0,"Rereading never duplicates or affects the case")
 check(not game.state.complete and not game.state.nursery_diagnosed and not game.state.nursery_restored and not game.state.cabinet_open and not game.state.dispatch_open,
  "Neighbour notes do not change the mystery or the optional service puzzle")
 var raw_save: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(State.PATH))
 check(raw_save.version==1 and not raw_save.has("rain_posts"),"Read status uses the existing save and discovery list")
 game.start_game(false)
 check_post_status(read)
 game.state.complete = true
 game.show_ending()
 await read_post("rain_07")
 check(game.state.complete and Data.solved(0,0,["cup","chemical","ledger","note"]),"A read remains optional after the ending and does not affect proof")
 game.start_game(true)
 check(game.world.get_instance_id()==intact_world,"Reset reuses the unchanged world")
 check_post_status([])
 if failures.is_empty(): print("PASS: true wall occlusion/reach, fixed corridor cameras, three out-of-order finds and read/unread, no photo/proof additions, Continue and restart")
 game.queue_free()
 await process_frame
 quit(0 if failures.is_empty() else 1)
