extends SceneTree
const Fly = preload("res://scripts/fly.gd")
const State = preload("res://scripts/case_state.gd")
var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")

func blocker(parent: Node3D, point: Vector3, extent: float) -> void:
 var obstacle := StaticBody3D.new()
 parent.add_child(obstacle)
 obstacle.position = point
 var collision := CollisionShape3D.new()
 var box := BoxShape3D.new()
 box.size = Vector3.ONE*extent
 collision.shape = box
 obstacle.add_child(collision)

func check(value: bool, message: String) -> void:
 if not value: errors.append(message)

func run() -> void:
 var fixture := Node3D.new()
 root.add_child(fixture)
 var east := Vector3(350,78,540)
 var west := Vector3(-420,102,1950)
 var edge := Vector3(509,80,1220)
 var trapped := Vector3(-360,140,500)
 for point in [east,west,edge]: blocker(fixture,point,3.0)
 blocker(fixture,trapped,138.0)
 var fly := Fly.new()
 fixture.add_child(fly)
 fly.active = false
 fly.set_physics_process(false)
 await physics_frame
 await physics_frame
 var save_path := "user://test-old-wide-save.json"
 var legacy := FileAccess.open(save_path,FileAccess.WRITE)
 legacy.store_string(JSON.stringify({"version":1,"position":[350,78,540]}))
 legacy.close()
 var loaded := State.new()
 check(loaded.load_from(save_path),"Existing v1 save loads")
 var saved_point := Vector3(loaded.saved_position[0],loaded.saved_position[1],loaded.saved_position[2])
 check(saved_point==east,"Existing v1 save coordinates remain valid")
 for point in [saved_point,west,edge]:
  check(not fly.position_is_clear(point),"Fixture starts inside a real obstacle")
  fly.restore_position(point)
  fly.resolve_restored_position()
  check(fly.position_is_clear(fly.global_position) and fly.global_position.distance_to(point)<=2.5,"Nearest local unblocked point is kept on both sides and near the edge")
  check(absf(fly.global_position.x)<510.0,"Recovered position stays inside the train")
 fly.restore_position(trapped)
 fly.resolve_restored_position()
 check(fly.global_position==Vector3(-75,88,1225),"No available local spawn still returns to the safe perch")
 var open_point := Vector3(190,88,620)
 fly.restore_position(open_point)
 fly.resolve_restored_position()
 check(fly.global_position==open_point,"An already valid save is never moved")
 fixture.queue_free()
 await process_frame
 if errors.is_empty(): print("PASS: legacy save, widened local recovery, valid original and trapped fallback")
 else: printerr(errors)
 quit(0 if errors.is_empty() else 1)
