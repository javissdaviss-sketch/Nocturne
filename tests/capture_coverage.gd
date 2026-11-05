extends SceneTree
## Extended visual audit of the original investigation rooms and their props.
## Run in Forward+ with an isolated XDG_DATA_HOME. --ui captures conversations.
## Optional --only=01-chaise,04-chess limits expensive renders during refinement.
const World = preload("res://scripts/world.gd")
var output := ""

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 output = OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/coverage"
 DirAccess.make_dir_recursive_absolute(output)
 root.size = Vector2i(1440,900)
 if "--ui" in OS.get_cmdline_user_args():
  await capture_conversations()
  return
 var world := World.new()
 root.add_child(world)
 var camera := Camera3D.new()
 camera.near = 0.08
 camera.far = 8000
 camera.fov = 65
 world.add_child(camera)
 camera.current = true
 var views := [
  ["01-chaise",Vector3(196,128,25),Vector3(107,48,100),""],
  ["02-terminal",Vector3(168,125,598),Vector3(102,90,655),""],
  ["03-radio",Vector3(77,111,250),Vector3(119,91,287),""],
  ["04-chess",Vector3(-156,117,91),Vector3(-102,81,140),""],
  ["05-trolley",Vector3(210,112,1075),Vector3(125,40,1010),""],
  ["06-reception",Vector3(-210,149,863),Vector3(-410,87,916),""],
  ["07-galley",Vector3(-205,147,1405),Vector3(-410,80,1515),""],
  ["08-service-closed",Vector3(66,83,1400),Vector3(118,45,1462),""],
  ["09-service-open",Vector3(66,83,1400),Vector3(118,45,1462),"cabinet"],
  ["10-dispatch-closed",Vector3(-72,118,2170),Vector3(-100,84,2235),""],
  ["11-dispatch-open",Vector3(-72,118,2170),Vector3(-100,84,2235),"dispatch"],
  ["12-resident-face",Vector3(97,156,476),Vector3(112,151,530),""],
  ["16-lian-feet",Vector3(80,48,2064),Vector3(113,28,2110),""],
  ["17-lian-full",Vector3(250,115,2059),Vector3(112,86,2110),""],
  ["18-rack-supports",Vector3(205,261,274),Vector3(145,260,334),""],
  ["19-reading-console",Vector3(225,102,384),Vector3(147,36,414),""],
  ["20-pot-contact",Vector3(265,87,2118),Vector3(303,72,2116),""],
  ["21-mara-full",Vector3(265,118,1115),Vector3(113,86,1150),""],
  ["22-ivo-full",Vector3(265,118,515),Vector3(112,86,530),""]
 ]
 for view in views:
  if not selected(view[0]): continue
  if view[3] == "cabinet": world.unlock_cabinet()
  elif view[3] == "dispatch": world.unlock_dispatch()
  camera.position = view[1]
  camera.look_at(view[2])
  await capture(view[0])
 world.queue_free()
 for frame in range(3): await process_frame
 quit()

func selected(label: String) -> bool:
 for argument in OS.get_cmdline_user_args():
  if argument.begins_with("--only="):
   return label in argument.trim_prefix("--only=").split(",")
 return true

func capture(label: String) -> void:
 for frame in range(4): await process_frame
 await RenderingServer.frame_post_draw
 var result := root.get_texture().get_image().save_png(output+"/"+label+".png")
 if result != OK:
  push_error("Coverage capture failed: "+label)
  quit(1)
 print("COVERAGE CAPTURE: ",label," draw calls=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)," primitives=",RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))

func capture_conversations() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 game.start_game(false)
 for person in [["13-engineer-conversation","engineer",Vector3(112,135,465)],["14-steward-conversation","steward",Vector3(113,135,1085)],["15-botanist-conversation","botanist",Vector3(112,135,2045)]]:
  if not selected(person[0]): continue
  game.fly.position = person[2]
  game.show_inspection(person[1])
  await capture(person[0])
  game.resume_game()
 game.queue_free()
 for frame in range(3): await process_frame
 quit()
