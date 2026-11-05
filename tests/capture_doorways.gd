extends SceneTree
# Static-camera art review shares the runtime render scene. Collision geometry
# is validated separately; constructing its CPU hulls cannot alter these frames.
class RenderOnlyPhysics extends RefCounted:
 func build(_root: Node3D, _exclusions: Array[Node] = []) -> Dictionary: return {}

func _initialize() -> void: call_deferred("run")
func run() -> void:
 root.size = Vector2i(960,600)
 var world := preload("res://scripts/world.gd").new()
 world.solid_geometry = RenderOnlyPhysics.new()
 print("BUILDING RENDER SCENE")
 root.add_child(world)
 print("RENDER SCENE READY")
 var camera := Camera3D.new()
 camera.far = 6000
 camera.near = 0.08
 camera.fov = 75
 world.add_child(camera)
 camera.current = true
 var output := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/nov5"
 DirAccess.make_dir_recursive_absolute(output)
 var views := [
  ["suite-entry",Vector3(-10,145,175),Vector3(310,108,194)],
  ["galley-entry",Vector3(-12,125,1570),Vector3(310,104,1588)],
  ["archive-entry",Vector3(10,140,2090),Vector3(-310,102,2110)],
  ["floor-detail",Vector3(185,14,184),Vector3(230,0,215)]
 ]
 for view in views:
  camera.position = view[1]
  camera.look_at(view[2])
  for _i in range(3): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+view[0]+".png")
  print("CAPTURED ",view[0])
 world.queue_free()
 await process_frame
 quit()
