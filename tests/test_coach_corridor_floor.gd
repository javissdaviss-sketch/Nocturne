extends SceneTree
class NoWorld extends "res://scripts/world.gd":
 func _ready()->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var train:=NoWorld.new()
 root.add_child(train)
 var names:Dictionary={}
 var errors:Array[String]=[]
 for i in range(3):
  train.carriage(i)
  var part:=train.get_node("CoachCorridorFloor_%02d"%(i+6)) as MeshInstance3D
  var mat:=part.material_override as ShaderMaterial
  var pos:=Vector3(0,0.8,float(i)*840.0+400.0)
  if not part.position.is_equal_approx(pos) or not part.mesh.size.is_equal_approx(Vector3(110,1.2,780)):
   errors.append("carriage support geometry changed")
  if not is_instance_valid(mat) or mat.get_shader_parameter("floor_center")!=Vector2(pos.x,pos.z) or mat.get_shader_parameter("style_kind")!=[0,1,3][i]:
   errors.append("floor role does not match appropriate coach")
  if mat.get_shader_parameter("coach_seam_weight")<=0.0 or mat.get_shader_parameter("coach_seam_weight")>0.75:
   errors.append("wrong coach-local threshold inlay opacity")
  names[mat.resource_name]=true
 await physics_frame
 await physics_frame
 var space:=train.get_world_3d().direct_space_state
 for i in range(3):
  for p in [Vector2(0,100),Vector2(-38,425),Vector2(32,600)]:
   var from:=Vector3(p.x,2.5,840.0*float(i)+p.y)
   var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,from-Vector3.UP*2.4,1))
   if hit.is_empty() or absf(hit.position.y-1.4)>0.007:
    errors.append("changed physical ground level "+str(from))
 if names.size()!=3:errors.append("coach identities missing")
 print("Coach corridor floors issues=",errors)
 train.queue_free()
 quit(0 if errors.is_empty() else 1)
