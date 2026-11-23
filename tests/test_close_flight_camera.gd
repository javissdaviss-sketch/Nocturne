extends SceneTree
const Fly:=preload("res://scripts/fly.gd")
const EYE:=0.12
func _initialize()->void:call_deferred("run")
func make_block(center:Vector3,size:Vector3)->StaticBody3D:
 var body:=StaticBody3D.new()
 root.add_child(body)
 body.position=center
 var piece:=CollisionShape3D.new()
 var box:=BoxShape3D.new()
 box.size=size
 piece.shape=box
 body.add_child(piece)
 return body

func run()->void:
 var f:=Fly.new()
 root.add_child(f)
 f.set_physics_process(false)
 f.position=Vector3.ZERO
 # A ceiling leaves a legitimate body passage at its true 0.16 cm radius,
 # but it intersects the old camera-only position 0.4 cm above the body.
 make_block(Vector3(0,0.59,0),Vector3(8.0,0.50,24.0))
 # Thin chair rail brushes the side of the real optical eye. Its geometry
 # deliberately misses the nominal center ray by 0.06 cm.
 make_block(Vector3(10.10,0,4),Vector3(0.08,0.70,0.18))
 # A solid square post provides the ordinary retract case.
 make_block(Vector3(20,0,4),Vector3(0.18,0.70,0.18))
 await physics_frame
 await physics_frame
 var no_head_penetration:=f.clear_camera(Vector3(0,0.4,0),Vector3(0,0.42,7))
 var rail:=f.clear_camera(Vector3(10,0,0),Vector3(10,0,9))
 var post:=f.clear_camera(Vector3(20,0,0),Vector3(20,0,9))
 var open:=f.clear_camera(Vector3(30,0,0),Vector3(30,0,9))
 var errors:Array[String]=[]
 if not eye_is_clear(f,no_head_penetration) or no_head_penetration.y>0.22:
  errors.append("escaping a requested boom anchored in a low ceiling")
 if rail.z>=4.0 or not eye_is_clear(f,rail):
  errors.append("camera eye swept over a rail the old zero-width ray misses")
 if post.z>=4.0 or not eye_is_clear(f,post):
  errors.append("standard centered blocker does not retract correctly")
 if not open.is_equal_approx(Vector3(30,0,9)):
  errors.append("clear spaces no longer preserve requested zoom")
 print("Close active camera issues=",errors," positions=",no_head_penetration,"/",rail,"/",post,"/",open)
 f.queue_free()
 quit(0 if errors.is_empty() else 1)

func eye_is_clear(node:Node3D, eye:Vector3)->bool:
 var q:=PhysicsShapeQueryParameters3D.new()
 var shape:=SphereShape3D.new()
 shape.radius=EYE
 q.shape=shape
 q.transform.origin=eye
 q.collision_mask=1
 return node.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty()
