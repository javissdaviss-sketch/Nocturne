extends SceneTree
const World=preload("res://scripts/world.gd")
const Vase=preload("res://scripts/opaline_vase.gd")
class LightScene extends Node3D:
 func mesh_obj(parent:Node3D,mesh:Mesh,point:Vector3,_color:Color)->MeshInstance3D:
  var node:=MeshInstance3D.new()
  node.mesh=mesh
  parent.add_child(node)
  node.position=point
  return node
func _initialize()->void:call_deferred("run")
func run()->void:
 var errors:Array[String]=[]
 var repeated:=OS.get_cmdline_user_args().has("--component-only")
 var source:Node3D=LightScene.new() if repeated else World.new()
 root.add_child(source)
 var vase:Node3D=Vase.fit(source) if repeated else source.get_node_or_null("MeridianOpalineVase")
 if not is_instance_valid(vase):
  push_error("Missing the single central vase")
  quit(2);return
 var max_radius:=0.0
 var upper:=0.0
 var triangles:=0
 var lower:=INF
 var omit:Array[RID]=[]
 for part:MeshInstance3D in vase.find_children("*","MeshInstance3D",false,false):
  for point:Vector3 in part.mesh.get_faces():
   max_radius=maxf(max_radius,Vector2(point.x,point.z).length())
   lower=minf(lower,point.y)
   upper=maxf(upper,point.y)
  triangles+=part.mesh.get_faces().size()/3
  for physical:StaticBody3D in part.find_children("*","StaticBody3D",false,false):
   omit.append(physical.get_rid())
  if part.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
   errors.append("Vase must not create hard shadow patterns on the evidence")
 if max_radius>3.0001 or not is_zero_approx(lower) or upper<18.5 or upper+Vase.AXIS.y>96.001:
  errors.append("Former vase envelope or deck contact changed")
 if vase.find_children("*","Light3D",true,false).size()>0 or triangles<1000 or triangles>3400:
  errors.append("Unexpected light/triangle budget")
 if not repeated:
  await physics_frame
  await physics_frame
  var space:=source.get_world_3d().direct_space_state
  var support_query:=PhysicsRayQueryParameters3D.create(Vase.AXIS+Vector3.UP*0.9,Vase.AXIS+Vector3.DOWN*1,1,omit)
  var support:=space.intersect_ray(support_query)
  if omit.size()!=2:errors.append("All visible vase parts should be real collision/contact")
  var foot_gap:=INF
  if not support.is_empty():foot_gap=Vase.AXIS.y-support.position.y
  if foot_gap>0.001 or foot_gap<-0.05:
   errors.append("The weighted foot is not actually seated on the table")
  # Probe the actual vessel envelope rather than the single lathe apex
  # beneath the seated flower stems. Side rays sample the full fluted glass.
  var contact_rays:=0
  for offset in [Vector3(1,0,0),Vector3(-1,0,0),Vector3(0,0,-1),Vector3(0,0,1)]:
   var axis:=Vase.AXIS+Vector3.UP*7.85
   var q:=PhysicsRayQueryParameters3D.create(axis+offset*4.2,axis+offset*0.45,1)
   q.hit_back_faces=true
   var actual_contact:=space.intersect_ray(q)
   if not actual_contact.is_empty() and vase.is_ancestor_of(actual_contact.collider):
    contact_rays+=1
   else:
    print("Non-vase side contact ",offset," ",actual_contact.get("collider")," ",actual_contact.get("position"))
  var fly_sphere:=SphereShape3D.new()
  fly_sphere.radius=0.16
  var sweep:=PhysicsShapeQueryParameters3D.new()
  sweep.shape=fly_sphere
  sweep.collision_mask=1
  sweep.transform.origin=Vase.AXIS+Vector3.UP*7.85+Vector3.RIGHT*4.2
  sweep.motion=Vector3.LEFT*4.0
  var vase_safe:=space.cast_motion(sweep)
  if vase_safe[0]>=0.999 or contact_rays<4:
   errors.append("The authored vessel cannot provide real local contacts")
  print("Meridian physical vase cone ",contact_rays," vessel rays; player capsule ",vase_safe)
  var lip_axis:=Vase.AXIS+Vector3(0.62,19.7,0.62)
  var well_query:=PhysicsRayQueryParameters3D.create(lip_axis,lip_axis+Vector3.DOWN*4.0,1)
  well_query.hit_back_faces=true
  var recess:=space.intersect_ray(well_query)
  if recess.is_empty() or not vase.is_ancestor_of(recess.collider) or absf(recess.position.y-(Vase.AXIS.y+17.68))>0.05:
   errors.append("The visibly hollow rolled mouth has no real recessed stem support")
  var sprouts:=0
  for parts:MultiMeshInstance3D in source.find_children("Details_*","MultiMeshInstance3D",true,false):
   if not str(parts.get_meta("detail_batch_key","")).begins_with("cylinder536e4aff"):continue
   for t:Transform3D in parts.multimesh.get_meta("solid_geometry_transforms",[]):
    var bottom:Vector3=t.origin-t.basis.y*0.5
    var tip:Vector3=t.origin+t.basis.y*0.5
    var original_center:=Vector3(-127,96,1278)
    if absf(bottom.x-original_center.x)<0.02 and absf(bottom.z-original_center.z)<0.02 and absf(bottom.y-94.95)<0.02:
     for j in range(3):
      var original_tip:=original_center+Vector3((j-1)*3.0,8+float(j%2)*3,(j-1)*1.5)
      if tip.distance_to(original_tip)<0.03:sprouts+=1
  if sprouts!=3:errors.append("Existing flower tips moved or are not physically seated below the vase mouth")
  print("Meridian original blooms ",sprouts," with buried anchors")
  var cue_check:=PhysicsShapeQueryParameters3D.new()
  cue_check.shape=fly_sphere
  cue_check.collision_mask=1
  cue_check.transform.origin=Vector3(-75,88,1225)
  cue_check.motion=Vector3(-88,95,1250)-cue_check.transform.origin
  if space.cast_motion(cue_check)[0]<0.999:
   errors.append("Original approach from initial fly position to the cup is blocked")
  print("Meridian real contact ray foot_gap_cm=",foot_gap)
 print("Meridian opaline issues=",errors," triangles=",triangles," radius=",max_radius," y=",Vector2(lower,upper)," real_world=",not repeated)
 source.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 1)
