extends SceneTree
## Actual L/W/Space sequence on both sides of both fitted gangways.
## Synthetic setup chooses legal starting positions; controls drive the chain.
const State=preload("res://scripts/case_state.gd")
var game:Node
var problems:Array[String]=[]
var prev_camera:=Vector3.ZERO
var prior_camera:=false
var max_camera_step:=0.0
var camera_checks:=0
func _initialize()->void:call_deferred("run")
func check(ok:bool,reason:String)->void:
 if not ok and not problems.has(reason):problems.append(reason)
func tick(n:int=1)->void:
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
func inspect_frames(n:int,label:String)->void:
 for i in range(n):
  await tick()
  var fly=game.fly
  var position:Vector3=fly.global_position
  var eye:Vector3=fly.camera.get_camera_transform().origin
  var space:PhysicsDirectSpaceState3D=fly.get_world_3d().direct_space_state
  check(fly.flight_eye_clear(space,eye),label+" optical volume overlapped")
  check(position.is_finite() and eye.is_finite(),label+" non-finite body or camera")
  check(position.distance_to(eye)<fly.distance*1.2+0.4,label+" camera departed body boom")
  if prior_camera:max_camera_step=maxf(max_camera_step,prev_camera.distance_to(eye))
  prev_camera=eye;prior_camera=true;camera_checks+=1
func run()->void:
 if FileAccess.file_exists(State.PATH):quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 tap(KEY_ENTER)
 await tick(3)
 var untouched:Array=game.state.found.duplicate()
 for coach in [6,7,8]:
  var surfaces:Array[Node]=game.world.find_children("CoachCorridorFloor_%02d"%coach,"MeshInstance3D",true,false)
  check(surfaces.size()==1,"Expected one existing render runner for coach "+str(coach))
  if surfaces.size()!=1:continue
  var runner:=surfaces[0] as MeshInstance3D
  var colliders:=runner.find_children("*","CollisionShape3D",true,false)
  check(colliders.size()==1,"Expected exactly one runner collider for coach "+str(coach))
  if colliders.size()!=1:continue
  var collider:=colliders[0] as CollisionShape3D
  var physical:=collider.shape as BoxShape3D
  var visible_mesh:=runner.mesh as BoxMesh
  check(physical!=null and visible_mesh!=null and physical.size.is_equal_approx(visible_mesh.size)
   and collider.global_transform.is_equal_approx(runner.global_transform),"Physical runner differs from rendered volume")
  check(runner.material_override==game.world.runner_finish(coach-6),"Rendered runner finish changed")
 var routes:Array=[]
 for origin in [["06_to_07",842.0,850.0,1.0],["07_to_06",801.0,790.0,-1.0],
  ["07_to_08",1682.0,1690.0,1.0],["08_to_07",1642.0,1630.0,-1.0]]:
  for lane in [-41.0,41.0]:
   routes.append(["%s/%s"%[origin[0],"left" if lane<0 else "right"],lane,origin[1],origin[2],origin[3]])
 for route in routes:
  var label:String=route[0]
  var side:float=signf(route[1])
  var heading:float=route[4]
  var turn:float=PI if heading>0 else 0.0
  var fly=game.fly
  fly.restore_position(Vector3(route[1],6,route[2]))
  fly.yaw=turn
  fly.pitch=0.0
  fly.distance=14.0
  await tick(3)
  tap(KEY_L)
  await tick(3)
  check(fly.landed,label+" failed to land on starting floor")
  prior_camera=false
  max_camera_step=0.0
  key(KEY_W,true)
  await inspect_frames(190,label+" walk")
  key(KEY_W,false)
  await tick(2)
  var ground:Vector3=fly.global_position
  check(fly.landed and heading*(ground.z-route[3])>2.0,label+" walked seam incompletely")
  tap(KEY_SPACE)
  await inspect_frames(7,label+" single hop")
  var airborne_peak:float=fly.global_position.y-ground.y
  check(fly.jumping and not fly.landed and airborne_peak>0.6,label+" single hop failed")
  await inspect_frames(31,label+" settle")
  check(fly.landed and not fly.jumping and fly.global_position.distance_to(ground)<0.15,label+" single hop did not settle")
  fly.yaw=turn-side*heading*0.22
  fly.pitch=0.08
  await inspect_frames(2,label+" new look")
  var takeoff_yaw:float=fly.yaw
  var takeoff_pitch:float=fly.pitch
  tap(KEY_SPACE)
  await inspect_frames(4,label+" takeoff first tap")
  tap(KEY_SPACE)
  check(not fly.jumping and not fly.landed,label+" deliberate double tap failed")
  var lift_start:Vector3=fly.global_position
  key(KEY_W,true)
  await inspect_frames(9,label+" flight from trim")
  key(KEY_W,false)
  var departure:Vector3=fly.global_position-lift_start
  check(heading*departure.z>6.0 and side*departure.x< -0.5,label+" horizontal departure disagreed with aimed turn "+str(departure))
  check(fly.yaw==takeoff_yaw and fly.pitch==takeoff_pitch,label+" camera adjusted intended heading")
  check(fly.position_is_clear(fly.global_position),label+" departure body overlapped")
  await inspect_frames(15,label+" normal chase")
  check(max_camera_step<6.0,label+" camera snapped excessively")
  print("WALK_HOP_FLY ",label," walked=",heading*(ground.z-route[3])," hop=",airborne_peak,
   " departure=",departure," chase_max_sample_step=",max_camera_step)
 check(game.mode=="play" and game.state.found==untouched,"route changed case or interaction mode")
 print("WALK_HOP_FLY_DONE camera_samples=",camera_checks," problems=",problems)
 game.queue_free()
 await process_frame
 quit(0 if problems.is_empty() else 4)
