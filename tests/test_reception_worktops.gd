extends SceneTree
const Casework := preload("res://scripts/cabinet_assets.gd")
const Purpose := preload("res://scripts/room_identity.gd")
class Fixture extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var stage := Fixture.new()
 root.add_child(stage)
 var left := Casework.service_counter(stage,stage,Vector3(-410,0,915),120,-1,Purpose.service(-1,840))
 var right := Casework.service_counter(stage,stage,Vector3(410,0,915),120,1,Purpose.service(1,840))
 var pantry := Casework.service_counter(stage,stage,Vector3(-410,0,1515),220,-1,Purpose.service(-1,1390))
 var steward := Casework.service_counter(stage,stage,Vector3(410,0,1515),220,1,Purpose.service(1,1390))
 var issues: Array[String] = []
 var added := 0
 for counter in [left,right,pantry,steward]:
  var artifacts := []
  for child in counter.get_children():
   if child.get_meta("reception_prop",false): artifacts.append(child)
  if artifacts.size() != (4 if counter==steward else 2):
   issues.append("room receives duplicate or missing decorative equipment")
  added += artifacts.size()
  for prop: MeshInstance3D in artifacts:
   var set_to := prop.transform*prop.get_aabb()
   if absf(set_to.position.x)>41.0 or set_to.end.x>41.0 or absf(set_to.position.z)>52.0 or set_to.end.z>52.0:
    issues.append("dressing exceeds grounded countertop footprint: "+str(prop.name))
   if prop.get_child_count()!=1 or prop.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
    issues.append("dressing collision or casting budget wrong: "+str(prop.name))
 if added!=10: issues.append("expected four distinct counter fitting inventories")
 for deck in [left,right,pantry,steward]:
  # Compile only actual built worktop layers to verify the rest height.
  for surface in deck.get_children():
   if surface is MeshInstance3D and absf(surface.position.y-95.85)<0.02:
    stage.solid_geometry.add_mesh(surface)
 await physics_frame
 await physics_frame
 var space := stage.get_world_3d().direct_space_state
 for fixture in [[left,"ConciergeOpenTicketCradle",96.0],[left,"ConciergeServiceBell",96.0],[right,"CloakroomKeyReturnTray",96.0],[right,"CloakroomFoldedCoat",96.8],
  [pantry,"PantryOpenMixingBowl",96.0],[pantry,"PantryRibbedDishRack",96.0],
  [steward,"StewardRaisedDispatchTray",96.0],[steward,"StewardBlankWorkSheet",96.76],
  [steward,"StewardBrassSheetClip",97.11],[steward,"StewardInkRest",96.0]]:
  var mounted: MeshInstance3D = fixture[0].get_node(fixture[1])
  var y := (mounted.transform*mounted.get_aabb()).position.y
  var p := mounted.global_position
  if absf(y-fixture[2])>0.02: issues.append("fitting floats above support: "+str(fixture[1]))
  var q := PhysicsRayQueryParameters3D.create(p+Vector3(0,0.08,0),p-Vector3(0,1.7,0))
  q.exclude = [(mounted.get_child(0) as StaticBody3D).get_rid()]
  var support := space.intersect_ray(q)
  if support.is_empty() or absf(support.position.y-y)>0.05: issues.append("no real support surface at "+str(fixture[1])+": "+str(support))
 # The bowl is genuinely recessed and the elevated rack has slots.
 var bowl: MeshInstance3D = pantry.get_node("PantryOpenMixingBowl")
 var bp := bowl.to_global(Vector3(0.3,0,0.2))
 var centre := space.intersect_ray(PhysicsRayQueryParameters3D.create(bp+Vector3(0,11,0),bp-Vector3(0,1,0)))
 var lip_pt := bowl.to_global(Vector3(11.73,0,0))
 var lip := space.intersect_ray(PhysicsRayQueryParameters3D.create(lip_pt+Vector3(0,11,0),lip_pt-Vector3(0,1,0)))
 if centre.is_empty() or absf(centre.position.y-96.98)>0.06 or lip.is_empty() or lip.position.y<103.1:
  issues.append("pantry bowl centre and rolled lip were not physically distinct")
 var rack: MeshInstance3D = pantry.get_node("PantryRibbedDishRack")
 var crest := rack.to_global(Vector3(0,0,0))
 var slot := rack.to_global(Vector3(2.7,0,0))
 var crest_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(crest+Vector3(0,11,0),crest-Vector3(0,1,0)))
 var slot_hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(slot+Vector3(0,11,0),slot-Vector3(0,1,0)))
 if crest_hit.is_empty() or crest_hit.position.y<100.8 or slot_hit.is_empty() or absf(slot_hit.position.y-96.88)>0.06:
  issues.append("draining rack does not leave an open slot between solid ribs")
 if issues.is_empty(): print("PASS: four distinct actual front counters, exact solid deck/tray/sheet supports and no overflow.")
 else:
  for issue in issues: push_error(issue)
 stage.queue_free()
 quit(0 if issues.is_empty() else 1)
