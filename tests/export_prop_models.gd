extends SceneTree
## Rebuild standalone prop scenes from the same authored meshes used in the game.
## Run: godot --headless --path . --script res://tests/export_prop_models.gd
const Details = preload("res://scripts/lived_in_details.gd")
const Residential = preload("res://scripts/residential_props.gd")
const Hospitality = preload("res://scripts/hospitality_props.gd")
const SolidGeometry = preload("res://scripts/solid_geometry.gd")

func _initialize() -> void:
 call_deferred("run")

func own_branch(node: Node, scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  own_branch(child,scene_root)

func counts(node: Node) -> Dictionary:
 var result := {"render_nodes":0,"render_instances":0,"physics_bodies":0,"collision_shapes":0}
 if node is MeshInstance3D:
  result.render_nodes += 1
  result.render_instances += 1
 elif node is MultiMeshInstance3D:
  result.render_nodes += 1
  result.render_instances += node.multimesh.instance_count
  var transforms: Array = node.multimesh.get_meta("solid_geometry_transforms",[])
  assert(transforms.size() == node.multimesh.instance_count,"Baked batches retain CPU transforms for headless physics")
 if node is StaticBody3D: result.physics_bodies += 1
 if node is CollisionShape3D: result.collision_shapes += 1
 for child in node.get_children():
  var child_counts := counts(child)
  for key in result: result[key] += child_counts[key]
 return result

func build_asset(id: String) -> Node3D:
 var model := Node3D.new()
 model.name = id.to_pascal_case()
 root.add_child(model)
 var builder: Node3D
 if id == "wireless_radio" or id == "travel_chess":
  builder = Residential.new()
 elif id == "tea_service":
  builder = Hospitality.new()
 else:
  builder = Details.new()
 model.add_child(builder)
 builder.name = "ModeledComponents"
 match id:
  "leather_trunk":
   builder.suitcase(Vector3.ZERO,Vector3(33,25,43),Color("654231"))
  "wireless_radio":
   builder.position = -Vector3(119,77.45,287)
   builder.wireless_radio()
  "tea_service":
   builder.teapot(Vector3.ZERO)
   builder.service_cup(Vector3(20,0,-10))
   builder.bottle(Vector3(-17,0,10),Color("48695b"))
   builder.sugar_bowl(Vector3(14,0,12))
  "travel_chess":
   builder.position = -Vector3(-102,77.45,140)
   builder.travel_chess()
  "bound_books":
   builder.book(Vector3.ZERO,17,24,3.3,Color("553c36"),-0.06)
   builder.book(Vector3(0,3.3,0),15,22,2.8,Color("284f47"),0.09)
  "folded_linen":
   builder.napkin(Vector3.ZERO)
 builder.finish_batches()
 # The baked library contains normal scene nodes and resources, not generators.
 builder.set_script(null)
 SolidGeometry.new().build(model)
 own_branch(model,model)
 return model

func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://assets/models")
 for id in ["leather_trunk","wireless_radio","tea_service","travel_chess","bound_books","folded_linen"]:
  var model := build_asset(id)
  var expected := counts(model)
  assert(expected.render_instances > 0 and expected.collision_shapes > 0,"Asset includes visible geometry and physical surfaces")
  var packed := PackedScene.new()
  assert(packed.pack(model) == OK)
  var path: String = "res://assets/models/"+id+".scn"
  assert(ResourceSaver.save(packed,path,ResourceSaver.FLAG_COMPRESS) == OK)
  var loaded := ResourceLoader.load(path,"PackedScene",ResourceLoader.CACHE_MODE_IGNORE) as PackedScene
  assert(loaded != null)
  var restored := loaded.instantiate()
  assert(counts(restored) == expected,"Reloaded asset preserves every render batch, instance and collision shape")
  print("EXPORTED PROP MODEL: ",path," ",expected)
  restored.free()
  model.free()
 quit()
