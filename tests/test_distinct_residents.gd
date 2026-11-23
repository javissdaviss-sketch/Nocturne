extends SceneTree
const Resident:=preload("res://scripts/resident_assets.gd")
const World:=preload("res://scripts/world.gd")
const Data:=preload("res://scripts/case_data.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var errors:Array[String]=[]
 var signatures:Dictionary={}
 var materials:Array[Array]=[
  ["engineer",Vector3(112,0,530),Color("697c80"),Color("292a2a")],
  ["steward",Vector3(113,0,1150),Color("863f54"),Color("242d30")],
  ["botanist",Vector3(112,0,2110),Color("a99068"),Color("b6b3a1")]]
 var only_fit:=OS.get_cmdline_user_args().has("--component-only")
 var all:=Node3D.new() if only_fit else World.new()
 root.add_child(all)
 var original:=Resident.build(all,all,Vector3(2700,0,0),Color("697c80"),Color("292a2a"))
 var expected:=bounds(original,original)
 var actual_nodes:Array[Node]=[]
 if not only_fit:
  for node:Node in all.find_children("TailoredResident*","Node3D",true,false):
   if node.has_meta("hotspot_id"):actual_nodes.append(node)
 for row in materials:
  var id:String=row[0]
  var start:Vector3=row[1]
  var actor:Node3D
  if only_fit:actor=Resident.build(all,all,start,row[2],row[3],id)
  else:
   for candidate in actual_nodes:
    if candidate.get_meta("hotspot_id")==id:
     actor=candidate
     break
  if not is_instance_valid(actor) or not actor.global_position.is_equal_approx(start):
   errors.append(id+": original body position changed")
   continue
  var shape:=bounds(actor,actor)
  # Conservative measure: the room/collision envelope never grows.
  if not expected.grow(0.15).encloses(shape):
   errors.append(id+": torso or face outside verified original bounds: "+str(shape))
  var head:=actor.get_node("SculptedHead") as Node3D
  var coat:=actor.get_node("FittedOuterCoat") as MeshInstance3D
  var hair:=head.get_node("ShapedHairCap") as MeshInstance3D
  if not is_equal_approx(head.position.y+head.scale.y*139,142.6):
   errors.append(id+": head no longer rooted in original neck contact")
  signatures[str([head.scale,coat.get_aabb(),hair.get_aabb()])]=true
  var frame:Node=head.get_node_or_null("FittedReadingFrames")
  if (frame!=null)!=(id=="botanist") or (frame!=null and frame.get_child_count()!=5):
   errors.append(id+": reading frames not physically complete on the intended head")
  if not only_fit:
   var descriptive:Array=Data.TALKS[id].point
   var p:=Vector3(descriptive[0],descriptive[1],descriptive[2])
   if all.hotspots[id].position!=p or actor.get_meta("resident_tailoring")!=id:
    errors.append(id+": case point or metadata changed")
 if signatures.size()!=3:errors.append("three actual cut/portrait combinations required")
 if not only_fit and actual_nodes.size()!=3:errors.append("resident roster changed")
 print("Role-authored residents issues=",errors," distinct=",signatures.size()," world=",not only_fit)
 all.queue_free()
 quit(0 if errors.is_empty() else 1)

func bounds(node:Node3D,parent:Node3D)->AABB:
 var cumulative:=AABB()
 var valid:=false
 for child:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
  var local:=parent.global_transform.affine_inverse()*child.global_transform
  var region:=local*child.get_aabb()
  cumulative=region if not valid else cumulative.merge(region)
  valid=true
 return cumulative
