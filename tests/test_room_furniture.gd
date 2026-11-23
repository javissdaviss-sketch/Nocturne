extends SceneTree
## Check transformed visible geometry in the generated scene. Collision tests
## alone can pass even when a perfectly solid chair is half inside a wall.
const World = preload("res://scripts/world.gd")
const GardenFixtures = preload("res://scripts/garden_fixture_geometry.gd")
var failed := false

func _initialize() -> void:
 call_deferred("run")

func world_bounds(node: Node3D) -> AABB:
 var bounds := AABB()
 if node is MeshInstance3D and node.mesh != null:
  # Source MeshInstances retain authored transforms even when batched.
  bounds = node.global_transform * node.mesh.get_aabb()
 if node is MultiMeshInstance3D and node.multimesh != null:
  for transform3 in node.multimesh.get_meta("solid_geometry_transforms",[]):
   var piece: AABB = node.global_transform*transform3*node.multimesh.mesh.get_aabb()
   bounds = bounds.merge(piece) if bounds.has_surface() else piece
 for child in node.get_children():
  if child is Node3D and not child is CollisionObject3D and not child is CollisionShape3D:
   var candidate := world_bounds(child)
   if candidate.has_surface():
    bounds = bounds.merge(candidate) if bounds.has_surface() else candidate
 return bounds

func check(value: bool, message: String) -> void:
 if not value:
  failed = true
  printerr("FAIL: ", message)

func run() -> void:
 var world := World.new()
 root.add_child(world)
 var nodes := world.find_children("*", "Node3D", true, false)
 var chairs := nodes.filter(func(n: Node) -> bool: return n.get_meta("layout_furniture","") == "seat")
 var tables := nodes.filter(func(n: Node) -> bool: return n.has_node("MouldedWalnutTop"))
 var layout := world.get_node("CompartmentLayout")
 var chair_bounds: Array[AABB] = []
 check(chairs.size() == 20, "all twenty chairs are checked")
 for chair in chairs:
  var box := world_bounds(chair)
  chair_bounds.append(box)
  var center: Vector3 = chair.global_position
  var assigned := false
  for room in layout.rooms:
   if signf(center.x) != room.side or center.z <= room.lo or center.z >= room.hi:
    continue
   assigned = true
   check(box.position.z >= room.lo+5.0 and box.end.z <= room.hi-5.0,
    "chair clears partition at %s, bounds %s" % [center,box])
   check(minf(absf(box.position.x),absf(box.end.x)) > 60.0, "chair clears the aisle")
   break
  check(assigned, "chair belongs to a compartment at %s" % center)
  var best_distance := INF
  var serving_table: Node3D = null
  for table in tables:
   var distance: float = table.global_position.distance_to(center)
   if distance < best_distance:
    serving_table = table
    best_distance = distance
  if serving_table == null: continue
  var toward := (serving_table.global_position-center).normalized()
  check((-chair.global_basis.z).dot(toward) > 0.70, "chair faces its table at %s" % center)
  check(not box.intersects(world_bounds(serving_table)), "chair does not crash into its table at %s" % center)
 for i in range(chair_bounds.size()):
  for j in range(i+1,chair_bounds.size()):
   check(not chair_bounds[i].intersects(chair_bounds[j]), "chairs %s and %s do not overlap" % [i,j])
 var sleeper_slates := 0
 for slate in nodes.filter(func(n: Node) -> bool: return n.get_meta("layout_furniture","") == "data_slate"):
  if slate.global_position.z >= 800: continue
  sleeper_slates += 1
  var supported := false
  var prop_bounds := world_bounds(slate)
  for table in tables:
   var top := table.get_node("MouldedWalnutTop") as MeshInstance3D
   var top_bounds := world_bounds(top)
   if absf(prop_bounds.position.y-top_bounds.end.y) <= 0.15 \
     and prop_bounds.position.x >= top_bounds.position.x and prop_bounds.end.x <= top_bounds.end.x \
     and prop_bounds.position.z >= top_bounds.position.z and prop_bounds.end.z <= top_bounds.end.z:
    supported = true
    break
  check(supported, "sleeper slate sits on its actual tabletop at %s, bounds %s" % [slate.global_position,prop_bounds])
 check(sleeper_slates == 4, "all four sleeper slates are tested")
 var dinner_plate := world.get_node("ValeTableDinnerPlate") as MeshInstance3D
 var coaster := world.get_node("EvidenceSaucerCoaster") as MeshInstance3D
 var saucer := world.get_node("EvidenceCup/PorcelainSaucer") as MeshInstance3D
 var plate_bounds := world_bounds(dinner_plate)
 var coaster_bounds := world_bounds(coaster)
 var saucer_bounds := world_bounds(saucer)
 var centers := Vector2(dinner_plate.position.x-coaster.position.x,dinner_plate.position.z-coaster.position.z)
 check(centers.length() > (plate_bounds.size.x+coaster_bounds.size.x)*0.5+0.5,
  "Skyline view no longer overlays the dinner plate and evidence saucer/coaster")
 check(absf(plate_bounds.position.y-77.4)<0.025 and absf(coaster_bounds.position.y-77.4)<0.025,
  "Both pieces are supported by the actual table surface")
 check(absf(coaster_bounds.end.y-saucer_bounds.position.y)<0.025,
  "Coaster supports the original evidence saucer with no floating gap")
 var same_clue: Vector3 = world.hotspots.cup.position
 check(same_clue==Vector3(-88,83,1250),"The evidence inspection position is unchanged")
 var vale_table_count := 0
 for table in tables:
  if table.global_position!=Vector3(-110,0,1250): continue
  vale_table_count += 1
  var wood: AABB = world_bounds(table.get_node("MouldedWalnutTop"))
  check(plate_bounds.position.x>wood.position.x+2 and plate_bounds.end.x<wood.end.x-2
    and plate_bounds.position.z>wood.position.z+2 and plate_bounds.end.z<wood.end.z-2,
    "Dinner plate remains on Vale's tabletop, not at the table edge")
 check(vale_table_count==1,"Vale's original table is checked")
 var tableau := world.get_node("QuietTable") as Node3D
 var tableau_bounds := world_bounds(tableau)
 check(tableau_bounds.size.x >= 172 and tableau_bounds.size.x <= 178,
  "covered scene keeps human scale and runs across the room")
 check(tableau_bounds.position.z > 1310 and tableau_bounds.end.z < 1385 and tableau_bounds.end.x < -65,
  "covered scene clears the cup table, bulkhead, and aisle")
 var linen := tableau.get_node("FoldedLinen") as MeshInstance3D
 check(linen.material_override.get_meta("crafted_finish",-1) == 6,
  "reference linen material remains on the shroud")
 for box in chair_bounds:
  check(not box.intersects(tableau_bounds),"chairs do not intersect the quiet table")
 var dispatch_count := 0
 for table in tables:
  var center: Vector3 = table.global_position
  if center.x>=0 or not is_equal_approx(center.z,2235.0): continue
  dispatch_count += 1
  var dispatch_bounds := world_bounds(table)
  check(dispatch_bounds.end.x < -60.0,"dispatch table stays inside the wall")
  for node in nodes:
   if node.get_meta("inner_bed_side",0)==-1 and node.get_meta("inner_bed_row",0)==2260:
    check(not dispatch_bounds.intersects(world_bounds(node)),"dispatch table and archive bed are separate")
  var unchanged_point: Vector3 = world.hotspots.ledger.position
  check(unchanged_point == Vector3(-100,80,2235) and dispatch_bounds.position.x < unchanged_point.x and unchanged_point.x < dispatch_bounds.end.x,
   "original ledger still belongs to the unchanged investigation point")
 check(dispatch_count==1,"one dispatch table is checked")
 for crown in world.palms:
  var center: Vector3 = crown.global_position
  var foliage := world_bounds(crown)
  var has_room := false
  for room in layout.rooms:
   if signf(center.x)!=room.side or center.z<=room.lo or center.z>=room.hi: continue
   has_room = true
   var aisle_clearance := minf(absf(foliage.position.x),absf(foliage.end.x))
   check(aisle_clearance>60 and foliage.position.z>room.lo+3 and foliage.end.z<room.hi-3,
    "full palm crown stays clear of wall at %s" % center)
   break
  check(has_room,"palm belongs to a compartment")

 var gardens := world.get_node("GardenAccessories")
 var anchors: Dictionary = gardens.get_meta("garden_support_anchors")
 await physics_frame
 await process_frame
 var space := world.get_world_3d().direct_space_state
 # The little corner palm remains wholly in its bay and outside the actual
 # view through the original doorway to the mounted garment.
 var cloak_crowns:=0
 for crown in world.palms:
  if crown.global_position.x>55 and crown.global_position.z>840 and crown.global_position.z<990:
   cloak_crowns+=1
   check(crown.global_position.is_equal_approx(Vector3(250,117*0.83,952)),"the one real cloakroom palm is kept, lowered and placed by its bulkhead")
 check(cloak_crowns==1,"exactly one original cloakroom palm remains")
 var eye:=Vector3(104,115,889)
 for seam in [Vector3(392,148,943),Vector3(392,157,941),Vector3(392,139,946)]:
  var reach:=space.intersect_ray(PhysicsRayQueryParameters3D.create(eye,seam,1))
  check(not reach.is_empty() and reach.position.x>385.0 and reach.position.x<391.0,
   "actual clear sightline from cloakroom entrance to front of coat: "+str(reach.get("position")))
 for anchor_name in ["tray","rack","front_pot","archive_pot"]:
  var side := -1 if anchor_name == "tray" else 1
  var row := 1880 if anchor_name in ["tray","front_pot"] else 2260
  var anchor: Vector3 = anchors[anchor_name]
  var planter_count := 0
  for node in nodes:
   if node.get_meta("inner_bed_side",0)!=side or node.get_meta("inner_bed_row",0)!=row: continue
   planter_count += 1
   var local: Vector3 = node.to_local(anchor)
   check(absf(local.x)<75 and absf(local.z)<5,"accessory stays within the actual planted bed")
   var soil := GardenFixtures.soil_height(local.x,local.z,190,52)
   check(absf(soil-local.y)<0.1,"accessory follows planted soil height")
   # Probe immediately beside the accessory footprint, avoiding its own collider.
   var probe: Vector3 = node.to_local(anchor+Vector3(0,0,22))
   probe.y = GardenFixtures.soil_height(probe.x,probe.z,190,52)
   var surface_point: Vector3 = node.to_global(probe)
   var ray := PhysicsRayQueryParameters3D.create(surface_point+Vector3(0,0.75,0),surface_point-Vector3(0,4,0),1)
   var hit := space.intersect_ray(ray)
   check(not hit.is_empty() and node.is_ancestor_of(hit.collider) and absf(hit.position.y-surface_point.y)<0.3,
    "physical soil collider beside the accessory footprint")
  check(planter_count == 1,"accessory matches exactly one planter in the loaded scene")
 var floor_point: Vector3 = anchors.can + Vector3(5,0.4,2)
 var floor_ray := PhysicsRayQueryParameters3D.create(floor_point+Vector3(0,0.15,0),floor_point-Vector3(0,1.0,0),1)
 var floor_hit := space.intersect_ray(floor_ray)
 check(not floor_hit.is_empty() and absf(floor_hit.position.y)<0.10,"watering can's foot rests on the actual floor")
 var luggage_count := 0
 for node in nodes:
  if not node.has_meta("floor_luggage"): continue
  for luggage in node.get_meta("floor_luggage"):
   luggage_count += 1
   var center: Vector3 = luggage[0]
   var dimensions: Vector3 = luggage[1]
   check(center.z-dimensions.z/2-1.0>365.0,"entire case clears sleeper wall and its trim")
   var ray := PhysicsRayQueryParameters3D.create(center+Vector3(0,3,0),center+Vector3(0,3,0)-Vector3(dimensions.x,0,0),1)
   ray.hit_from_inside = true
   var hit := space.intersect_ray(ray)
   check(not hit.is_empty() and node.is_ancestor_of(hit.collider),"modeled case is solid into the visible footprint")
   var near_floor := center+Vector3(dimensions.x/2+2,0,0)
   ray = PhysicsRayQueryParameters3D.create(near_floor+Vector3(0,1.2,0),near_floor-Vector3(0,1.0,0),1)
   hit = space.intersect_ray(ray)
   check(not hit.is_empty() and absf(hit.position.y-center.y)<0.1,"nearby actual floor matches the grounded case")
 check(luggage_count==3,"all three freestanding cases are checked")

 world.queue_free()
 await process_frame
 if not failed:
  print("PASS: all 20 chairs clear partitions, tables, and one another; face their tables; all 4 sleeper slates sit on tabletops; the covered scene and garden accessories have physical clearance and support; dispatch table, crowns and luggage clear their partitions; the evidence saucer and dinner plate remain seated and separate")
 quit(1 if failed else 0)
