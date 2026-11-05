extends SceneTree
## Rebuild standalone investigation props from the same models used in the world.
class AssetWorld extends "res://scripts/world.gd":
 func _ready() -> void: pass
func _initialize() -> void: call_deferred("run")
func own_branch(node: Node, scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  own_branch(child,scene_root)

func model_counts(node: Node) -> Dictionary:
 var counts := {"mesh_instances":0,"mesh_vertices":0,"static_bodies":0,"collision_shapes":0}
 if node is MeshInstance3D:
  counts.mesh_instances += 1
  counts.mesh_vertices += node.mesh.get_faces().size()
 if node is StaticBody3D: counts.static_bodies += 1
 if node is CollisionShape3D: counts.collision_shapes += 1
 for child in node.get_children():
  var child_counts := model_counts(child)
  for key in counts: counts[key] += child_counts[key]
 return counts

func cup_measurements(model: Node) -> Dictionary:
 const Hero = preload("res://scripts/hero_assets.gd")
 var measurements := {}
 for label in ["AdheredVioletDeposit","AngularVioletCrystals"]:
  var node := model.find_child(label,true,false) as MeshInstance3D
  assert(node != null)
  var minimum_y := INF
  var inward_minimum := INF
  var inward_maximum := -INF
  for point in node.mesh.get_faces():
   minimum_y = minf(minimum_y,point.y)
   var inward := Hero.cup_inner_radius(point.y)-Vector2(point.x,point.z).length()
   inward_minimum = minf(inward_minimum,inward)
   inward_maximum = maxf(inward_maximum,inward)
  measurements[label] = {"tea_clearance_cm":minimum_y-4.06,"wall_embed_cm":-inward_minimum,"maximum_inward_relief_cm":inward_maximum}
 return measurements

func run() -> void:
 var only := ""
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--only="): only = argument.trim_prefix("--only=")
 var labels := ["maintenance_terminal","v9_reagent_bottle","dispatch_case","dispatch_ledger","data_slate","covered_scene","evidence_cup"]
 if not only.is_empty() and not only in labels:
  printerr("Unknown hero model: ",only)
  quit(1)
  return
 var w := AssetWorld.new()
 root.add_child(w)
 const Hero = preload("res://scripts/hero_assets.gd")
 DirAccess.make_dir_recursive_absolute("res://assets/models")
 for label in labels:
  if not only.is_empty() and label != only: continue
  var model := Node3D.new()
  w.add_child(model)
  model.name = label
  match label:
   "maintenance_terminal": Hero.terminal(w,model,Vector3(0,5,0))
   "v9_reagent_bottle": Hero.chemical_bottle(w,model,Vector3.ZERO)
   "dispatch_case": Hero.dispatch_cover(w,model,Vector3(0,4,0))
   "dispatch_ledger": Hero.ledger(w,model,Vector3.ZERO)
   "data_slate": Hero.data_slate(w,model,Vector3.ZERO)
   "covered_scene": Hero.covered_scene(w,model,Vector3.ZERO)
   "evidence_cup": Hero.evidence_cup(w,model,Vector3.ZERO)
  preload("res://scripts/solid_geometry.gd").new().build(model)
  own_branch(model,model)
  var expected := model_counts(model)
  var packed := PackedScene.new()
  assert(packed.pack(model) == OK)
  var path: String = "res://assets/models/"+label+".scn"
  assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) == OK)
  var resource := ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
  var restored: Node = resource.instantiate()
  assert(model_counts(restored) == expected,"Reload preserves all model meshes and physical surfaces")
  if label == "evidence_cup":
   var measurements := cup_measurements(restored)
   print("CUP RESIDUE MEASUREMENTS: ",measurements)
   for part in measurements:
    var values: Dictionary = measurements[part]
    assert(values.tea_clearance_cm > 0,"All residue stays above the accepted tea surface")
    # Packed mesh coordinates have finite precision; allow 0.0001 cm tolerance.
    assert(values.wall_embed_cm >= 0.0019 and values.wall_embed_cm < 0.0021,"Deposit backs contact the ceramic with 0.002 cm embed")
    assert(values.maximum_inward_relief_cm < 0.121,"Deposits remain thin, with sparse small shards")
  restored.free()
  model.queue_free()
  await process_frame
  print("EXPORTED HERO MODEL: ",path," ",expected)
 w.queue_free()
 await process_frame
 quit()
