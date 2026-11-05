extends SceneTree
## Repeated authored models retain labels, layers, shadows and puzzle visibility.
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene := Node3D.new()
 root.add_child(scene)
 var mesh := preload("res://scripts/crafted_geometry.gd").rounded_box(Vector3(8,12,8),0.4)
 var material := StandardMaterial3D.new()
 var sources: Array[MeshInstance3D] = []
 for i in range(6):
  var node := MeshInstance3D.new()
  node.mesh = mesh
  node.material_override = material
  node.layers = 2
  scene.add_child(node)
  node.position = Vector3(15+i*20,0,10)
  sources.append(node)
 var label := Label3D.new()
 label.text = "Attached label"
 sources[0].add_child(label)
 # These controls must remain independent even though their mesh is shared.
 var glass := material.duplicate() as StandardMaterial3D
 glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 sources[2].material_override = glass
 sources[3].material_overlay = material
 sources[5].scale.x = -1
 var batcher = preload("res://scripts/interior_batches.gd").new()
 batcher.build(scene,[sources[4]])
 assert(sources[0].layers == 0 and sources[1].layers == 0)
 assert(label.is_visible_in_tree(),"Batching a mesh must not hide its child labels")
 assert(sources[2].layers == 2,"Transparent geometry keeps independent sorting")
 assert(sources[3].layers == 2,"Overlay materials retain their source draw")
 assert(sources[4].layers == 2 and sources[4].visible,"Excluded puzzle leaves stay independently visible")
 assert(sources[5].layers == 2,"Mirrored authored meshes retain independent winding and tangent handling")
 var render_root := scene.get_node("InteriorRenderBatches")
 assert(render_root.get_child_count() == 1)
 var batch := render_root.get_child(0) as MultiMeshInstance3D
 assert(batch.layers == 2 and batch.multimesh.instance_count == 2)
 assert(batch.multimesh.mesh == mesh,"Authored geometry is shared without simplification")
 assert(batch.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_ON)
 assert(scene.get_meta("interior_batch_stats").sources == 2)
 print("PASS: authored static batching preserves geometry, shadows, layers, child labels, transparent sorting and excluded puzzle leaves")
 scene.queue_free()
 await process_frame
 quit()
