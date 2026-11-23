extends SceneTree
class Fixture extends "res://scripts/world.gd":
 func _ready()->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var world:=Fixture.new()
 root.add_child(world)
 var original:=world.seat(Vector3(2700,0,0),Color.SEA_GREEN)
 var existing:=bounds(original)
 var tests:=["writing","crew","coast","engineering"]
 var seen:Dictionary={}
 var seats:Dictionary={}
 var errors:Array[String]=[]
 for i in range(4):
  var role:String=tests[i]
  var chair:=world.seat(Vector3(i*120.0,0,0),Color.SEA_GREEN,"berth-"+role)
  seats[role]=chair
  var support:=bounds(chair)
  if not existing.grow(0.2).encloses(support):
   errors.append(role+": chair grew beyond the accepted support/clearance envelope "+str(support))
  var faces:=0
  for component in chair.get_children():
   if component.get_meta("berth_chair_back",false):
    var form:=component as MeshInstance3D
    faces+=form.mesh.get_faces().size()
    if form.get_child_count()!=1:errors.append(role+": body is not physically formed")
  if faces==0:errors.append(role+": no authored body")
  seen[str(faces)]=true
 if seen.size()!=4: errors.append("four distinct desk-seat mesh fingerprints")
 await physics_frame
 await physics_frame
 var space:=world.get_world_3d().direct_space_state
 for test in [
  ["writing",Vector2(0,70),true],["writing",Vector2(0,49),false],
  ["crew",Vector2(0,66),true],["crew",Vector2(0,47),false],
  ["coast",Vector2(0,65),true],["coast",Vector2(5.4,65),false],
  ["engineering",Vector2(0,71),true],["engineering",Vector2(0,62),false]]:
  var chair:Node3D=seats[test[0]]
  var from:=chair.to_global(Vector3(test[1].x,test[1].y,15))
  var hit:=not space.intersect_ray(PhysicsRayQueryParameters3D.create(from,from+Vector3(0,0,18),1)).is_empty()
  if hit!=test[2]: errors.append(str(test[0])+": unexpected open/solid probe "+str(test[1]))
 print("Room desk chair role issues=",errors)
 world.queue_free()
 quit(0 if errors.is_empty() else 1)

func bounds(seat:Node3D)->AABB:
 var result:=AABB()
 var any:=false
 for piece:MeshInstance3D in seat.find_children("*","MeshInstance3D",true,false):
  var b: AABB=(seat.global_transform.affine_inverse()*piece.global_transform)*piece.get_aabb()
  result=result.merge(b) if any else b
  any=true
 return result
