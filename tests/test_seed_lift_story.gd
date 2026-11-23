extends SceneTree
const Lift = preload("res://scripts/seed_lift.gd")
const Data = preload("res://scripts/case_data.gd")
const State = preload("res://scripts/case_state.gd")
const STORY := "seed_return_ready"
var failures: Array[String] = []
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(condition: bool, context: String) -> void:
 if not condition:
  failures.append(context)
  printerr("FAIL: ",context)
func settled() -> void:
 await physics_frame
 await process_frame
 await physics_frame
 await process_frame
func key(which: Key) -> void:
 var input := InputEventKey.new()
 input.keycode = which
 input.pressed = true
 game._unhandled_input(input)

func place(point: Vector3) -> void:
 game.fly.active = false
 game.fly.restore_pending = false
 game.fly.reset_movement()
 game.fly.global_position = point
 game.nearest = ""

func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading": await game.investigation_ready
 game.start_game(true)
 var world_id: int = game.world.get_instance_id()
 var lift: Node3D = game.world.seed_lift
 var original_hotspots: int = game.world.hotspots.size()
 var light_count: int = game.world.find_children("*","Light3D",true,false).size()
 check(not lift.returned and lift.seed.position==Lift.SEED_PATH[0] and lift.status.text=="RETURN PENDING","The seed starts visibly in its holder")
 var wrong: Vector3 = lift.to_global(Vector3(7,-4.7,-8))
 place(wrong)
 await settled()
 key(KEY_L)
 check(game.fly.landed and not game.state.found.has(STORY),"Landing on an adjacent floor is not a spoon event")
 check(not lift.show_landing_hint(wrong),"No optional landing cue beside the actual spoon")
 var middle: Vector3 = lift.to_global(Lift.INTAKE_PATH[1])
 place(middle)
 # Let the authentic flight tick record this as the last safe position. The
 # fixture otherwise disables movement while placing a player for key tests.
 game.fly.active = true
 await settled()
 check(game.fly.safe_position.distance_to(middle)<0.1,"The actual flight tick records the safe mid-route position")
 game.save_game()
 game.start_game(false)
 await settled()
 check(game.fly.global_position.distance_to(middle)<0.7 and not lift.returned,"Continue mid-route stays clear and cannot trigger the return")
 place(middle)
 for segment in Lift.INTAKE_PATH.slice(2):
  var goal: Vector3 = lift.to_global(segment)
  var result: KinematicCollision3D = game.fly.move_and_collide(goal-game.fly.global_position)
  check(result==null and game.fly.global_position.distance_to(goal)<0.08,"Actual fly reaches the spoon along the baffles")
 await settled()
 check(not lift.returned and not game.state.found.has(STORY),"Hovering over the spoon does not do anything")
 check(game.prompt.text.contains("Land on the balance spoon"),"The real control cue only appears above its physical landing surface")
 key(KEY_E)
 check(game.fly.landed and not lift.returned,"The normal nearby-surface action does not operate the spoon")
 key(KEY_L)
 check(not game.fly.landed and not lift.returned,"L as take-off does not operate it")
 place(lift.to_global(Lift.INTAKE_PATH[-1]))
 await settled()
 key(KEY_L)
 check(game.fly.landed and lift.returned and not lift.visibly_ready and lift.status.text=="RETURNING","Deliberate L landing starts the visible physical transfer")
 check(game.state.found.count(STORY)==1 and FileAccess.get_file_as_string(State.PATH).contains(STORY),"The single optional story is saved on the actual event")
 await create_timer(Lift.TRANSFER_TIME*0.55).timeout
 check(lift.seed.position.distance_to(Lift.SEED_PATH[0])>0.5 and lift.seed.position.distance_to(Lift.SEED_PATH[-1])>0.5,"The seed visibly moves instead of teleporting or changing a prompt")
 await create_timer(Lift.TRANSFER_TIME*0.65).timeout
 check(lift.visibly_ready and lift.seed.position.is_equal_approx(Lift.SEED_PATH[-1]) and lift.status.text=="RETURN READY" and lift.cradle_status.text=="IRIS READY","The seed lands visibly in the ready cradle and both physical readouts agree")
 key(KEY_L)
 place(lift.to_global(Lift.INTAKE_PATH[-1]))
 await settled()
 key(KEY_L)
 check(game.state.found.count(STORY)==1 and lift.visibly_ready,"Landing again cannot repeat the animation or duplicate the story")
 game.start_game(false)
 await settled()
 check(lift.visibly_ready and lift.seed.position==Lift.SEED_PATH[-1] and game.state.found.count(STORY)==1,"Continue preserves the physical result and journal")
 game.show_notebook(STORY)
 var heard := false
 for note in game.modal.find_children("*","Label",true,false):
  if note.text.contains("marsh nursery by the old ferry stop"): heard = true
 check(heard,"The optional notebook entry records the returned iris without case clues")
 check(game.world.hotspots.size()==original_hotspots and Data.ESSENTIAL.size()==6 and game.state.evidence_count()==0,"Original hotspot and proof always remain independent")
 check(not game.state.cabinet_open and not game.state.dispatch_open and not game.state.complete,"The original case flags do not move")
 check(game.world.find_children("*","Light3D",true,false).size()==light_count,"No new projected light was needed to show the outcome")
 game.start_game(true)
 check(game.world.get_instance_id()==world_id and not lift.returned and lift.seed.position==Lift.SEED_PATH[0] and not game.state.found.has(STORY),"A fresh investigation resets the reused fixture")
 game.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: actual L on the spoon, animated and persistent seed return, no wrong trigger, no case dependency, and reset")
 quit(0 if failures.is_empty() else 1)
