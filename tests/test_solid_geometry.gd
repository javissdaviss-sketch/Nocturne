extends SceneTree
## Compiler regression: exact openings and scale-safe solid volumes.
const Compiler = preload("res://scripts/solid_geometry.gd")
var failures: Array[String] = []
func check(ok: bool, message: String) -> void:
 if not ok: failures.append(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
 var scene := Node3D.new()
 root.add_child(scene)
 var scaled := Node3D.new()
 scene.add_child(scaled)
 scaled.scale = Vector3(2,3,0.5)
 scaled.rotation = Vector3(0.2,0.4,0.1)
 var cube := MeshInstance3D.new()
 cube.mesh = BoxMesh.new()
 scaled.add_child(cube)
 cube.scale = Vector3(1,2,4)
 cube.rotation = Vector3(0.35,0.1,0.5)
 var ring := MeshInstance3D.new()
 var torus := TorusMesh.new()
 torus.inner_radius = 1.2
 torus.outer_radius = 2
 torus.rings = 32
 torus.ring_segments = 12
 ring.mesh = torus
 scene.add_child(ring)
 ring.position = Vector3(20,0,0)
 ring.scale = Vector3(2,0.5,3)
 ring.rotation.z = 0.3
 var copies := MultiMeshInstance3D.new()
 var mm := MultiMesh.new()
 mm.transform_format = MultiMesh.TRANSFORM_3D
 mm.mesh = BoxMesh.new()
 mm.instance_count = 2
 mm.set_instance_transform(0,Transform3D(Basis.from_scale(Vector3(2,3,4)),Vector3(-4,0,0)))
 mm.set_instance_transform(1,Transform3D(Basis.from_scale(Vector3(2,3,4)),Vector3(4,0,0)))
 mm.set_meta("solid_geometry_transforms",[Transform3D(Basis.from_scale(Vector3(2,3,4)),Vector3(-4,0,0)),Transform3D(Basis.from_scale(Vector3(2,3,4)),Vector3(4,0,0))])
 copies.multimesh = mm
 scene.add_child(copies)
 copies.position = Vector3(40,0,0)
 copies.scale = Vector3(1.2,2.1,0.7)
 copies.rotation = Vector3(0.3,0.25,0.5)
 var reflected := MeshInstance3D.new()
 reflected.mesh = BoxMesh.new()
 scene.add_child(reflected)
 reflected.position = Vector3(60,0,0)
 reflected.scale = Vector3(-2,3,1)
 reflected.rotation = Vector3(0.3,0.1,0.25)
 var excluded := Node3D.new()
 scene.add_child(excluded)
 var non_solid := MeshInstance3D.new()
 non_solid.mesh = BoxMesh.new()
 excluded.add_child(non_solid)
 non_solid.position = Vector3(80,0,0)
 var existing := MeshInstance3D.new()
 existing.mesh = BoxMesh.new()
 scene.add_child(existing)
 existing.position = Vector3(90,0,0)
 existing.create_trimesh_collision()
 existing.get_child(0).collision_layer = 0
 var compiler = Compiler.new()
 compiler.build(scene,[excluded])
 for body in [cube.get_child(0),ring.get_child(0),copies.get_child(0),reflected.get_child(0)]:
  check(body.global_basis.get_scale().is_equal_approx(Vector3.ONE),"Body has unit global scale")
 await physics_frame
 await process_frame
 var space := root.world_3d.direct_space_state
 var shape_query := PhysicsShapeQueryParameters3D.new()
 var sphere := SphereShape3D.new()
 sphere.radius = 0.05
 shape_query.shape = sphere
 shape_query.collision_mask = 1
 shape_query.transform.origin = cube.global_position
 check(not space.intersect_shape(shape_query).is_empty(),"Deep inside sheared box detected")
 var ring_hole := PhysicsRayQueryParameters3D.create(ring.global_transform*Vector3(0,5,0),ring.global_transform*Vector3(0,-5,0),1)
 check(space.intersect_ray(ring_hole).is_empty(),"Ring center stays open under nonuniform scale")
 var ring_rim := PhysicsRayQueryParameters3D.create(ring.global_transform*Vector3(1.6,5,0),ring.global_transform*Vector3(1.6,-5,0),1)
 check(not space.intersect_ray(ring_rim).is_empty(),"Ring rim collides")
 var gap := PhysicsRayQueryParameters3D.create(copies.global_transform*Vector3(0,5,0),copies.global_transform*Vector3(0,-5,0),1)
 check(space.intersect_ray(gap).is_empty(),"MultiMesh gap stays open")
 shape_query.transform.origin = copies.global_transform*Vector3(-4,0,0)
 check(not space.intersect_shape(shape_query).is_empty(),"Deep inside MultiMesh cube detected")
 shape_query.transform.origin = reflected.global_position
 check(not space.intersect_shape(shape_query).is_empty(),"Reflected closed volume detects interior")
 check(reflected.get_child(0).global_basis.determinant() > 0.0,"Reflected mesh body has proper positive determinant")
 check(non_solid.get_child_count() == 0,"Excluded branch stays nonphysical")
 check(existing.get_child_count() == 1 and existing.get_child(0).collision_layer == 0,"Existing disabled puzzle collider is preserved")
 check(compiler.stats.mesh_bodies == 3 and compiler.stats.multimesh_bodies == 1,"Expected collider body counts")
 compiler.build(scene,[excluded])
 check(compiler.stats.mesh_bodies == 3 and compiler.stats.multimesh_bodies == 1,"Repeated compilation creates no duplicates")
 if failures.is_empty(): print("PASS: scaled/sheared/reflected solid volumes, unit-scale bodies, open torus, MultiMesh gap, deep overlap, exclusions, existing collider, idempotence")
 else: for failure in failures: printerr("FAIL: ",failure)
 quit(0 if failures.is_empty() else 1)
