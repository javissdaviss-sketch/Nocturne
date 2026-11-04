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
 var render_stats: Dictionary = world.get_meta("interior_batch_stats")
 check(render_stats.sources > render_stats.batches,"Static rendering uses fewer batches than source meshes")
 check(world.cabinet_door.visible and world.drawer.visible,"Puzzle doors keep independent visuals before unlocking")
 # Continuous aisle across all three carriage boundaries.
 var query := PhysicsRayQueryParameters3D.create(Vector3(0,105,20),Vector3(0,105,2460),1)
 check(space.intersect_ray(query).is_empty(),"All three carriages connected by a clear aisle")
 # Every compartment has a physical wall, open portal and a full-width floor.
 var layout := world.get_node("CompartmentLayout")
 check(layout.rooms.size()==14,"Fourteen enclosed rooms across three carriages")
 for room in layout.rooms:
  var side: int = room.side
  var entry: float = room.entry
  query = PhysicsRayQueryParameters3D.create(Vector3(0,105,entry),Vector3(side*75,105,entry),1)
  check(space.intersect_ray(query).is_empty(),"Room doorway connects to corridor: "+str(room))
  var wall_z: float = room.lo+8
  query = PhysicsRayQueryParameters3D.create(Vector3(0,150,wall_z),Vector3(side*70,150,wall_z),1)
  check(not space.intersect_ray(query).is_empty(),"Room wall blocks flight outside doorway")
  query = PhysicsRayQueryParameters3D.create(Vector3(side*300,10,entry),Vector3(side*300,-10,entry),1)
  check(not space.intersect_ray(query).is_empty(),"Expanded room has a solid floor")
 # A save from an outer room remains valid after restarting.
 s.saved_position = [300.0,120.0,200.0]
 s.save_to("user://test-case.json")
 restored = State.new()
 restored.load_from("user://test-case.json")
 check(restored.saved_position==[300.0,120.0,200.0],"Expanded-room save positions survive reload")
 fly.position = Vector3(300,180,200)
 fly.active = true
 fly._physics_process(0.0)
 fly.active = false
 check(fly.position.x>290,"Flight controller accepts the expanded room width")
 # The access duct admits the fly above its physical cable while locked.
 query = PhysicsRayQueryParameters3D.create(Vector3(65,12,1460),Vector3(102,12,1460),1)
 check(space.intersect_ray(query).is_empty(),"Cable duct actually admits the fly")
 query = PhysicsRayQueryParameters3D.create(Vector3(65,49,1460),Vector3(121,49,1460),1)
 check(not space.intersect_ray(query).is_empty(),"Cabinet door blocks bottle before release")
 world.unlock_cabinet()
 world.unlock_dispatch()
 check(not world.cabinet_door.visible and not world.drawer.visible,"Puzzle visuals disappear when their colliders release")
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
 fly.position = Vector3(509,110,1200)
 collision = fly.move_and_collide(Vector3(20,0,0))
 check(collision!=null and fly.position.x<515,"Windows prevent escaping the train")
 # New prop: real gaps between garden-crate slats admit the 6 mm fly.
 query = PhysicsRayQueryParameters3D.create(Vector3(-154,10,2421),Vector3(-146.5,10,2421),1)
 check(space.intersect_ray(query).is_empty(),"Garden crate has real gaps between slats")
 query = PhysicsRayQueryParameters3D.create(Vector3(-154,6,2421),Vector3(-144,6,2421),1)
 check(not space.intersect_ray(query).is_empty(),"Garden crate wooden slats are solid")
 fly.position = Vector3(-148.5,35,2421)
 collision = fly.move_and_collide(Vector3(0,-20,0))
 check(collision!=null and fly.position.y>24.8,"Fly can perch on the garden crate rim")
 world.queue_free()
 fly.queue_free()
 await process_frame
 for path in ["user://test-case.json","user://test-bad.json"]: DirAccess.remove_absolute(path)
 if failures.is_empty(): print("PASS: case logic, corrupted saves, all physical clues, connected carriages, fly-sized duct, tabletop landing, window collision, garden crate gaps and perching")
 quit(0 if failures.is_empty() else 1)
