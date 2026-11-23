extends SceneTree
class Stage extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var stage := Stage.new()
 root.add_child(stage)
 var orig := stage.table(Vector3(-230,0,0),75,65)
 var crew := stage.table(Vector3.ZERO,75,65,"crew")
 var mech := stage.table(Vector3(230,0,0),75,65,"engineering")
 var writing := stage.table(Vector3(-230,0,225),75,65,"writing")
 var coast := stage.table(Vector3(230,0,225),75,65,"coast")
 var issues: Array[String] = []
 var stock: MeshInstance3D = orig.get_node("MouldedWalnutTop")
 var id_specs := [
  [crew,"CrewAshSlattedWorkDesk","CrewLowerRackRestraints"],
  [mech,"EngineeringStressedSteelStation","EngineeringRecessedDrawerFronts"],
  [writing,"WritingTaperedWalnutFrame","WritingGraduatedStationeryDrawers"],
  [coast,"CoastBentElmsOpenHoops","CoastCurvedLuggageCradle"],
 ]
 for spec in id_specs:
  var desk: Node3D = spec[0]
  var top: MeshInstance3D = desk.get_node("MouldedWalnutTop")
  var base: MeshInstance3D = desk.get_node(spec[1])
  var surface: MeshInstance3D = desk.get_node(spec[2])
  var usable := base.get_aabb()
  if desk==crew:
   var stiles: MeshInstance3D = crew.get_node("CrewLongGrainStiles")
   usable = usable.merge(stiles.get_aabb())
   if stiles.material_override.get_shader_parameter("strand_world") != Vector3.UP: issues.append("crew vertical stiles grain runs across their length")
  if top.mesh!=stock.mesh or not is_equal_approx(top.mesh.get_aabb().end.y,77.4):
   issues.append("physical top or slate height changed")
  if absf(usable.position.y)>0.01 or absf(usable.end.y-71.5)>0.02:
   issues.append("new furniture does not ground and support original top: "+str(spec[1])+" "+str(usable))
  if not AABB(Vector3(-37.6,-0.1,-32.6),Vector3(75.2,77.6,65.2)).encloses(usable.merge(surface.get_aabb())):
   issues.append("new frame extends past old room footprint")
  if base.get_child_count()!=1 or surface.get_child_count()!=1 or desk.has_node("TurnedLeg"):
   issues.append("parts are not true replacements with exact contact")
 if crew.get_node("MouldedWalnutTop").material_override==mech.get_node("MouldedWalnutTop").material_override:
  issues.append("different room usage didn't change the visible material")
 await physics_frame
 await physics_frame
 var space := stage.get_world_3d().direct_space_state
 var hit := PhysicsRayQueryParameters3D.create(Vector3(247.5,35,32),Vector3(247.5,35,12))
 var gap := PhysicsRayQueryParameters3D.create(Vector3(210,43,32),Vector3(210,43,-32))
 if space.intersect_ray(hit).is_empty() or not space.intersect_ray(gap).is_empty():
  issues.append("drawer face isn't physically solid or usable footwell lost")
 var write_draw := PhysicsRayQueryParameters3D.create(Vector3(-230,65,257),Vector3(-230,65,247))
 var write_gap := PhysicsRayQueryParameters3D.create(Vector3(-230,47,257),Vector3(-230,47,194))
 var coast_hoop := PhysicsRayQueryParameters3D.create(Vector3(266,35,203.5),Vector3(253,35,203.5))
 var coast_shelf := PhysicsRayQueryParameters3D.create(Vector3(230,28,232),Vector3(230,10,232))
 var coast_slot := PhysicsRayQueryParameters3D.create(Vector3(233,28,232),Vector3(233,10,232))
 if space.intersect_ray(write_draw).is_empty() or not space.intersect_ray(write_gap).is_empty():
  issues.append("writing's actual drawers or open footwell missing")
 if space.intersect_ray(coast_hoop).is_empty() or space.intersect_ray(coast_shelf).is_empty() or not space.intersect_ray(coast_slot).is_empty():
  issues.append("coast's solid bent side hoop / open slatted cradle missing")
 if issues.is_empty(): print("PASS: four truly distinct berths preserve 77.4 cm slate support and original footprint; grounded frames, real drawer contacts, open footwell and slats.")
 else:
  for issue in issues: push_error(issue)
 stage.queue_free()
 quit(0 if issues.is_empty() else 1)
