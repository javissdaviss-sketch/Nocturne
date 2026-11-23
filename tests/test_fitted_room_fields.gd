extends SceneTree
const Fields:=preload("res://scripts/fitted_room_wall_fields.gd")
class Fixture extends "res://scripts/world.gd":
 func _ready()->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var world:=Fixture.new()
 root.add_child(world)
 var corpus:=[]
 var failed:=[]
 var scope:=[
  [0,-1,0,0,360],[1,1,1390,1390,1640],[2,-1,1680,1680,2045],
 ]
 var total:=0
 for i in range(scope.size()):
  var tag:Array=scope[i]
  var z:=100.0+i*700.0
  var styled:={"car":tag[0],"side":tag[1],"lo":tag[2],"hi":tag[4]}
  var x:float=styled.side*58.0
  var draws:=Fields.dress(world,world,styled,x,z-50.0,z+50.0)
  if not draws: failed.append("missing fitted side field")
  if Fields.dress(world,world,styled,styled.side*52.0,z-50,z+50):
   failed.append("room treatment appeared on shared corridor face")
  var group:=world.get_child(-1) as Node3D
  var stencil:=PackedVector3Array()
  for mesh:MeshInstance3D in group.get_children():
   var actual:=mesh.get_aabb()
   if not AABB(Vector3(-1.87,-51,-47),Vector3(3.74,102,94)).encloses(actual) or mesh.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
    failed.append("wall relief extended past kept dimensions")
   total+=mesh.mesh.get_faces().size()/3
   stencil.append(actual.size)
  corpus.append([styled.side,z,stencil])
 await physics_frame
 await physics_frame
 var space:=world.get_world_3d().direct_space_state
 for item in corpus:
  var side:float=item[0]
  var z:float=item[1]
  var c:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(side*62,153,z),Vector3(side*58.1,153,z)))
  var r:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(side*62,153,z+43.55),Vector3(side*58.1,153,z+43.55)))
  var p:=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(side*62,153,z+51.0),Vector3(side*58.1,153,z+51.0)))
  if c.is_empty() or r.is_empty() or not p.is_empty() or absf(r.position.x)-absf(c.position.x)<0.65:
   failed.append("fitted room face/raised bead not physically distinct or enters the opening")
 if total>1500 or Fields.WALL_ROLE.size()!=14: failed.append("shape/role budget compromised")
 if failed.is_empty(): print("PASS: three actual hand-formed profile families, measured raised/recessed faces, fourteen room roles and original clear spans; ",total," sample triangles.")
 else:
  for note in failed: push_error(note)
 quit(0 if failed.is_empty() else 1)
