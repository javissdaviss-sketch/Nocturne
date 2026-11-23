extends SceneTree
const Vessel:=preload("res://scripts/nursery_vessel_forms.gd")
const F:=preload("res://scripts/garden_fixture_geometry.gd")
const Living:=preload("res://scripts/botanical_collection.gd")
const World:=preload("res://scripts/world.gd")
const MaterialLibrary:=preload("res://scripts/material_library.gd")
class Isolated extends "res://scripts/world.gd":
 func _ready()->void: pass
func _initialize()->void: call_deferred("run")
func run()->void:
 var fixture:=Isolated.new()
 root.add_child(fixture)
 var families:=["orchid","potting","heritage","reserve"]
 var errors:Array[String]=[]
 var new_cost:=0
 var old_cost:=0
 var role:Dictionary={}
 for family in families:
  for size in [Vector2(30,11),Vector2(23,14),Vector2(26,18)]:
   var old:=F.pot_mesh(size.x,size.y)
   var m:=Vessel.modeled(family,size.x,size.y)
   role[family]=str(Vessel.profile_path(family,30,11))
   if not old.get_aabb().grow(0.035).encloses(m.get_aabb()):
    errors.append(family+": touched old outer volume")
   old_cost+=old.get_faces().size()
   new_cost+=m.get_faces().size()
  var sample:=Living.new()
  fixture.add_child(sample)
  sample.role=family
  sample.pot(Vector3.ZERO,26,18,true)
  sample.finish_batches()
  var tested_finish:=MaterialLibrary.Finish.TERRACOTTA if family=="potting" else MaterialLibrary.Finish.CERAMIC
  var part_count:=0
  for part:MultiMeshInstance3D in sample.get_children():
   if str(part.get_meta("detail_batch_key","")).begins_with("turned_pot_"):
    part_count+=1
    if part.material_override.get_meta("crafted_finish",-1)!=tested_finish:
     errors.append(family+": actual installed vessel material not from authored family")
  if part_count!=1:errors.append(family+": exactly one real installed vessel shape expected")
  sample.free()
  var support:=Living.seated_pot_position(Vector3(430,0,1752),Vector3(377,0,1745))
  if absf(support.y+0.2-F.soil_height(53,7,190,52))>0.001:
   errors.append("unseated floor")
  var n:=fixture.mesh_obj(fixture,Vessel.modeled(family,30,11),Vector3(families.find(family)*66.0,0,0),Color.WHITE,true) as MeshInstance3D
  n.name=family
 if role.values().size()!=4: errors.append("four profile families required")
 for a in families:
  for b in families:
   if a!=b and role[a]==role[b]: errors.append(a+" matches "+b)
 if new_cost>old_cost*1.45: errors.append("more radial complexity than intended")
 await physics_frame
 await physics_frame
 var space:=fixture.get_world_3d().direct_space_state
 for n:MeshInstance3D in fixture.get_children():
  var c:=n.global_position
  var q:=PhysicsRayQueryParameters3D.create(c+Vector3(0.18,16,0),c+Vector3(0.18,0.3,0))
  var inside:=space.intersect_ray(q)
  q=PhysicsRayQueryParameters3D.create(c+Vector3(14.9,16,0),c+Vector3(14.9,0.3,0))
  var lip:=space.intersect_ray(q)
  if inside.is_empty() or absf(inside.position.y-1.73)>0.065 or lip.is_empty() or lip.position.y<10.6:
   errors.append(str(n.name)+": no open physical interior and separate rim")
 print("Nursery exact vessel forms issues=",errors," vertices ratio=",float(new_cost)/float(old_cost))
 fixture.queue_free()
 quit(0 if errors.is_empty() else 1)
