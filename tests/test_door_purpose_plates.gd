extends SceneTree
const World:=preload("res://scripts/world.gd")
const Signs:=preload("res://scripts/door_purpose_plates.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var train:=World.new()
 root.add_child(train)
 await physics_frame
 await physics_frame
 var layout:=train.get_node("CompartmentLayout")
 var issues:Array[String]=[]
 var names:Dictionary={}
 var checked:=0
 var space:=train.get_world_3d().direct_space_state
 if layout.find_children("Doormark_*","Node3D",false,false).size()!=14:
  issues.append("not exactly one nameplate per actual room")
 for spec in layout.rooms:
  var car:int=spec.car
  var side:int=spec.side
  var lo:float=spec.lo
  var mount:=layout.get_node("Doormark_%d_%d_%d"%[car,side,int(lo)]) as Node3D
  var sign:=mount.get_node("RoomPurposeLabel") as Label3D
  var material:=mount.get_node("FittedNameplate") as MeshInstance3D
  var bound:=material.global_transform*material.get_aabb()
  var target_center:=Vector3(side*48.42,114,spec.parked)
  if not mount.global_position.is_equal_approx(target_center):
   issues.append("stage does not attach to actual parked door")
  if minf(absf(bound.position.x),absf(bound.end.x))<47.7 or    (absf(spec.parked-spec.entry)-bound.size.z*0.5)<float(spec.width)*0.5+6.0:
   issues.append("door plate crossed reading corridor or opening")
  if not sign.global_basis.z.is_equal_approx(Vector3(-side,0,0)) or sign.double_sided:
   issues.append("incorrect physical nameplate orientation")
  if sign.text!=Signs.PURPOSE[Signs.key(car,side,lo)]:
   issues.append("wrong room-specific wayfinding name")
  names[sign.text]=true
  var start:=Vector3(side*20,114,spec.parked)
  var eye:=target_center
  var seen:=space.intersect_ray(PhysicsRayQueryParameters3D.create(start,eye,1))
  if seen.is_empty() or absf(absf(seen.position.x)-47.86)>0.12:
   issues.append("parked door plaque did not make a visible, physical front "+sign.text)
  checked+=1
 if names.size()!=14 or checked!=14:issues.append("duplicated names")
 print("Physical purpose plates=",checked," issues=",issues)
 train.queue_free()
 quit(0 if issues.is_empty() else 1)
