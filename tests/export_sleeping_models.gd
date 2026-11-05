extends SceneTree
## Rebuild physical sleeping-car scenes from the same authored models as the game.
## Run: godot --headless --path . --script res://tests/export_sleeping_models.gd
const Sleeping = preload("res://scripts/sleeping_assets.gd")
const SolidGeometry = preload("res://scripts/solid_geometry.gd")

class AssetWorld extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void:
 call_deferred("run")

func own_branch(node: Node, scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  own_branch(child,scene_root)

func counts(node: Node) -> Dictionary:
 var result := {"meshes":0,"bodies":0,"shapes":0}
 if node is MeshInstance3D: result.meshes += 1
 if node is StaticBody3D: result.bodies += 1
 if node is CollisionShape3D: result.shapes += 1
 for child in node.get_children():
  var child_counts := counts(child)
  for key in result: result[key] += child_counts[key]
 return result

func run() -> void:
 var world := AssetWorld.new()
 root.add_child(world)
 DirAccess.make_dir_recursive_absolute("res://assets/models")
 for label in ["meridian_sleeper_bed","marquetry_bedside_cabinet"]:
  var model: Node3D
  if label == "meridian_sleeper_bed":
   model = Sleeping.build_bed(world,world,Vector3.ZERO)
  else:
   model = Sleeping.build_bedside(world,world,Vector3.ZERO)
  preload("res://scripts/material_library.gd").apply(model)
  SolidGeometry.new().build(model)
  own_branch(model,model)
  var expected := counts(model)
  assert(expected.meshes > 0 and expected.shapes > 0)
  var packed := PackedScene.new()
  assert(packed.pack(model) == OK)
  var path: String = "res://assets/models/"+label+".scn"
  assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) == OK)
  var restored: Node = ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
  assert(counts(restored) == expected,"Sleeping model reload preserves every mesh and physical surface")
  print("EXPORTED SLEEPING MODEL: ",path," ",expected)
  restored.free()
  model.free()
 world.queue_free()
 await process_frame
 quit()
