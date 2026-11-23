extends SceneTree
const World:=preload("res://scripts/world.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var train:=World.new()
 root.add_child(train)
 await physics_frame
 await physics_frame
 var installed:=train.find_children("FittedCabinCeiling_*","Node3D",true,false)
 var role:={}
 var fail:=[]
 for unit:Node3D in installed:
  role[unit.get_meta("ceiling_role")]=true
  if absf(unit.position.y-294.0)>0.002 or absf(absf(unit.position.x)-332.0)>0.003 or unit.get_child_count()!=3:
   fail.append("roof insert moves structural origin or combines expected materials")
  for g:MeshInstance3D in unit.get_children():
   if g.get_aabb().position.y<-6.36 or g.get_aabb().end.y>0.01:
    fail.append("physically intruding above/below kept roof treatment")
 if role.size()!=14 or installed.size()!=14: fail.append("exact outer room instance count wrong")
 var sphere:=SphereShape3D.new()
 sphere.radius=0.32
 var sp:=train.get_world_3d().direct_space_state
 for p in [Vector3(-205,225,202),Vector3(219,218,1127),Vector3(238,213,2258)]:
  var query:=PhysicsShapeQueryParameters3D.new()
  query.shape=sphere
  query.transform.origin=p
  if not sp.intersect_shape(query).is_empty(): fail.append("eye in physical roof fixture "+str(p))
 if fail.is_empty(): print("PASS: exact fourteen roof modules with their own materials, preserved structural anchors and three modeled fly-view clearances.")
 else:
  for problem in fail: push_error(problem)
 train.queue_free()
 await process_frame
 quit(0 if fail.is_empty() else 1)
