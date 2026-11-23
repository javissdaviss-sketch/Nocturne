extends SceneTree
const Head:=preload("res://scripts/window_head_finish.gd")
class Fixture extends "res://scripts/world.gd":
 func _ready()->void: pass

func _initialize()->void: call_deferred("run")
func run()->void:
 var scene:=Fixture.new()
 root.add_child(scene)
 var count:=0
 var failure: Array[String]=[]
 var forms:= []
 for car in range(3):
  var dims:=PackedInt32Array()
  for side in [-1,1]:
   var z:int=Head.ANCHORS[car]
   if not Head.draws_here(car,z) or Head.draws_here(car,z+170): failure.append("variant spills into other bays")
   Head.build(scene,scene,car,side,z)
   var profile:=scene.get_child(-1) as Node3D
   var room:=AABB(Vector3(-0.55,248,-77.1),Vector3(6.95,27,154.2))
   var finished:=AABB()
   for mesh:MeshInstance3D in profile.get_children():
    if not room.encloses(mesh.get_aabb()) or mesh.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: failure.append("new geometry exceeds kept bay: "+str(car)+" "+str(mesh.get_aabb()))
    dims.push_back(mesh.mesh.get_faces().size()/3)
    count+=mesh.mesh.get_faces().size()/3
    finished=mesh.get_aabb() if not finished.has_surface() else finished.merge(mesh.get_aabb())
   if not finished.has_volume() or finished.size.x<5.5: failure.append("profile isn't consistent physical relief")
   if car==0 and absf(profile.position.z+finished.end.z)>=355.0: failure.append("sleeper valance crosses partition")
  forms.append(str(dims))
 if count>7800 or forms[0]==forms[1] or forms[0]==forms[2] or forms[1]==forms[2]: failure.append("distinct head triangle budget failed: "+str(count))
 await physics_frame
 await physics_frame
 var space:=scene.get_world_3d().direct_space_state
 for car in range(3):
  var z:float=float(Head.ANCHORS[car])+73.0
  for side in [-1,1]:
   var head:=PhysicsRayQueryParameters3D.create(Vector3(side*476,266,z),Vector3(side*499,266,z))
   var glass:=PhysicsRayQueryParameters3D.create(Vector3(side*476,243,z),Vector3(side*505,243,z))
   if space.intersect_ray(head).is_empty() or not space.intersect_ray(glass).is_empty(): failure.append("missing physical cornice or trim across window")
 if failure.is_empty(): print("PASS: six real room-signed window heads, three silhouettes, ten cm fore/aft envelope, all glass sightlines clear; %d total triangles."%count)
 else:
  for problem in failure: push_error(problem)
 quit(0 if failure.is_empty() else 1)
