extends SceneTree

const Sleep := preload("res://scripts/sleeping_assets.gd")
const Identity := preload("res://scripts/room_identity.gd")
class BedFixture extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("check")

func check() -> void:
 var world := BedFixture.new()
 root.add_child(world)
 var issues: Array[String] = []
 var fingerprints: Dictionary = {}
 var finishes: Dictionary = {}
 var full_tris := 0
 var old := Sleep.headboard_mesh(132,67,7,false)
 var old_bounds := old.get_aabb().grow(0.03)
 for side in [-1,1]:
  for lo in [0,360]:
   var look := Identity.sleeping(side,lo)
   var outline: String = look.outline
   var rev := Sleep.headboard_mesh(132,67,7,false,outline)
   var fp := [] as Array[float]
   for x in [0,0.35,0.55,0.72,0.90,1.0]: fp.append(Sleep.head_height(x,outline))
   fingerprints[str(fp)] = true
   if not old_bounds.encloses(rev.get_aabb()): issues.append("Outline extends beyond stock berth: "+outline)
   var room := {"car":0,"side":side,"lo":lo,"hi":360 if lo==0 else 800}
   var finish := Identity.wall(room)
   finishes[finish.get_instance_id()] = true
   Identity.draw(world,world,room)
   var motif := world.get_child(-1)
   if motif.get_child_count()!=2: issues.append("Missing signed relief surfaces: "+str(motif.name))
   for mesh: MeshInstance3D in motif.get_children():
    var bound := mesh.get_aabb()
    if not AABB(Vector3(-46,-39,-6.5),Vector3(92,79,7.25)).encloses(bound): issues.append("wall relief too wide: "+str(motif.name))
    full_tris += mesh.mesh.get_faces().size()/3
    if mesh.get_child_count()!=1: issues.append("not solid: "+str(motif.name))
 if fingerprints.size()!=4 or finishes.size()!=4: issues.append("four independent outlines and wall finishes required")
 if full_tris>1800: issues.append("non-shadowed plaque meshes exceeded budget")
 var bed := Sleep.build_bed(world,world,Vector3(-415,0,180),Identity.sleeping(-1,0))
 if bed.get_meta("joinery")!="fan" or bed.get_node_or_null("ShapedHeadboard")==null or bed.get_node_or_null("RecessedUpholsteredField")==null: issues.append("test bed failed to mount full authored silhouette")
 if issues.is_empty(): print("PASS: four berth silhouettes within original footprints, four finishes, actual bed and ", full_tris," physical wall-relief triangles.")
 else:
  for i in issues: push_error(i)
 world.queue_free()
 quit(0 if issues.is_empty() else 1)
