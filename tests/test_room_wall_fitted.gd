extends SceneTree
const World=preload("res://scripts/world.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
 var world:=World.new()
 root.add_child(world)
 await physics_frame
 await physics_frame
 var found:={}
 var errors:=[]
 var parts:=world.find_children("FittedRoomSideField_*","Node3D",true,false)
 for form:Node3D in parts:
  found[str(form.get_meta("fitted_room_wall_role",""))]=true
  var id:PackedStringArray=str(form.get_meta("fitted_room_wall_role","")).split(":")
  if id.size()!=3 or absf(absf(form.global_position.x)-58.25)>0.02 or form.get_child_count()!=3:
   errors.append("unexpected field position, scope or profile grouping")
  for relief:MeshInstance3D in form.get_children():
   if absf(relief.get_aabb().position.x)>1.9 or absf(relief.get_aabb().end.x)>1.9:
    errors.append("room-side field projects too far")
 if found.size()!=13 or found.has("1:1:990") or parts.size()<13 or parts.size()>26:
  errors.append("expected 13 installed relief roles and the original unchanged Tea wall")
 var sphere:=SphereShape3D.new()
 sphere.radius=0.32
 var sp:=world.get_world_3d().direct_space_state
 for view in [Vector3(181,129,238),Vector3(183,143,1311),Vector3(-147,146,2284)]:
  var query:=PhysicsShapeQueryParameters3D.new()
  query.shape=sphere
  query.transform.origin=view
  if not sp.intersect_shape(query).is_empty(): errors.append("held wall camera is physically blocked: "+str(view))
 if errors.is_empty(): print("PASS: 13 fitted room-side wall roles, original Tea wall retained, ",parts.size()," separately clear span groups, all 3 wall cameras physical.")
 else:
  for issue in errors: push_error(issue)
 world.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 1)
