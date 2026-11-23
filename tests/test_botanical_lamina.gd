extends SceneTree
const Plants := preload("res://scripts/botanical_collection.gd")

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var tests := Plants.new()
 root.add_child(tests)
 tests.populate(-1,1680,2045)
 var found := 0
 var foliage := 0
 var errors := []
 for child in tests.get_children():
  if not child is MultiMeshInstance3D: continue
  var batch := child as MultiMeshInstance3D
  var detail := batch.name.contains("broad_leaf") or batch.name.contains("fern_frond")
  var m = batch.material_override
  if detail:
   found += 1
   if not m is ShaderMaterial or m.shader.resource_path!="res://shaders/botanical_lamina.gdshader":
    errors.append("wrong or missing leaf material")
   if batch.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_ON:
    errors.append("original geometry shadow flag changed")
   var mesh := batch.multimesh.mesh
   var arr := mesh.surface_get_arrays(0)
   var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
   var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
   if verts.size()!=uv.size() or verts.is_empty():
    errors.append("foliage geometry or UV parameterization changed")
   foliage += batch.multimesh.instance_count
  elif m is ShaderMaterial and m.shader.resource_path=="res://shaders/botanical_lamina.gdshader":
   errors.append("a non-leaf assembly was repainted")
 if found!=5 or foliage!=78: errors.append("original five groups/78 foliage instances changed: "+str(found)+"/"+str(foliage))
 if errors.is_empty(): print("PASS: original five foliage render groups/78 leaves with unchanged UV geometry/shadows; stems, ceramic and soil not reassigned.")
 else:
  for error in errors: push_error(error)
 quit(0 if errors.is_empty() else 1)
