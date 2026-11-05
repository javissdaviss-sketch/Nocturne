extends RefCounted
## Batch shared static meshes after physics compilation. Original nodes and colliders
## remain in place; puzzle leaves and moving palm crowns keep their own visuals.
var groups: Dictionary = {}
var meshes: Dictionary = {}
var source_count := 0
var batch_count := 0

func build(world: Node3D, exclusions: Array[Node]) -> void:
 collect(world,exclusions)
 var root := Node3D.new()
 root.name = "InteriorRenderBatches"
 root.set_meta("solid_geometry_exclude",true)
 world.add_child(root)
 for key in groups:
  var group: Dictionary = groups[key]
  if group.sources.size() < 2: continue
  var multi := MultiMesh.new()
  multi.transform_format = MultiMesh.TRANSFORM_3D
  multi.mesh = group.mesh
  multi.instance_count = group.transforms.size()
  for i in range(multi.instance_count): multi.set_instance_transform(i,group.transforms[i])
  var node := MultiMeshInstance3D.new()
  node.multimesh = multi
  node.material_override = group.material
  node.cast_shadow = group.shadow
  node.layers = group.layers
  root.add_child(node)
  for source in group.sources:
   # Render layers affect this mesh alone, unlike visibility inherited by its
   # child labels. Physics and scene ownership remain on the authored node.
   source.layers = 0
   source_count += 1
  batch_count += 1
 world.set_meta("interior_batch_stats",{"sources":source_count,"batches":batch_count})

func collect(node: Node, exclusions: Array[Node]) -> void:
 if exclusions.has(node): return
 if node is MeshInstance3D and node.visible and node.layers != 0: add_primitive(node)
 for child in node.get_children():
  if child is CollisionObject3D or child is CollisionShape3D: continue
  collect(child,exclusions)

func add_primitive(node: MeshInstance3D) -> void:
 var size := Vector3.ONE
 var shape := ""
 var mesh := node.mesh
 var authored := false
 if mesh is BoxMesh:
  shape = "box"
  size = mesh.size
 elif mesh is SphereMesh and not mesh.is_hemisphere:
  shape = "sphere_%d_%d" % [mesh.radial_segments,mesh.rings]
  size = Vector3(mesh.radius*2,mesh.height,mesh.radius*2)
 elif mesh is CylinderMesh and mesh.bottom_radius > 0:
  shape = "cylinder_%s_%d" % [str(mesh.top_radius/mesh.bottom_radius),mesh.radial_segments]
  size = Vector3(mesh.bottom_radius*2,mesh.height,mesh.bottom_radius*2)
 elif mesh is ArrayMesh and mesh.get_blend_shape_count() == 0 and node.skin == null:
  shape = "authored_"+str(mesh.get_instance_id())
  authored = true
 else: return
 # Mirrored authored meshes keep their MeshInstance winding and tangent handling.
 if authored and node.global_basis.determinant() < 0.0: return
 if node.material_override == null: return
 if node.material_overlay != null: return
 var material: Material = node.material_override
 if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: return
 if material is ShaderMaterial:
  var code: String = material.shader.code
  if code.contains("ALPHA") or code.contains("instance uniform") or code.contains("INSTANCE_CUSTOM") or code.contains("INSTANCE_ID"): return
 if not meshes.has(shape):
  var canonical: Mesh
  if mesh is BoxMesh:
   var box_mesh := BoxMesh.new()
   box_mesh.size = Vector3.ONE
   canonical = box_mesh
  elif mesh is SphereMesh:
   var sphere := SphereMesh.new()
   sphere.radius = 0.5
   sphere.height = 1
   sphere.radial_segments = mesh.radial_segments
   sphere.rings = mesh.rings
   canonical = sphere
  elif mesh is CylinderMesh:
   var cylinder := CylinderMesh.new()
   cylinder.bottom_radius = 0.5
   cylinder.top_radius = 0.5*mesh.top_radius/mesh.bottom_radius
   cylinder.height = 1
   cylinder.radial_segments = mesh.radial_segments
   canonical = cylinder
  else: canonical = mesh
  meshes[shape] = canonical
 var transform3 := node.global_transform*Transform3D(Basis.from_scale(size),Vector3.ZERO)
 # Spatial cells prevent one small prop from submitting every carriage's props.
 var cell := Vector2i(floori(transform3.origin.x/255),floori(transform3.origin.z/280))
 var shadow := node.cast_shadow
 var extent := mesh.get_aabb().size*node.global_basis.get_scale().abs()
 if not authored and extent[extent.max_axis_index()] < 6:
  shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var key := shape+":"+str(node.material_override.get_instance_id())+":"+str(cell)+":"+str(shadow)+":"+str(node.layers)
 if not groups.has(key):
  groups[key] = {"mesh":meshes[shape],"material":node.material_override,"shadow":shadow,"layers":node.layers,"transforms":[],"sources":[]}
 groups[key].transforms.append(transform3)
 groups[key].sources.append(node)
