extends SceneTree
class Stage extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var world := Stage.new()
 root.add_child(world)
 var orig := world.seat(Vector3(-100,0,0))
 var chair := world.seat(Vector3.ZERO,Color("4b6256"),"tea")
 var outline := chair.get_node("TeaChairSteamBentCrown") as MeshInstance3D
 var valid := bounds(orig).grow(0.1).encloses(bounds(chair))
 valid=valid and outline.mesh.get_faces().size()/3 in range(1150,1441)
 await physics_frame
 await physics_frame
 var space := world.get_world_3d().direct_space_state
 var hits := [Vector2(0,68),Vector2(0,89),Vector2(-25,70),Vector2(25,70)]
 for pair: Vector2 in hits:
  if ray_here(space,pair).is_empty(): valid=false
 for pair: Vector2 in [Vector2(5.7,69),Vector2(17.9,64),Vector2(-18.2,64)]:
  if not ray_here(space,pair).is_empty(): valid=false
 if valid: print("PASS: curved open-back tea chair physically blocks splats and crown, read-through gaps remain real, all surfaces fit original chair envelope.")
 else: push_error("Tea chair estimate, envelope, structural contact or open slit does not match")
 world.queue_free()
 quit(0 if valid else 1)

func ray_here(space: PhysicsDirectSpaceState3D,pt: Vector2) -> Dictionary:
 return space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(pt.x,pt.y,5),Vector3(pt.x,pt.y,36)))
func bounds(n: Node3D) -> AABB:
 var total:=AABB()
 var first:=true
 for child in n.get_children():
  if child is MeshInstance3D:
   var measure: AABB = child.transform*child.get_aabb()
   total=measure if first else total.merge(measure)
   first=false
 return total
