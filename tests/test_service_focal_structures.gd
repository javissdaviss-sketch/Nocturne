extends SceneTree
const Cabinet:=preload("res://scripts/cabinet_assets.gd")
const Identity:=preload("res://scripts/room_identity.gd")
class Isolated extends "res://scripts/world.gd":
 func _ready()->void: pass

func _initialize()->void: call_deferred("run")
func run()->void:
 var world:=Isolated.new()
 root.add_child(world)
 var counters:Dictionary={}
 var failures:Array[String]=[]
 var tris:=0
 for role in [[-1,840,120], [1,840,120], [-1,1390,220], [1,1390,220]]:
  var look:=Identity.service(role[0],role[1])
  var name:String=look.casework
  var fit:=Cabinet.service_counter(world,world,Vector3(role[0]*410,0,role[1]+85),role[2],role[0],look)
  counters[name]=fit
  var additions:=0
  for child in fit.get_children():
   if not child.get_meta("service_focal_structure",false): continue
   additions+=1
   var mesh:=child as MeshInstance3D
   var bounds:=mesh.get_aabb()
   tris+=mesh.mesh.get_faces().size()/3
   if not AABB(Vector3(-role[2]*0.5,95.7,-60),Vector3(role[2],97,126)).encloses(bounds):
    failures.append(name+": silhouette expands established counter envelope "+str(bounds))
   if mesh.get_child_count()!=1 or mesh.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
    failures.append(name+": decorative surfaces are not registered physical, non-casting shapes")
  if additions!=(0 if name=="pantry" else 2):
   failures.append(name+": incorrect primary structure fit count")
 if tris>6600: failures.append("small decorative budget exceeded "+str(tris)+" triangles")
 await physics_frame
 await physics_frame
 var space:=world.get_world_3d().direct_space_state
 for probe in [
  ["concierge",Vector3(0,139,-59),Vector3(0,139,-41),false],
  ["concierge",Vector3(50,130,-59),Vector3(50,130,-41),true],
  ["concierge",Vector3(0,186,-57),Vector3(0,186,-39),true],
  ["cloak",Vector3(24,142,-24),Vector3(24,142,-10),false],
  ["cloak",Vector3(-27,142,-25),Vector3(-27,142,-10),true],
  ["cloak",Vector3(0,185,-18),Vector3(0,185,-8),true],
  ["steward",Vector3(-73,111,18),Vector3(-73,111,54),false],
  ["steward",Vector3(-73,134,20),Vector3(-73,134,54),false],
  ["steward",Vector3(-73,134,20),Vector3(-73,134,64),true],
  ["steward",Vector3(0,120,20),Vector3(0,120,54),true]]:
  var c:Node3D=counters[probe[0]]
  var ray:=PhysicsRayQueryParameters3D.create(c.to_global(probe[1]),c.to_global(probe[2]))
  var hit:=not space.intersect_ray(ray).is_empty()
  if hit!=probe[3]: failures.append("counter "+probe[0]+" unexpected solid/open path "+str(probe[1]))
 print("Service focal structures issues=",failures," triangles=",tris)
 world.queue_free()
 quit(0 if failures.is_empty() else 1)
