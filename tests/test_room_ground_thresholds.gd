extends SceneTree
## Actual L/W grounded passage, same support, material and original aperture, all 14.
const State=preload("res://scripts/case_state.gd")
var game:Node
var issues:Array[String]=[]
func _initialize()->void:call_deferred("run")
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
 key(code,true)
 key(code,false)
func height(x:float,z:float)->float:
 var space:=game.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
 var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,5,z),Vector3(x,-3,z),1)
 var hit:=space.intersect_ray(ray)
 return float(hit.position.y) if not hit.is_empty() else -90.0
func run()->void:
 if FileAccess.file_exists(State.PATH):quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await tick()
 var block_count:=0
 var fit_samples:=0
 var reverse_walking:=0
 var gear_doors:=0
 var observed_motion_ticks:=0
 var slow_ticks:=0
 var measurements:=0
 for room in game.guide_rooms():
  var side:float=room.side
  var z:float=room.entry
  var key_name:="RoomThreshold_%d_%d_%d"%[room.car+6,room.side,int(room.entry)]
  var tread:=game.world.find_child(key_name,true,false) as MeshInstance3D
  if tread==null:
   issues.append("Missing exact tread "+key_name)
   continue
  var box:=tread.mesh as BoxMesh
  var solid:Array[Node]=tread.find_children("*","CollisionShape3D",true,false)
  if solid.size()!=1 or not solid[0].shape is BoxShape3D or solid[0].shape.size!=box.size or not solid[0].global_transform.is_equal_approx(tread.global_transform) or absf(box.size.z-room.width)>0.01 or tread.material_override!=game.world.runner_finish(room.car):
   issues.append("Rendered and physical volumes differ "+key_name)
  gear_doors+=1
  for lane in [-float(room.width)*0.5+6,0.0,float(room.width)*0.5-6]:
   for x_metric in [55.0,55.5,57.0,58.0,59.0,60.0,61.0,63.0,64.0,65.0,67.0]:
    var expected:=clampf((65.0-float(x_metric))*0.14,0.0,1.4)
    var gauge:=height(side*float(x_metric),z+float(lane))
    if absf(gauge-expected)>0.03:issues.append("Seam height was discontinuous: "+str([key_name,lane,x_metric,gauge,expected]))
    fit_samples+=1
  var from:=64.0
  var start:Vector3=Vector3.ZERO
  var attempts:Array=[]
  for x in [64.0,65.0,67.0,69.0]:
   var y:=height(side*x,z)
   if y<-1.0:continue
   game.fly.restore_position(Vector3(side*x,y+1.5,z))
   game.fly.yaw=side*PI/2.0
   game.fly.pitch=0
   await tick()
   tap(KEY_L)
   await tick()
   start=game.fly.global_position
   attempts.append([x,y,start.y,game.fly.landed])
   if game.fly.landed and absf(start.x-side*x)<0.12:
    from=x
    break
  if not game.fly.landed or absf(start.x-side*from)>0.12:
   issues.append("Failed to land on valid approach "+str([side,z,attempts]))
   continue
  key(KEY_W,true)
  var route_ticks:=0
  for step in range(245):
   var before_x:float=side*game.fly.global_position.x
   var frame_before:=Engine.get_physics_frames()
   await tick(1)
   var counted:=maxi(1,Engine.get_physics_frames()-frame_before)
   route_ticks+=counted
   if before_x-side*game.fly.global_position.x<0.045*counted:slow_ticks+=1
  observed_motion_ticks+=route_ticks
  key(KEY_W,false)
  await tick()
  var stop:Vector3=game.fly.global_position
  var from_wall:=side*stop.x-55.0
  var below_room:=height(side*62,z)
  var below_aisle:=height(side*51,z)
  var caught:bool=not game.fly.landed or side*stop.x>=50.0
  if not caught:
   var ground_distance:=side*(start.x-stop.x)
   # Walking supplies (5, -3) cm/s. On an incline the velocity is
   # projected onto (1, 0.14); the original flat pace is still 5.
   const RISE_PER_CM:=0.14
   const WALK_X:=5.0
   const WALK_DOWN:=3.0
   var uphill_rate:=(WALK_X-WALK_DOWN*RISE_PER_CM)/(1.0+RISE_PER_CM*RISE_PER_CM)
   var ramp_run:=clampf(side*start.x-55.0,0.0,10.0)
   var expected_run:=float(route_ticks)*WALK_X/float(Engine.physics_ticks_per_second)-ramp_run*(WALK_X/uphill_rate-1.0)
   if absf(ground_distance-expected_run)>1.0:
    issues.append("Pace differs at "+key_name+": "+str(ground_distance))
   game.fly.yaw=-side*PI/2.0
   key(KEY_W,true)
   for step in range(288):
    var before_x:float=side*game.fly.global_position.x
    var frame_before:=Engine.get_physics_frames()
    await tick(1)
    var counted:=maxi(1,Engine.get_physics_frames()-frame_before)
    observed_motion_ticks+=counted
    if side*game.fly.global_position.x-before_x<0.045*counted:slow_ticks+=1
   key(KEY_W,false)
   await tick()
   if game.fly.landed and side*game.fly.global_position.x>=65.5:
    reverse_walking+=1
   else:
    issues.append("Reverse downhill did not reach original room floor at "+key_name+" ended "+str(game.fly.global_position))
  if caught:block_count+=1
  measurements+=1
  print("THRESHOLD side=",side," center=",z," floor_room=",below_room," floor_aisle=",below_aisle,
   " end_x=",stop.x," short_from_wall=",from_wall," caught=",caught)
 if slow_ticks>0:issues.append("Unexpected slowdown/stop ticks: "+str(slow_ticks))
 print("ROOM_THRESHOLDS_DONE measured=",measurements," caught=",block_count," fit_samples=",fit_samples," exact_parts=",gear_doors," retreat=",reverse_walking," motion_ticks=",observed_motion_ticks," slow_ticks=",slow_ticks," issues=",issues)
 game.queue_free()
 await process_frame
 quit(0 if measurements==14 and gear_doors==14 and reverse_walking==14 and block_count==0 and issues.is_empty() else 4)
