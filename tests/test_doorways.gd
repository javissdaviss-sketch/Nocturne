extends SceneTree
const World = preload("res://scripts/world.gd")
var failed := false
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var world := World.new()
 root.add_child(world)
 await physics_frame
 await process_frame
 var space := world.get_world_3d().direct_space_state
 var layout := world.get_node("CompartmentLayout")
 for room in layout.rooms:
  var volume := BoxShape3D.new()
  volume.size = Vector3(170,210,float(room.width)-8.0)
  var query := PhysicsShapeQueryParameters3D.new()
  query.shape = volume
  query.collision_mask = 1
  query.transform.origin = Vector3(room.side*85,107,room.entry)
  var obstacles := space.intersect_shape(query,128)
  if not obstacles.is_empty():
   failed = true
   for hit in obstacles.slice(0,5): printerr("BLOCKED PORTAL ",room," / ",hit.collider.get_path()," at ",hit.collider.get_parent().global_position)
  var body := SphereShape3D.new()
  body.radius = 0.16
  query.shape = body
  for height in [2,20,45,75,105,150,210]:
   for offset in [-float(room.width)*0.5+6,0.0,float(room.width)*0.5-6]:
    for direction in [-1,1]:
     query.transform.origin = Vector3(0 if direction == 1 else room.side*170,height,room.entry+offset)
     query.motion = Vector3(room.side*170*direction,0,0)
     var sweep := space.cast_motion(query)
     if sweep[0]<0.999:
      failed = true
      printerr("BLOCKED FLY SWEEP ",room," height=",height," offset=",offset," direction=",direction)
 world.queue_free()
 await process_frame
 if not failed: print("PASS: all fourteen room entrances have clear full-height volumes and two-way fly sweeps")
 quit(1 if failed else 0)
