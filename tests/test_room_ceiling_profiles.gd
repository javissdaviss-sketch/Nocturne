extends SceneTree
const Roof:=preload("res://scripts/room_ceiling_joinery.gd")
class Shell extends "res://scripts/world.gd":
 func _ready()->void: pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var fixture:=Shell.new()
 root.add_child(fixture)
 var probes:=[]
 var fails:=[]
 var triangles:=0
 for room in [[0,-1,0,360],[1,1,840,990],[2,1,2045,2480]]:
  var body:=Roof.build(fixture,fixture,room[0],room[1],room[2],room[3])
  if not is_instance_valid(body) or body.get_child_count()!=3:
   fails.append("room has no carved inner roof")
   continue
  var z_len:float=room[3]-room[2]-42.0
  var bound:=AABB(Vector3(-126.001,-6.351,-z_len*0.5-0.001),Vector3(252.002,6.352,z_len+0.002))
  for part:MeshInstance3D in body.get_children():
   if not bound.encloses(part.get_aabb()) or part.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
    fails.append("ceiling projection or light budget changed")
   triangles+=part.mesh.get_faces().size()/3
  probes.append(body.global_position)
 await physics_frame
 await physics_frame
 var space:=fixture.get_world_3d().direct_space_state
 for center:Vector3 in probes:
  var c:=space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(0,-12,0),center+Vector3(0,0.4,0)))
  var shoulder:=INF
  var penetrates:=false
  for x in range(110,126):
   var lip:=space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(x,-12,0),center+Vector3(x,0.4,0)))
   var below:=space.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3(x,-12,0),center+Vector3(x,-6.8,0)))
   if not lip.is_empty(): shoulder=minf(shoulder,lip.position.y)
   penetrates=penetrates or not below.is_empty()
  if c.is_empty() or is_inf(shoulder) or penetrates or c.position.y-shoulder<1.5:
   fails.append("real coffer relief missing at "+str(center)+" "+str([c,shoulder,penetrates]))
 if Roof.RECIPES.size()!=14 or triangles>2100: fails.append("missing room role or excessive roof cost")
 if fails.is_empty():print("PASS: actual rounded inset ceiling planes and dropped fillets; preserved normal headroom, 14 role recipes; sample triangles ",triangles)
 else:
  for issue in fails:push_error(issue)
 quit(0 if fails.is_empty() else 1)
