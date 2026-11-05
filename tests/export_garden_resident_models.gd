extends SceneTree
## Bake the crafted botanical furniture and tailored residents as standalone assets.
## Each scene contains its own exact solid geometry and recursively owned descendants.
const Fixtures = preload("res://scripts/garden_fixture_geometry.gd")
const Botanicals = preload("res://scripts/botanical_collection.gd")
const Residents = preload("res://scripts/resident_assets.gd")
const Solids = preload("res://scripts/solid_geometry.gd")

class PalmWorld extends "res://scripts/world.gd":
 func _ready() -> void: pass
 func _process(_delta: float) -> void: pass

func _initialize() -> void:
 call_deferred("run")

func own_branch(node: Node, scene_root: Node) -> void:
 for child in node.get_children():
  child.owner = scene_root
  own_branch(child,scene_root)

func count_nodes(node: Node) -> int:
 var result := 1
 for child in node.get_children(): result += count_nodes(child)
 return result

func bake(model: Node3D, filename: String) -> void:
 Solids.new().build(model)
 # The scene is usable without executing a generator, with embedded custom meshes.
 model.set_script(null)
 own_branch(model,model)
 var expected := count_nodes(model)
 var scene := PackedScene.new()
 assert(scene.pack(model) == OK)
 var path := "res://assets/models/"+filename+".scn"
 assert(ResourceSaver.save(scene,path,ResourceSaver.FLAG_COMPRESS) == OK)
 var restored: Node = load(path).instantiate()
 assert(count_nodes(restored) == expected)
 for child in restored.get_children():
  if child is MultiMeshInstance3D:
   assert(child.multimesh.get_meta("solid_geometry_transforms",[]).size() == child.multimesh.instance_count)
 restored.free()
 print("EXPORTED GARDEN / RESIDENT MODEL: ",path," (",expected," nodes)")

func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://assets/models")
 var stage := Node3D.new()
 root.add_child(stage)
 var planter := Fixtures.new()
 stage.add_child(planter)
 planter.build_planter(Vector3.ZERO)
 bake(planter,"crafted_garden_planter")
 var palm_world := PalmWorld.new()
 stage.add_child(palm_world)
 palm_world.rng.seed = 87
 palm_world.plant(Vector3.ZERO,130,38)
 var palm := Node3D.new()
 palm.name = "OrganicPalm"
 stage.add_child(palm)
 for child in palm_world.get_children(): child.reparent(palm)
 palm_world.free()
 bake(palm,"botanical_palm")
 for kind in ["broadleaf","fern"]:
  var specimen := Botanicals.new()
  stage.add_child(specimen)
  specimen.make_leaf_meshes()
  if kind == "broadleaf": specimen.broadleaf(Vector3.ZERO,98,0.6)
  else: specimen.fern(Vector3.ZERO,0.8)
  specimen.finish_batches()
  specimen.name = "Botanical"+kind.to_pascal_case()
  bake(specimen,"botanical_"+kind)
 for row in [["resident_engineer",Color("697c80"),Color("292a2a")],["resident_steward",Color("863f54"),Color("242d30")],["resident_botanist",Color("a99068"),Color("b6b3a1")]]:
  var model: Node3D = Residents.build(null,stage,Vector3.ZERO,row[1],row[2])
  model.name = row[0].to_pascal_case()
  bake(model,row[0])
 stage.free()
 quit()
