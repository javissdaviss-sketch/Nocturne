extends SceneTree
class BuildStage extends "res://scripts/world.gd":
 func _ready() -> void:
  pass

const Id := preload("res://scripts/room_identity.gd")
const Layout := preload("res://scripts/train_layout.gd")

func _initialize() -> void:
 call_deferred("check")

func check() -> void:
 var world := BuildStage.new()
 root.add_child(world)
 var motifs := Node3D.new()
 world.add_child(motifs)
 var issues: Array[String] = []
 var finishes: Dictionary = {}
 var silhouettes: Dictionary = {}
 var tris_total := 0
 var surfaces := 0
 var tea_motif: Node3D
 for key in Id.MERIDIAN:
  var columns: PackedStringArray = key.split(":")
  var side := int(columns[1])
  var lo := int(columns[2])
  var hi: int = {840:990,990:1390,1390:1640}[lo]
  var id := {"car":1,"side":side,"lo":lo,"hi":hi}
  var finish := Id.wall(id) as ShaderMaterial
  finishes[finish.get_instance_id()] = true
  Id.draw(world,motifs,id)
  var motif := motifs.get_child(-1) as Node3D
  var silhouette := PackedInt32Array()
  var tea := motif.name=="TeawareShelves"
  if tea: tea_motif = motif
  for mesh: MeshInstance3D in motif.get_children():
   surfaces += 1
   var bounds := mesh.get_aabb()
   var t := mesh.mesh.get_faces().size()/3
   tris_total += t
   silhouette.append(t)
   var min_z := -12.0 if tea else -6.5
   if not AABB(Vector3(-46,-39,min_z),Vector3(92,79,0.75-min_z)).encloses(bounds): issues.append("%s bulks into room (%s)" %[motif.name,bounds])
   if mesh.get_child_count()!=1 or mesh.get_child(0).get_child_count()!=1: issues.append("not physically solid: "+motif.name)
   if mesh.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF: issues.append("added shadow "+motif.name)
  silhouettes[str(silhouette)] = true
 if motifs.get_child_count()!=6 or finishes.size()!=6 or silhouettes.size()!=6: issues.append("room material and geometry must be distinct in all six rooms")
 if tris_total>5600 or surfaces!=13: issues.append("room geometry too expensive: %d" % tris_total)
 if not Id.style({"car":3,"side":1,"lo":2520}).is_empty(): issues.append("unscoped fourth carriage should not be defined")
 await physics_frame
 await physics_frame
 if not is_instance_valid(tea_motif): issues.append("no salon tea shelf")
 else:
  var space := world.get_world_3d().direct_space_state
  var ware := tea_motif.get_node("TeacupsAndSaucers") as MeshInstance3D
  for xy in [Vector2(-19.25,-24.0),Vector2(16.0,-24.0),Vector2(-4.4,5.0)]:
   var rim := tea_motif.to_global(Vector3(xy.x+2.62,xy.y+1.4,-7.0))
   var core := tea_motif.to_global(Vector3(xy.x+0.30,xy.y+1.4,-6.8))
   var q := PhysicsRayQueryParameters3D.create(rim+Vector3.UP*6,rim-Vector3.UP)
   var hit_rim := space.intersect_ray(q)
   q.from = core+Vector3.UP*6
   q.to = core-Vector3.UP
   var hit_core := space.intersect_ray(q)
   q.exclude=[(ware.get_child(0) as StaticBody3D).get_rid()]
   var hit_shelf := space.intersect_ray(q)
   if hit_rim.is_empty() or hit_core.is_empty() or hit_shelf.is_empty() or absf(hit_shelf.position.y-core.y)>0.025 or absf(hit_rim.position.y-hit_core.position.y)<1.7:
    issues.append("tea must have physical hollow cups supported by a real shelf: "+str([hit_rim,hit_core,hit_shelf]))
 if issues.is_empty(): print("PASS: six distinct solid motifs and 13 non-shadow draw surfaces, including physically supported open teacups; %d triangles."%tris_total)
 else:
  for issue in issues: push_error(issue)
 world.queue_free()
 quit(0 if issues.is_empty() else 1)
