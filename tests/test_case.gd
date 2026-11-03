extends SceneTree
const State = preload("res://scripts/case_state.gd")
const Data = preload("res://scripts/case_data.gd")
const World = preload("res://scripts/world.gd")
const Fly = preload("res://scripts/fly.gd")
var failures: Array[String] = []
func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var s = State.new()
 check(not s.discover("not_a_clue"),"Unknown clues rejected")
 check(s.discover("cup"),"First discovery recorded")
 check(not s.discover("cup"),"Duplicate discovery ignored")
 check(s.evidence_count()==1,"Only physical evidence counted")
 s.discover("steward")
 check(s.evidence_count()==1,"Conversation not counted as physical evidence")
 check(not Data.solved(0,0,["cup"]),"Incomplete case rejected")
 var proof := ["cup","chemical","ledger","note"]
 check(Data.solved(0,0,proof),"Supported solution accepted")
 check(not Data.solved(1,0,proof),"Wrong suspect rejected")
 check(not Data.solved(0,1,proof),"Wrong motive rejected")
 s.cabinet_open = true
 s.dispatch_open = true
 for id in Data.ESSENTIAL: s.discover(id)
 s.complete = true
 check(s.save_to("user://test-case.json")==OK,"Atomic save succeeds")
 var restored = State.new()
 check(restored.load_from("user://test-case.json"),"Save loads")
 check(restored.complete and restored.evidence_count()==6 and restored.cabinet_open and restored.dispatch_open,"Progress preserved")
 var f := FileAccess.open("user://test-bad.json",FileAccess.WRITE)
 f.store_string("{broken"); f.close()
 check(not State.new().load_from("user://test-bad.json"),"Malformed save fails safely")
 f = FileAccess.open("user://test-bad.json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"version":1,"found":["ledger","chemical","cup","cup","unknown"],"position":[99999,-12,"bad"]})); f.close()
 restored = State.new()
 check(restored.load_from("user://test-bad.json"),"Partial save loads safely")
 check(restored.found==["cup"],"Locked, duplicate, and unknown evidence filtered")
 check(restored.saved_position==[-75.0,88.0,1225.0],"Invalid spawn rejected")
 var world = World.new()
 root.add_child(world)
 var fly = Fly.new()
 root.add_child(fly)
 fly.active = false
 await physics_frame
 await process_frame
 var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
 check(world.hotspots.size()==15,"All fifteen physical/listening hotspots exist")
 # Continuous aisle across all three carriage boundaries.
 var query := PhysicsRayQueryParameters3D.create(Vector3(0,105,20),Vector3(0,105,2460),1)
 check(space.intersect_ray(query).is_empty(),"All three carriages connected by a clear aisle")
 # The tiny access duct must be clear even while the cabinet is locked.
 query = PhysicsRayQueryParameters3D.create(Vector3(65,11,1460),Vector3(104,11,1460),1)
 check(space.intersect_ray(query).is_empty(),"Cable duct actually admits the fly")
 query = PhysicsRayQueryParameters3D.create(Vector3(65,49,1460),Vector3(121,49,1460),1)
 check(not space.intersect_ray(query).is_empty(),"Cabinet door blocks bottle before release")
 world.unlock_cabinet()
 world.unlock_dispatch()
 await physics_frame
 await process_frame
 var approaches := {"cup":Vector3(-88,95,1250),"chemical":Vector3(101,50,1460),"ledger":Vector3(-100,96,2235),"note":Vector3(-102,90,285),"label":Vector3(102,94,1905),"log":Vector3(102,100,655)}
 for id in approaches:
  var target: Vector3 = world.hotspots[id].position
  query = PhysicsRayQueryParameters3D.create(approaches[id],target,1)
  var hit := space.intersect_ray(query)
  check(hit.is_empty() or hit.position.distance_to(target)<=4.0,"Physical clue approachable: "+id)
 # Real CharacterBody collision: descending onto a dining table must stop at its top.
 fly.position = Vector3(-76,100,1240)
 fly.velocity = Vector3(0,-100,0)
 var collision = fly.move_and_collide(Vector3(0,-30,0))
 check(collision!=null and fly.position.y>77,"Fly collides with the tabletop")
 fly.position = Vector3(-76,85,1240)
 check(fly.try_land() and fly.landed,"Fly lands on the tabletop")
 check(fly.try_land() and not fly.landed,"Fly takes off from landing")
 fly.position = Vector3(169,110,1200)
 collision = fly.move_and_collide(Vector3(20,0,0))
 check(collision!=null and fly.position.x<175,"Windows prevent escaping the train")
 world.queue_free()
 fly.queue_free()
 await process_frame
 for path in ["user://test-case.json","user://test-bad.json"]: DirAccess.remove_absolute(path)
 if failures.is_empty(): print("PASS: case logic, corrupted saves, all physical clues, connected carriages, fly-sized duct, tabletop landing, window collision")
 quit(0 if failures.is_empty() else 1)
