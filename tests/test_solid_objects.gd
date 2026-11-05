extends SceneTree
## Physical regressions for visible MeshInstance and MultiMesh props, at fly scale.
const World = preload("res://scripts/world.gd")
const Fly = preload("res://scripts/fly.gd")
var failures: Array[String] = []
var fly: CharacterBody3D
var world: Node3D

func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)

func _initialize() -> void:
 call_deferred("run")

func frames(count: int) -> void:
 for _i in range(count):
  await physics_frame
  await process_frame

func key(code: Key, pressed: bool) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = code
 event.keycode = code
 event.pressed = pressed
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func place(point: Vector3) -> void:
 fly.active = false
 fly.inspection = false
 fly.reset_movement()
 fly.position = point

func blocked(label: String, point: Vector3, motion: Vector3) -> void:
 place(point)
 var collision := fly.move_and_collide(motion)
 check(collision != null,label+" blocks an actual fly sweep")

func clear_gap(label: String, point: Vector3, motion: Vector3) -> void:
 place(point)
 var collision := fly.move_and_collide(motion)
 check(collision == null and fly.position.distance_to(point+motion)<0.05,label+" admits the actual fly through its empty space")

func find_leaf(node: Node) -> MeshInstance3D:
 if node is MeshInstance3D and node.material_override is StandardMaterial3D:
  if node.material_override.albedo_texture == World.LEAF_TEXTURE: return node
 for child in node.get_children():
  var result := find_leaf(child)
  if result != null: return result
 return null

func overlaps_body(point: Vector3) -> bool:
 var query := PhysicsShapeQueryParameters3D.new()
 var shape_node := fly.get_child(0) as CollisionShape3D
 query.shape = shape_node.shape
 query.transform = Transform3D(Basis.IDENTITY,point)
 query.collision_mask = 1
 query.exclude = [fly.get_rid()]
 return not world.get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func check_talk_prompts() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await frames(2)
 game.resume_game()
 game.fly.active = false
 for id in ["engineer","steward","botanist"]:
  var target: Vector3 = game.world.hotspots[id].position
  # From the window side, the speaker's own newly-solid torso/arm lies in the
  # listening ray. That actor can still be heard within the normal reach.
  var approach := Vector3(150,target.y,target.z)
  game.fly.position = approach
  game.fly.reset_movement()
  game.fly.camera.position = approach+Vector3(3,2,0)
  game.fly.camera.look_at(target)
  await frames(2)
  check(game.nearest == id,"New solid actor does not hide its own listening prompt: "+id)
  # A genuinely separate wall must still occlude the same speaker.
  var barrier := StaticBody3D.new()
  var shape := CollisionShape3D.new()
  var box := BoxShape3D.new()
  box.size = Vector3(0.6,22,22)
  shape.shape = box
  barrier.add_child(shape)
  root.add_child(barrier)
  barrier.position = Vector3(144,target.y,target.z)
  await frames(2)
  check(game.nearest != id,"Separate solid obstruction blocks listening prompt: "+id)
  barrier.queue_free()
  await frames(2)
 game.queue_free()
 await frames(1)

func run() -> void:
 world = World.new()
 root.add_child(world)
 fly = Fly.new()
 root.add_child(fly)
 fly.active = false
 await frames(2)
 # Both approaches must hit the thin trolley deck, not a coarse volume around it.
 blocked("Trolley deck edge",Vector3(90,78.4,1010),Vector3(60,0,0))
 check(fly.position.x < 103.0,"Horizontal sweep stops before the trolley deck")
 blocked("Trolley top",Vector3(142,110,1010),Vector3(0,-60,0))
 check(fly.position.y > 79.6,"Downward sweep rests on the top tray, not the lower shelf")
 clear_gap("Space between trolley legs",Vector3(96,55,1010),Vector3(58,0,0))
 blocked("Thin trolley leg",Vector3(97,55,985),Vector3(20,0,0))
 blocked("Overhead luggage",Vector3(143,245,300),Vector3(0,0,65))
 check(fly.position.z < 311.0,"Luggage front face blocks entry")
 blocked("Radio front",Vector3(105,89,287),Vector3(28,0,0))
 check(fly.position.x < 112.0,"Radio grille blocks entry before the cabinet body")
 blocked("Chessboard",Vector3(-102,95,140),Vector3(0,-30,0))
 check(fly.position.y > 79.3,"Chessboard supports the fly above its supporting table")
 blocked("Reading lamp shade",Vector3(-131,120,151),Vector3(0,-14,0))
 check(fly.position.y > 110.0,"Reading lamp shade supports the fly")
 blocked("Human torso",Vector3(78,110,530),Vector3(45,0,0))
 check(fly.position.x < 105.0,"The engineer's visible body blocks flight")
 blocked("Palm cane",Vector3(-146,90,270),Vector3(30,0,0))
 check(fly.position.x < -132.0,"Palm cane is solid above the table")
 # Sample an actual curved leaf triangle, not an approximate crown bounding box.
 var leaf := find_leaf(world)
 check(leaf != null,"A textured palm leaf exists for the surface test")
 if leaf != null:
  var faces: PackedVector3Array = leaf.mesh.get_faces()
  var a: Vector3 = leaf.to_global(faces[36])
  var b: Vector3 = leaf.to_global(faces[37])
  var c: Vector3 = leaf.to_global(faces[38])
  var center := (a+b+c)/3.0
  var normal := (b-a).cross(c-a).normalized()
  blocked("Palm frond upper side",center+normal*2.0,-normal*4.0)
  blocked("Palm frond lower side",center-normal*2.0,normal*4.0)
 # A torus collider must preserve the handle hole and still stop at its rim.
 clear_gap("Teapot handle hole",Vector3(110,89.4,996),Vector3(0,0,6))
 blocked("Teapot handle rim",Vector3(105.7,89.4,996),Vector3(0,0,6))
 clear_gap("Garden crate slat gap",Vector3(-154,10,2421),Vector3(7.5,0,0))
 blocked("Garden crate slat",Vector3(-154,6,2421),Vector3(7.5,0,0))
 clear_gap("Open service cable duct above its cable",Vector3(65,12,1460),Vector3(37,0,0))
 check(fly.position.distance_to(Vector3(104,11,1460))<5.0,"Duct route reaches the latch within interaction distance")
 blocked("Fixed service cabinet front beside the puzzle door",Vector3(65,50,1521),Vector3(30,0,0))
 # Exercise the real flight controller at full speed against a narrow trolley leg.
 place(Vector3(95,55,985))
 fly.yaw = 0.0
 fly.active = true
 fly.velocity = Vector3(165,0,0)
 key(KEY_D,true)
 await frames(18)
 key(KEY_D,false)
 check(fly.position.x < 105.3,"Full-speed active flight cannot tunnel through a trolley leg")
 fly.active = false
 # Walk slowly across the real tabletop into the raised travel board.
 place(Vector3(-127,84,140))
 check(fly.try_land(),"The table beside the travel board is reachable for walking")
 fly.active = true
 key(KEY_D,true)
 await frames(100)
 key(KEY_D,false)
 check(fly.position.x < -121.1 and fly.landed,"Landed walking stops at the chessboard edge")
 fly.active = false
 # Snap onto a newly-solid thin tray through the same player landing action.
 place(Vector3(142,90,1010))
 check(fly.try_land() and fly.landed and fly.position.y > 79.7,"Landing snaps to the trolley's upper tray")
 # A thin overhead plate leaves enough room for a landed fly, but not a teleport.
 # This isolated physical fixture tests takeoff independently of changing props.
 var ceiling := StaticBody3D.new()
 var shape := CollisionShape3D.new()
 var plate := BoxShape3D.new()
 plate.size = Vector3(4,0.08,4)
 shape.shape = plate
 ceiling.add_child(shape)
 root.add_child(ceiling)
 ceiling.position = Vector3(0,2.03,200)
 await frames(2)
 place(Vector3(0,8,200))
 # Start below the plate and land on the aisle runner.
 fly.position = Vector3(0,1.60,200)
 fly.velocity = Vector3.ZERO
 fly.landed = true
 fly.take_off()
 check(fly.position.y < 1.83,"Takeoff cannot teleport through a thin overhead plate")
 fly.active = true
 key(KEY_SPACE,true)
 await frames(12)
 key(KEY_SPACE,false)
 check(fly.position.y < 1.84,"Active ascent remains below the plate after takeoff")
 fly.active = false
 # A save recorded before props became solid can be deeply inside a cabinet.
 var old_radio_position := Vector3(119,89,287)
 check(overlaps_body(old_radio_position),"Regression save point really overlaps the radio")
 fly.restore_position(old_radio_position)
 await frames(2)
 check(not overlaps_body(fly.position),"Deeply embedded saved position recovers outside solid geometry")
 check(fly.position.distance_to(old_radio_position)<30.0,"Saved-position recovery stays near the original location")
 check(fly.safe_position.is_equal_approx(fly.position),"Recovery updates the save's safe position")
 var clear_position := Vector3(0,105,300)
 check(not overlaps_body(clear_position),"Regression clear save point is free")
 fly.restore_position(clear_position)
 await frames(2)
 check(fly.position.is_equal_approx(clear_position),"Existing clear saved position stays unchanged")
 ceiling.queue_free()
 fly.queue_free()
 world.queue_free()
 await frames(1)
 await check_talk_prompts()
 if failures.is_empty(): print("PASS: solid props, human/palm surfaces, true handle/slat/leg/duct gaps, full-speed flight, walking, landing/takeoff, saved-position recovery, and speaker/obstruction prompts")
 quit(0 if failures.is_empty() else 1)
