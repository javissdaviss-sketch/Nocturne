extends SceneTree
## Repeatable art review. Run with a real display and isolated user data.
class RenderOnlyPhysics extends RefCounted:
 func build(_root: Node3D, _exclusions: Array[Node] = []) -> Dictionary: return {}
const World = preload("res://scripts/world.gd")
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 if "--ui" in OS.get_cmdline_user_args():
  await capture_ui()
  return
 var world := World.new()
 if "--render-only" in OS.get_cmdline_user_args(): world.solid_geometry = RenderOnlyPhysics.new()
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
 if "--complete" in OS.get_cmdline_user_args():
  views.append_array([
   ["09-chaise",Vector3(196,128,25),Vector3(107,48,100),""],
   ["10-terminal",Vector3(168,125,598),Vector3(102,90,655),""],
   ["11-reception",Vector3(-210,149,863),Vector3(-410,87,916),""],
   ["12-galley",Vector3(-205,147,1405),Vector3(-410,80,1515),""],
   ["13-service-closed",Vector3(66,83,1400),Vector3(118,45,1462),""],
   ["14-service-open",Vector3(66,83,1400),Vector3(118,45,1462),"cabinet"],
   ["15-dispatch-closed",Vector3(-72,118,2170),Vector3(-100,84,2235),""],
   ["16-dispatch-open",Vector3(-72,118,2170),Vector3(-100,84,2235),"dispatch"],
   ["17-resident-face",Vector3(97,156,476),Vector3(112,151,530),""],
   ["18-chemical-close",Vector3(114,50,1440),Vector3(121,44,1460),"cabinet"]
  ])
 for view in views:
  var selected := true
  for argument in OS.get_cmdline_user_args():
   if argument.begins_with("--only="):
    selected = view[0] in argument.trim_prefix("--only=").split(",")
  if not selected: continue
  if view.size() > 3:
   camera.fov = 65
   if view[3] == "cabinet": world.unlock_cabinet()
   elif view[3] == "dispatch": world.unlock_dispatch()
  camera.position = view[1]
  camera.look_at(view[2])
  for frame in range(3): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+view[0]+".png")
  print("ART CAPTURE: ",view[0]," draw calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
 world.queue_free()
 for frame in range(3): await process_frame
 quit()

func capture_ui() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 var output := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/luxe"
 DirAccess.make_dir_recursive_absolute(output)
 for screen in ["06-title","07-world-notebook","08-inspection"]:
  if screen == "07-world-notebook":
   # Smoke tests cover fresh-world replacement; this harness reuses the scene.
   game.start_game(false)
   game.show_notebook("world")
  elif screen == "08-inspection":
   game.fly.position = Vector3(-85,89,1242)
   game.show_inspection("cup")
  for frame in range(3): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+screen+".png")
  print("UI CAPTURE: ",screen)
 if "--detail" in OS.get_cmdline_user_args():
  game.set_process(false)
  game.fly.active = false
  game.ui.visible = false
  var detail := Camera3D.new()
  detail.near = 0.08
  detail.far = 6000
  detail.fov = 60
  game.world.add_child(detail)
  detail.position = Vector3(-70,99,1024)
  detail.look_at(Vector3(-95,81,1050))
  detail.current = true
  for frame in range(3): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/09-dining-roll.png")
  print("ART CAPTURE: 09-dining-roll")
 game.queue_free()
 await process_frame
 quit()
