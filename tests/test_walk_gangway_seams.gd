extends SceneTree
const State=preload("res://scripts/case_state.gd")
const _GameScript=preload("res://scripts/game.gd")
var game:Node
var problems:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,message:String)->void:
 if not ok:problems.append(message)
func wait_ticks(count:int=3)->void:
 for i in range(count):
  await physics_frame
  await process_frame
func tap(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=down
  root.push_input(e,true)
func hold(code:Key,pressed:bool)->void:
 var e:=InputEventKey.new()
 e.keycode=code
 e.physical_keycode=code
 e.pressed=pressed
 Input.parse_input_event(e)
 Input.flush_buffered_events()
func support_height(z:float,x:float=0.0)->float:
 var space:=game.get_world_3d().direct_space_state as PhysicsDirectSpaceState3D
 var ray:=PhysicsRayQueryParameters3D.create(Vector3(x,6.0,z),Vector3(x,-3.0,z),1)
 var hit:=space.intersect_ray(ray)
 return float(hit.position.y) if not hit.is_empty() else -99.0
func run()->void:
 if FileAccess.file_exists(State.PATH):
  push_error("Use a new synthetic profile")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await wait_ticks()
 var before_state:Array=game.state.found.duplicate()
 # 4 transitions from the existing low gangway or end strip to the
 # corridor runner. Start 8–11 cm from the runner seam, not in the lip.
 for route in [["link_06_07_into_06",801.0,-1.0,790.0],
  ["link_06_07_into_07",842.0,1.0,850.0],
  ["link_07_08_into_07",1642.0,-1.0,1630.0],
  ["link_07_08_into_08",1682.0,1.0,1690.0]]:
  var route_id:String=route[0]
  var from:float=route[1]
  var heading:float=route[2]
  var seam:float=route[3]
  var coach:=int(route_id.right(2))
  var low_z:=seam-heading*10.0
  var tread_list:Array=game.world.find_children("GangwayRunnerTransition_%02d_%d"%[coach,int(low_z)],"MeshInstance3D",true,false)
  var runner_list:Array=game.world.find_children("CoachCorridorFloor_%02d"%coach,"MeshInstance3D",true,false)
  check(tread_list.size()==1 and runner_list.size()==1,route_id+" visible tread or existing runner not found")
  if tread_list.size()==1 and runner_list.size()==1:
   var tread:MeshInstance3D=tread_list[0]
   var runner:MeshInstance3D=runner_list[0]
   var shape:=tread.mesh as BoxMesh
   var runner_shape:=runner.mesh as BoxMesh
   check(shape!=null and runner_shape!=null and absf(shape.size.x-runner_shape.size.x)<0.001
    and tread.material_override==runner.material_override,route_id+" visible width/runner finish changed")
   if shape!=null:
    for ratio in [0.1,0.3,0.5,0.7,0.9]:
     var measured:=tread.to_global(Vector3(0,shape.size.y*0.5,heading*(float(ratio)-0.5)*shape.size.z))
     check(absf(support_height(measured.z)-measured.y)<0.015,route_id+" collider does not coincide with rendered top facet")
  # Sample the actual collider under the visible identical material at both
  # edges and middle; only the original 10cm end strip is sloped.
  for lane in [-40.0,0.0,40.0]:
   for sample in [0.0,1.0,2.0,3.5,5.0,6.5,8.0,9.0,10.0]:
    var z:float=seam-heading*(10.0-float(sample))
    var height:float=support_height(z,lane)
    check(absf(height-0.14*float(sample))<0.03,route_id+" floor height discontinuity at "+str([lane,sample,height]))
  var low:=support_height(seam-heading*2.0)
  var high:=support_height(seam+heading*2.0)
  game.fly.restore_position(Vector3(0,6,from))
  game.fly.yaw=PI if heading>0 else 0.0
  game.fly.pitch=0.0
  await wait_ticks()
  tap(KEY_L)
  await wait_ticks()
  var landed:bool=game.fly.landed
  check(landed,route_id+" did not acquire the real connector floor")
  hold(KEY_W,true)
  await wait_ticks(235)
  hold(KEY_W,false)
  await wait_ticks()
  var stop:Vector3=game.fly.global_position
  var beyond:=heading*(stop.z-seam)
  print("GANGWAY_WALK ",route_id," support_near_cm=",low," runner_cm=",high,
   " endpoint_z=",stop.z," beyond_seam_cm=",beyond," landed=",game.fly.landed)
  check(beyond>=3.5 and game.fly.landed and absf(stop.x)<0.1,
   route_id+" ordinary grounded W caught before/at the threshold")
  var distance:float=absf(stop.z-from)
  check(absf(distance-235.0*5.0/60.0)<1.6,route_id+" ordinary walk speed changed: "+str(distance))
  # Reverse course using real W while still grounded; no scripted stepping.
  game.fly.yaw=0.0 if heading>0 else PI
  hold(KEY_W,true)
  await wait_ticks(275)
  hold(KEY_W,false)
  await wait_ticks()
  var down:Vector3=game.fly.global_position
  check(heading*(down.z-from)<-1.5 and game.fly.landed and absf(down.x)<0.1,
   route_id+" downhill reverse caught or lost ordinary walk")
  # The previously clear low flight keeps the real body out of the lining.
  game.fly.restore_position(Vector3(0,5,from))
  await wait_ticks()
  var air:KinematicCollision3D=game.fly.move_and_collide(Vector3(0,0,heading*24.0))
  check(air==null and absf(game.fly.global_position.z-(from+heading*24.0))<0.05,
   route_id+" same low airborne body sweep became obstructed")
 # The first 07 portals start close enough to the strip to merit a lower
 # corner check on both sides, rather than only the standard higher sweeps.
 for side in [-1.0,1.0]:
  game.fly.restore_position(Vector3(0,2.2,849.0))
  await wait_ticks()
  var corner:KinematicCollision3D=game.fly.move_and_collide(Vector3(side*84.0,0,0))
  check(corner==null and absf(game.fly.global_position.x-side*84.0)<0.05,
   "Low approach into first 07 doorway corner was obstructed on side "+str(side))
 check(game.mode=="play" and game.state.found==before_state,"A corridor crossing changed the case")
 print("GANGWAY_TRAJECTORY issues=",problems)
 game.queue_free()
 await process_frame
 quit(0 if problems.is_empty() else 4)
