extends SceneTree
## Repeatable art review. Run with a real display and isolated user data.
const World = preload("res://scripts/world.gd")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 if "--ui" in OS.get_cmdline_user_args():
  await capture_ui()
  return
 var world := World.new()
 root.add_child(world)
 print("STATIC BATCHES: ",world.get_meta("interior_batch_stats"))
 var camera := Camera3D.new()
 camera.near = 0.08
 camera.far = 8000
 camera.fov = 72
 world.add_child(camera)
 camera.current = true
 root.size = Vector2i(1280,800)
 var output := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/luxe"
 DirAccess.make_dir_recursive_absolute(output)
 var views := [
  ["01-corridor",Vector3(0,143,40),Vector3(0,153,650)],
  ["02-sleeper",Vector3(-183,154,38),Vector3(-404,82,206)],
  ["03-salon",Vector3(-215,145,1010),Vector3(-380,102,1265)],
  ["04-archive",Vector3(-195,155,1725),Vector3(-392,113,1950)],
  ["05-evidence",Vector3(-73,92,1226),Vector3(-88,82,1250)]
 ]
 for view in views:
  camera.position = view[1]
  camera.look_at(view[2])
  for frame in range(3): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+view[0]+".png")
  print("ART CAPTURE: ",view[0]," draw calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
 quit()

func capture_ui() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 var output := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/luxe"
 DirAccess.make_dir_recursive_absolute(output)
 for screen in ["06-title","07-world-notebook","08-inspection"]:
  if screen == "07-world-notebook":
   game.start_game(true)
   game.show_notebook("world")
  elif screen == "08-inspection":
   game.fly.position = Vector3(-85,89,1242)
   game.show_inspection("cup")
  for frame in range(3): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+screen+".png")
  print("UI CAPTURE: ",screen)
 game.queue_free()
 await process_frame
 quit()
