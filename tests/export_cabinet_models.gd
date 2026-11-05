extends SceneTree
## Rebuild physical cabinet scenes from the same authored models as the game.
## Run: godot --headless --path . --script res://tests/export_cabinet_models.gd
const Cabinets = preload("res://scripts/cabinet_assets.gd")
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
 for label in ["cyber_luxe_wardrobe","service_counter_180","framed_service_door"]:
  var model: Node3D
  match label:
   "cyber_luxe_wardrobe":
    model = Cabinets.wardrobe(world,world,Vector3.ZERO)
   "service_counter_180":
    # Standard 180 cm length; the runtime builder also supports room lengths.
    model = Cabinets.service_counter(world,world,Vector3.ZERO,180,1)
   "framed_service_door":
    # Canonical front faces -Z; rotate Y by PI/2 for the in-game puzzle door.
    model = Cabinets.framed_panel(world,world,Vector3.ZERO,Vector3(73,68,3))
  SolidGeometry.new().build(model)
  own_branch(model,model)
  var expected := counts(model)
  assert(expected.meshes > 0 and expected.shapes > 0)
  var packed := PackedScene.new()
  assert(packed.pack(model) == OK)
  var path: String = "res://assets/models/"+label+".scn"
  assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) == OK)
  var restored: Node = ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
  assert(counts(restored) == expected,"Cabinet reload preserves every mesh and physical surface")
  print("EXPORTED CABINET MODEL: ",path," ",expected)
  restored.free()
  model.free()
 world.queue_free()
 await process_frame
 quit()
