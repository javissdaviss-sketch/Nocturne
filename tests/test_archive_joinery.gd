extends SceneTree
const Id := preload("res://scripts/room_identity.gd")
const Planter := preload("res://scripts/garden_fixture_geometry.gd")
class Fixture extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var world := Fixture.new()
 root.add_child(world)
 var issues: Array[String] = []
 var field_tris := 0
 var fields: Dictionary = {}
 var silhouette_marks: Dictionary = {}
 for side in [-1,1]:
  for lo in [1680,2045]:
   var room := {"car":2,"side":side,"lo":lo,"hi":2045 if lo==1680 else 2480}
   var look := Id.garden(side,lo)
   var front := Planter.planter_front(look.profile,49.16)
   var finish := Id.wall(room)
   fields[finish.get_instance_id()] = true
   var b := front.get_aabb()
   silhouette_marks[front.get_faces().size()] = true
   if not AABB(Vector3(-24.62,-14,-2.68),Vector3(49.24,28,3.45)).encloses(b): issues.append("panel outside original garden joinery: %s %s" % [look.profile,b])
   var unit := Planter.new()
   world.add_child(unit)
   unit.build_planter(Vector3(side*377,0,lo+65),Vector3(200,64,62),look)
   if unit.get_meta("planter_joinery")!=look.profile or not unit.meshes.has("fitted_louvers"): issues.append("proper planter did not use its assigned relief")
   if unit.meshes.has("louver"): issues.append("new pattern did not replace old redundant surfaces")
   Id.draw(world,world,room)
   for surface: MeshInstance3D in world.get_child(-1).get_children():
    field_tris += surface.mesh.get_faces().size()/3
    if not AABB(Vector3(-46,-39,-6.5),Vector3(92,79,7.25)).encloses(surface.get_aabb()): issues.append("wall relief outside protected envelope")
 var inner := Planter.new()
 world.add_child(inner)
 inner.build_planter(Vector3.ZERO)
 if inner.get_meta("planter_joinery")!="" or not inner.meshes.has("louver"): issues.append("original inner planters changed")
 if fields.size()!=4 or silhouette_marks.size()!=4: issues.append("not four visually and geometrically separate fitted gardens")
 if field_tris>1900: issues.append("08 bulkhead additions exceeded budget")
 if issues.is_empty(): print("PASS: four physically modelled planter styles inside original faces, four bulkhead finishes, ",field_tris," bulkhead triangles, original inner beds unchanged.")
 else:
  for i in issues: push_error(i)
 world.queue_free()
 quit(0 if issues.is_empty() else 1)
