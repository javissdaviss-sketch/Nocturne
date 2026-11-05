extends SceneTree
## Normalize standalone prefab physics after all model exports, without altering
## the game's geometry. Existing baked colliders are retained idempotently.
const Compiler = preload("res://scripts/solid_geometry.gd")
func _initialize() -> void: call_deferred("run")
func own_branch(node: Node, scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  own_branch(child,scene_root)
func count_meshes(node: Node) -> int:
 var count := 1 if node is MeshInstance3D or node is MultiMeshInstance3D else 0
 for child in node.get_children(): count += count_meshes(child)
 return count
func count_shapes(node: Node) -> int:
 var count := 1 if node is CollisionShape3D else 0
 for child in node.get_children(): count += count_shapes(child)
 return count
func run() -> void:
 var paths := DirAccess.get_files_at("res://assets/models")
 var total := 0
 for filename in paths:
  if not filename.ends_with(".scn"): continue
  var path := "res://assets/models/"+filename
  var model: Node3D = load(path).instantiate()
  root.add_child(model)
  Compiler.new().build(model)
  own_branch(model,model)
  var meshes := count_meshes(model)
  var shapes := count_shapes(model)
  assert(meshes > 0 and shapes > 0)
  var packed := PackedScene.new()
  assert(packed.pack(model) == OK)
  assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) == OK)
  var restored: Node3D = ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE).instantiate()
  assert(count_meshes(restored) == meshes and count_shapes(restored) == shapes)
  restored.free()
  model.queue_free()
  await process_frame
  total += 1
  print("VALIDATED MODEL: ",filename," meshes=",meshes," collision shapes=",shapes)
 print("PASS: ",total," standalone models retain visible geometry and physical collision after disk reload")
 quit()
