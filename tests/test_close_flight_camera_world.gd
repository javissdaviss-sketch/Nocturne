extends SceneTree
const Fly:=preload("res://scripts/fly.gd")
const World:=preload("res://scripts/world.gd")
const Lift:=preload("res://scripts/seed_lift.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var train:=World.new()
 root.add_child(train)
 var f:=Fly.new()
 train.add_child(f)
 f.active=true
 f.set_physics_process(false)
 await physics_frame
 await physics_frame
 var space:=train.get_world_3d().direct_space_state
 var failures:Array[String]=[]
 var cases:Array[Vector3]=[Vector3(-75,88,1225),Vector3(-19,28,292),
  Vector3(19,28,1132),Vector3(-19,28,1972),Vector3(-54,105,55),
  Vector3(54,105,889),Vector3(104,115,1588),Vector3(100,48,1460)]
 var passage:Array[Vector3]=[]
 for p in Lift.INTAKE_PATH:
  var point:Vector3=train.seed_lift.to_global(p)
  passage.append(point)
  cases.append(point)
 f.global_position=passage[0]
 for p in passage.slice(1):
  if f.move_and_collide(p-f.global_position)!=null or f.global_position.distance_to(p)>0.08:
   failures.append("fly body transfer changed "+str(p))
 var tests:=0
 var blocked_legacy:=0
 var examples:Array[Array]=[]
 var requests:Array[Vector3]=[]
 for p in cases:
  f.global_position=p
  if not f.position_is_clear(p):
   failures.append("chosen test location is blocked: "+str(p))
   continue
  for zoom in [3.0,14.0,28.0]:
   f.distance=zoom
   for i in range(8):
    f.yaw=float(i)*TAU/8.0
    for tilt in [-1.0,0.0,0.91]:
     f.pitch=tilt
     var forward:=Vector3(-sin(f.yaw)*cos(tilt),sin(tilt),-cos(f.yaw)*cos(tilt))
     var origin:=p+Vector3.UP*0.4
     var previous:=legacy(space,origin,origin-forward*zoom+Vector3.UP*zoom*0.17)
     if not f.flight_eye_clear(space,previous):
      blocked_legacy+=1
      if examples.size()<6: examples.append([p,zoom,i,tilt,previous])
     f.update_camera(1.0/60.0)
     if not f.flight_eye_clear(space,f.camera.get_camera_transform().origin):
      failures.append("flight optical overlap at "+str([p,zoom,i,tilt]))
     if not f.global_position.is_equal_approx(p):
      failures.append("camera moved its actor")
     tests+=1
   if zoom==14.0:
    requests.append(p+Vector3(0,0.4,0))
    requests.append(p+Vector3(6.3,2.8,12.4))
 var moved:=0
 var movement_routes:Array[Array]=[
  [Vector3(-7,105,55),Vector3(-92,105,55),Vector3(-7,105,55)],
  [Vector3(7,105,889),Vector3(92,105,889),Vector3(7,105,889)]
 ]
 var enclosed:Array[Vector3]=passage.duplicate()
 var return_route:Array[Vector3]=passage.duplicate()
 return_route.reverse()
 enclosed.append_array(return_route.slice(1))
 movement_routes.append(enclosed)
 for route in movement_routes:
  f.global_position=route[0]
  f.reset_movement()
  f.pitch=-0.24
  f.distance=24.0
  for i in range(1,route.size()):
   var segment_from:Vector3=route[i-1]
   var segment_to:Vector3=route[i]
   var delta:=segment_to-segment_from
   f.yaw=atan2(-delta.x,-delta.z)
   var steps:=maxi(1,int(ceil(delta.length()/1.25)))
   for j in range(1,steps+1):
    var next:=segment_from.lerp(segment_to,float(j)/steps)
    if f.move_and_collide(next-f.global_position)!=null or f.global_position.distance_to(next)>0.08:
     failures.append("real camera motion route physically blocked "+str(next))
     break
    f.update_camera(1.0/60.0)
    if not f.flight_eye_clear(space,f.camera.get_camera_transform().origin):
     failures.append("eye overlaps during actual motion "+str(next))
    moved+=1
 # Local physics solve time only. Two equal warm loops in this exact scene
 # don't constitute Windows, graphics-frame-rate or continuous play timing.
 var samples:=2000
 var old_micros:=0
 var new_micros:=0
 if not requests.is_empty():
  for pass_id in range(4):
   var mark:=Time.get_ticks_usec()
   for j in range(samples):
    var i: int=(j%(requests.size()/2))*2
    var from:=requests[i]
    var to:=requests[i+1]
    f.global_position=from-Vector3.UP*0.4
    if pass_id%2==0: legacy(space,from,to)
    else: f.clear_camera(from,to)
   if pass_id%2==0:old_micros+=Time.get_ticks_usec()-mark
   else:new_micros+=Time.get_ticks_usec()-mark
 print("Actual clear optics tests=",tests," collision-swept movement samples=",moved," old overlapping=",blocked_legacy," cases=",examples," issues=",failures,
  " local physics us/query old=",float(old_micros)/(samples*2)," swept=",float(new_micros)/(samples*2))
 train.queue_free()
 quit(0 if failures.is_empty() and tests>=750 and moved>=300 else 1)

func legacy(space:PhysicsDirectSpaceState3D,from:Vector3,to:Vector3)->Vector3:
 var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))
 if not hit.is_empty():return hit.position+hit.normal*0.2
 return to
