extends SceneTree
const Sideboards:=preload("res://scripts/window_lower_joinery.gd")
class Demo extends "res://scripts/world.gd":
 func _ready()->void: pass
func _initialize()->void: call_deferred("run")
func run()->void:
 var display:=Demo.new()
 root.add_child(display)
 var faults: Array[String]=[]
 var models: Array[Node3D]=[]
 var faceted := []
 for car in range(3):
  var counts := PackedInt32Array()
  for side in [-1,1]:
   var z: float=110+car*830
   var object:=Sideboards.build(display,display,car,side,z)
   models.append(object)
   if car==1:
    var m:ShaderMaterial=object.get_node("RealBacking").material_override
    var axis:Vector3=m.get_shader_parameter("strand_world")
    var face:=object.global_basis*Vector3.FORWARD
    if absf(axis.dot(face))>0.06 or axis!=Vector3.BACK: faults.append("visible boards use end grain instead of correctly fitting physical length")
   for mesh:MeshInstance3D in object.get_children():
    if not AABB(Vector3(-34.01,-28,-3.02),Vector3(68.02,56,3.74)).encloses(mesh.get_aabb()):
     faults.append("projecting beyond sideboard envelope "+str(mesh.get_aabb()))
    var n:=mesh.mesh.get_faces().size()/3
    if n<18 or n>480 or mesh.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: faults.append("increased panel draw/mesh budget unexpectedly")
    counts.append(n)
  faceted.append(str(counts))
 if faceted[0]==faceted[1] or faceted[1]==faceted[2] or faceted[0]==faceted[2]: faults.append("three shapes need different real cross-sections")
 await physics_frame
 await physics_frame
 var space:=display.get_world_3d().direct_space_state
 for model in models:
  for y in [-8.3,6.75]:
   var a:=model.to_global(Vector3(0,y,-5.0))
   var b:=model.to_global(Vector3(0,y,0.2))
   var q:=PhysicsRayQueryParameters3D.create(a,b)
   var hit:=space.intersect_ray(q)
   if hit.is_empty():
    faults.append("fitting is not solid")
    continue
   var front:=model.to_local(hit.position).z
   if model.name.begins_with("Garden"):
    if absf(y+8.3)<0.1 and absf(front+0.75)>0.09: faults.append("garden panel's real gap filled")
    if absf(y-6.75)<0.1 and front>=-1.81: faults.append("garden panel louvre not distinct from backing")
 for car in range(3):
  var lo: int=[0,990,2045][car]
  if Sideboards.pilot(car,lo+150,lo+96): faults.append("wrong bay chosen")
 if faults.is_empty(): print("PASS: three shallow physical window sideboards, real vent gaps/contact, no new cast surfaces and kept width/height.")
 else:
  for issue in faults: push_error(issue)
 quit(0 if faults.is_empty() else 1)
