extends SceneTree
## Rebuild the reusable furniture library from the same authored profiles as the game.
class AssetWorld extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void:
 call_deferred("run")

func own_branch(node: Node, scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  own_branch(child,scene_root)

func run() -> void:
 var world := AssetWorld.new()
 root.add_child(world)
 world.table(Vector3.ZERO,85,80)
 world.seat(Vector3.ZERO,Color("294c45"))
 preload("res://scripts/furniture_models.gd").build_chaise(world,world,Vector3.ZERO)
 DirAccess.make_dir_recursive_absolute("res://assets/models")
 var names := {"CraftedWalnutTable":"walnut_table","TuftedParlourChair":"parlour_chair","UpholsteredChaise":"chaise"}
 for model_name in names:
  var model := world.get_node(model_name)
  preload("res://scripts/material_library.gd").apply(model)
  preload("res://scripts/solid_geometry.gd").new().build(model)
  own_branch(model,model)
  var packed := PackedScene.new()
  assert(packed.pack(model) == OK)
  var path: String = "res://assets/models/"+names[model_name]+".scn"
  assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) == OK)
  var restored = load(path).instantiate()
  assert(restored.get_child_count()>0)
  restored.free()
  print("EXPORTED FURNITURE MODEL: ",path)
 quit()
