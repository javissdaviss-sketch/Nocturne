extends SceneTree
const Fly:=preload("res://scripts/fly.gd")
const STEP:=1.0/60.0

func _initialize()->void:call_deferred("run")
func run()->void:
 var body:=StaticBody3D.new()
 root.add_child(body)
 body.position=Vector3(0,1.4,4)
 var solid:=CollisionShape3D.new()
 body.add_child(solid)
 var size:=BoxShape3D.new()
 size.size=Vector3(0.42,4.0,0.30)
 solid.shape=size
 var pilot:=Fly.new()
 root.add_child(pilot)
 pilot.set_physics_process(false)
 pilot.position=Vector3.ZERO
 pilot.active=true
 pilot.pitch=0.0
 pilot.yaw=0.0
 pilot.distance=9
 await physics_frame
 await physics_frame
 var errors:Array[String]=[]
 var space:=pilot.get_world_3d().direct_space_state
 pilot.update_camera(STEP)
 var trapped:=pilot.camera.global_position.z
 if trapped>=4.0 or not pilot.flight_eye_clear(space,pilot.camera.global_position):
  errors.append("camera did not contract immediately near solid rail")
 pilot.position.x=1.0
 pilot.update_camera(STEP)
 var opening:=pilot.camera.global_position.z
 if opening<=trapped or opening>=7.0:
  errors.append("walking clear causes sudden outward zoom")
 var previous:=opening
 for i in range(36):
  pilot.update_camera(STEP)
  var here:=pilot.camera.global_position.z
  if here<previous-0.000001 or not pilot.flight_eye_clear(space,pilot.camera.global_position):
   errors.append("recovery is nonmonotone/physically obstructed")
  previous=here
 if absf(previous-9.0)>0.045:
  errors.append("zoom did not recover to the exact requested distance")
 pilot.position.x=0.0
 pilot.update_camera(STEP)
 if pilot.camera.global_position.z>trapped+0.025:
  errors.append("returning into tight space delayed necessary retraction")
 pilot.position.x=1.0
 pilot.distance=6.0
 pilot.update_camera(STEP)
 if absf(pilot.camera.global_position.z-6.0)>0.001:
  errors.append("user scroll still needs to be immediate")
 pilot.position.x=0.0
 pilot.update_camera(STEP)
 pilot.position.x=45.0
 pilot.update_camera(STEP)
 if absf(pilot.camera.global_position.z-6.0)>0.001:
  errors.append("new save/teleport inherited stale old boom")
 print("Boom recovery first block=",trapped," first open=",opening," full=",previous," issues=",errors)
 pilot.queue_free()
 body.queue_free()
 quit(0 if errors.is_empty() else 1)
