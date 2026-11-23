extends SceneTree
const World:=preload("res://scripts/world.gd")
const Heads:=preload("res://scripts/window_head_finish.gd")
const Low:=preload("res://scripts/window_lower_joinery.gd")
const Top:=preload("res://scripts/coach_coffers.gd")
func _initialize()->void: call_deferred("run")

func run()->void:
 var world:=World.new()
 root.add_child(world)
 await physics_frame
 await physics_frame
 var d:=world.get_world_3d().direct_space_state
 var issues:Array[String]=[]
 var form_count:Array[int]=[]
 var rooms:=world.find_children("FittedRoomFloor*","MeshInstance3D",true,false)
 var finishes:={}
 if rooms.size()!=14: issues.append("expected fourteen independently finished physical room floors")
 for inset:MeshInstance3D in rooms:
  var ground:=inset.get_aabb()
  var mat:=inset.material_override
  if not is_equal_approx(ground.size.x,300.0) or not is_equal_approx(ground.size.y,1.0) or not is_equal_approx(inset.global_position.y+ground.end.y,1.3):
   issues.append("floor art changed supporting geometry")
  if not mat is ShaderMaterial or not mat.shader.resource_path.ends_with("fitted_room_floors.gdshader"):
   issues.append("missing exact role finish in assembled train")
  else: finishes[mat.get_instance_id()]=true
 if finishes.size()!=14: issues.append("same material unintentionally reused across styled floors")
 for fold in [Heads.NAMES,Low.NAMES,Top.NAME]:
  var count:=0
  for tag in fold: count+=world.find_children(tag+"*","Node3D",true,false).size()
  form_count.append(count)
 if form_count != [32,26,3]: issues.append("pilot scopes changed "+str(form_count))
 var probe:=SphereShape3D.new()
 probe.radius=0.32
 for pose in [Vector3(339,149,346),Vector3(-344,150,1336),Vector3(345,170,2173),
  Vector3(0,228,143),Vector3(0,228,983),Vector3(0,228,1823),
  Vector3(222,168,217),Vector3(-224,161,1257),Vector3(242,186,1852),Vector3(-223,147,2306)]:
  var camera:=PhysicsShapeQueryParameters3D.new()
  camera.shape=probe
  camera.transform.origin=pose
  if not d.intersect_shape(camera).is_empty(): issues.append("held physical camera crosses existing solid geometry "+str(pose))
 # Normal sightseeing through real window and the physically contacting
 # replacement immediately above it. No cornice may carry into the glass.
 var found_heads:=0
 for car in range(3):
  var z:=float(Heads.ANCHORS[car])+73.0
  for side in [-1,1]:
   var high:=PhysicsRayQueryParameters3D.create(Vector3(side*470,266,z),Vector3(side*506,266,z))
   var sight:=PhysicsRayQueryParameters3D.create(Vector3(side*490,238,z),Vector3(side*505,238,z))
   var high_hit:=d.intersect_ray(high)
   var sight_hit:=d.intersect_ray(sight)
   if high_hit.is_empty() or not str(high_hit.collider.get_path()).contains(Heads.NAMES[car]): issues.append("cornice does not appear physically in free exterior bay "+str(car)+" "+str(side))
   else: found_heads+=1
   if not sight_hit.is_empty(): issues.append("existing window sightline visually/physically obstructed "+str(car)+" "+str(side))
 if issues.is_empty(): print("PASS: exact installed 32 window heads / 26 lower panels / 3 coffers, 14 floor role materials have identical support height, all 10 display cameras clear and "+str(found_heads)+" own rays above undisturbed glazing.")
 else:
  for issue in issues: push_error(issue)
 world.queue_free()
 await process_frame
 quit(0 if issues.is_empty() else 1)
