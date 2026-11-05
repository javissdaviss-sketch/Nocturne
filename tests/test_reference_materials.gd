extends SceneTree
## Surface conversion must preserve clue and display semantics, not just colors.
const Finishes = preload("res://scripts/material_library.gd")
func _initialize() -> void:
 var scene := Node3D.new()
 scene.name = "ReferenceFinishTest"
 root.add_child(scene)
 var special: Array[MeshInstance3D] = []
 for feature in ["Glass","EmissiveDisplay","ClueResidue","PalmPhoto","TeaSurface","EyeOptics","OrdinaryWood"]:
  var node := MeshInstance3D.new()
  node.name = feature
  node.mesh = BoxMesh.new()
  var material := StandardMaterial3D.new()
  material.albedo_color = Color("493126")
  match feature:
   "EyeOptics": material.roughness = 0.2
   "Glass": material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
   "EmissiveDisplay": material.emission_enabled = true
   "ClueResidue": material.vertex_color_use_as_albedo = true
   "PalmPhoto": material.albedo_texture = preload("res://assets/textures/palm_leaf_albedo.png")
  node.material_override = material
  scene.add_child(node)
  special.append(node)
 var originals: Array[Material] = []
 for node in special: originals.append(node.material_override)
 Finishes.apply(scene)
 for i in range(6):
  assert(special[i].material_override == originals[i],"Glass, light, deposit, leaf photo and liquid must retain their authored material")
 assert(special[6].material_override is ShaderMaterial,"Ordinary solid surfaces need real texture detail")
 assert(Finishes.apply(scene) == Finishes.apply(scene),"Material coverage is stable on repeat application")
 print("PASS: reference finishes preserve clue deposits, glass, screens, palm photos, liquids and eye highlights")
 scene.free()
 quit()
