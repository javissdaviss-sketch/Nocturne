extends RefCounted
## Physical collision for interior rendering geometry. Closed primitives use
## exact faceted convex volumes; ring holes and custom sheets remain concave.
## Keep this compiler on the world to reuse resources for later additions.
var stats: Dictionary = {
 "mesh_bodies":0,"multimesh_bodies":0,"convex_shapes":0,"concave_shapes":0,
 "triangles":0,"skipped_existing":0,"skipped_excluded":0,"skipped_empty":0,
 "skipped_invalid":0,"degenerate_triangles":0,"shape_cache_hits":0
}
var _faces: Dictionary = {}
var _shapes: Dictionary = {}
var _exclusions: Array[Node] = []

func build(root: Node3D, exclusions: Array[Node] = []) -> Dictionary:
 _exclusions = exclusions.duplicate()
 _walk(root)
 return stats.duplicate()

func _walk(node: Node) -> void:
 if _exclusions.has(node) or node.get_meta("solid_geometry_exclude",false):
  stats.skipped_excluded += 1
  return
 if node is Label3D or node is CPUParticles3D or node is GPUParticles3D: return
 if node is MeshInstance3D: add_mesh(node)
 elif node is MultiMeshInstance3D: add_multimesh(node)
 for child in node.get_children():
  if child is CollisionObject3D or child is CollisionShape3D: continue
  _walk(child)

func _has_collision(node: Node) -> bool:
 for child in node.get_children():
  if child is StaticBody3D or child is CollisionShape3D:
   stats.skipped_existing += 1
   return true
 return false

func _mesh_faces(mesh: Mesh) -> PackedVector3Array:
 var key := mesh.get_instance_id()
 if _faces.has(key): return _faces[key]
 var faces := mesh.get_faces()
 _faces[key] = faces
 return faces

func _is_closed_primitive(mesh: Mesh) -> bool:
 if mesh is BoxMesh: return true
 if mesh is CylinderMesh: return mesh.cap_top and mesh.cap_bottom
 if mesh is SphereMesh: return not mesh.is_hemisphere
 return false

func _rigid_basis(basis: Basis) -> Basis:
 var rigid := basis.orthonormalized()
 # Reflection is baked into shape vertices, never left as a physics-body scale.
 if rigid.determinant() < 0.0: rigid.x = -rigid.x
 return rigid

func _valid_node(node: Node3D) -> bool:
 if not node.is_inside_tree() or not node.global_transform.is_finite() or abs(node.global_basis.determinant()) < 0.000000000001:
  stats.skipped_invalid += 1
  return false
 return true

func _append_triangle(target: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
 if not a.is_finite() or not b.is_finite() or not c.is_finite() or (b-a).cross(c-a).length_squared() < 0.000000000001:
  stats.degenerate_triangles += 1
  return
 target.append(a)
 target.append(b)
 target.append(c)

func _clean_transformed(faces: PackedVector3Array, transform3: Transform3D) -> PackedVector3Array:
 var result := PackedVector3Array()
 for i in range(0,faces.size()-2,3):
  _append_triangle(result,transform3*faces[i],transform3*faces[i+1],transform3*faces[i+2])
 return result

func _geometry(mesh: Mesh, baked_basis: Basis) -> Dictionary:
 # Includes full basis rather than just scale, preserving shear/reflection.
 var key := str(mesh.get_instance_id())+":"+str(baked_basis)
 if _shapes.has(key):
  stats.shape_cache_hits += 1
  return _shapes[key]
 var faces := _clean_transformed(_mesh_faces(mesh),Transform3D(baked_basis,Vector3.ZERO))
 if faces.is_empty(): return {}
 var shape: Shape3D
 if _is_closed_primitive(mesh):
  var convex := ConvexPolygonShape3D.new()
  convex.points = faces
  shape = convex
 else:
  var concave := ConcavePolygonShape3D.new()
  concave.backface_collision = true
  concave.set_faces(faces)
  shape = concave
 var data := {"shape":shape,"triangles":faces.size()/3}
 _shapes[key] = data
 return data

func _body(node: Node3D, rigid: Basis) -> StaticBody3D:
 var body := StaticBody3D.new()
 body.name = "SolidGeometry"
 body.collision_layer = 1
 body.collision_mask = 0
 # Cancel inherited visual scale/shear. Body global rotation stays orthonormal;
 # its actual geometry receives that scale through its baked shape vertices.
 body.transform = Transform3D(node.global_basis.inverse()*rigid,Vector3.ZERO)
 node.add_child(body)
 return body

func _add_shape(body: StaticBody3D, shape: Shape3D, transform3: Transform3D = Transform3D.IDENTITY) -> void:
 var collision := CollisionShape3D.new()
 collision.name = "ExactMesh"
 collision.shape = shape
 collision.transform = transform3
 body.add_child(collision)
 if shape is ConvexPolygonShape3D: stats.convex_shapes += 1
 else: stats.concave_shapes += 1

func add_mesh(node: MeshInstance3D) -> StaticBody3D:
 if _has_collision(node) or node.mesh == null or not _valid_node(node): return null
 var rigid := _rigid_basis(node.global_basis)
 var data := _geometry(node.mesh,rigid.inverse()*node.global_basis)
 if data.is_empty():
  stats.skipped_empty += 1
  return null
 var body := _body(node,rigid)
 _add_shape(body,data.shape)
 stats.triangles += data.triangles
 stats.mesh_bodies += 1
 return body

func add_multimesh(node: MultiMeshInstance3D) -> StaticBody3D:
 if _has_collision(node) or node.multimesh == null or node.multimesh.mesh == null or not _valid_node(node): return null
 var multimesh := node.multimesh
 if multimesh.transform_format != MultiMesh.TRANSFORM_3D:
  stats.skipped_invalid += 1
  return null
 var rigid := _rigid_basis(node.global_basis)
 var normalize := Transform3D(rigid.inverse()*node.global_basis,Vector3.ZERO)
 var cpu_transforms: Array = multimesh.get_meta("solid_geometry_transforms",[])
 var count := multimesh.instance_count
 if multimesh.visible_instance_count >= 0: count = mini(count,multimesh.visible_instance_count)
 var body: StaticBody3D
 if _is_closed_primitive(multimesh.mesh):
  # Separate convex volumes preserve gaps between individual rack/slat pieces
  # while making deeply embedded saved positions detectable by shape queries.
  for instance_index in range(count):
   var transform3: Transform3D = normalize*(cpu_transforms[instance_index] if cpu_transforms.size() == multimesh.instance_count else multimesh.get_instance_transform(instance_index))
   if not transform3.is_finite() or abs(transform3.basis.determinant()) < 0.000000000001:
    stats.skipped_invalid += 1
    continue
   var instance_rigid := _rigid_basis(transform3.basis)
   var data := _geometry(multimesh.mesh,instance_rigid.inverse()*transform3.basis)
   if data.is_empty(): continue
   if body == null: body = _body(node,rigid)
   _add_shape(body,data.shape,Transform3D(instance_rigid,transform3.origin))
   stats.triangles += data.triangles
 else:
  # Real ring/leaf triangles retain their holes and do not bridge instances.
  var faces := _mesh_faces(multimesh.mesh)
  var all_faces := PackedVector3Array()
  for instance_index in range(count):
   var transform3: Transform3D = normalize*(cpu_transforms[instance_index] if cpu_transforms.size() == multimesh.instance_count else multimesh.get_instance_transform(instance_index))
   for i in range(0,faces.size()-2,3):
    _append_triangle(all_faces,transform3*faces[i],transform3*faces[i+1],transform3*faces[i+2])
  if not all_faces.is_empty():
   var shape := ConcavePolygonShape3D.new()
   shape.backface_collision = true
   shape.set_faces(all_faces)
   body = _body(node,rigid)
   _add_shape(body,shape)
   stats.triangles += all_faces.size()/3
 if body != null: stats.multimesh_bodies += 1
 else: stats.skipped_empty += 1
 return body
