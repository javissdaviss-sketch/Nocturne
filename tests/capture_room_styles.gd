extends SceneTree
## Diagnostic actual renderer; no case/saves and collision compilation is skipped.
## Run only requested 2–4 viewpoints per session. The exact same file/poses
## can be used back on a baseline with --script /absolute/shared/script.gd.
class RenderOnlyPhysics extends RefCounted:
 func build(_root: Node3D,_exclusions: Array[Node] = []) -> Dictionary: return {}

const World := preload("res://scripts/world.gd")
# Nominal local photos model a fly pausing at furniture/room level rather than
# front-on elevations. A room camera may still need adjustment after first QA;
# then update it on both sides of any comparison.
const ROOMS := {
 "06-l-writing-desk": [Vector3(-230,57,125),Vector3(-299,56,81),57.0],
 "06-l-coast-desk": [Vector3(-234,51,488),Vector3(-302,43,450),56.0],
 "06-r-crew-desk": [Vector3(230,53,125),Vector3(299,46,81),57.0],
 "06-r-maintenance-desk": [Vector3(243,52,487),Vector3(316,48,458),56.0],
 "08-r-potting-bench": [Vector3(109,91,1846),Vector3(151,65,1822),59.0],
 "08-l-orchid-stand": [Vector3(-109,103,1869),Vector3(-157,89,1892),59.0],
 "06-l-writing": [Vector3(-268,128,236),Vector3(-412,102,98),65.0],
 "06-r-crew": [Vector3(251,136,217),Vector3(414,107,100),65.0],
 "06-l-coast": [Vector3(-273,131,664),Vector3(-416,102,493),65.0],
 "06-r-maintenance": [Vector3(266,128,645),Vector3(414,104,494),65.0],
 "07-l-concierge": [Vector3(-279,142,908),Vector3(-383,125,973),62.0],
 "07-r-cloakroom": [Vector3(277,142,905),Vector3(376,125,974),62.0],
 "07-l-meridian": [Vector3(-243,133,1137),Vector3(-339,113,1355),67.0],
 "07-r-tea": [Vector3(254,137,1106),Vector3(348,130,1379),66.0],
 "07-l-pantry-prep": [Vector3(-318,126,1550),Vector3(-392,101,1518),57.0],
 "07-r-steward-tray": [Vector3(306,127,1569),Vector3(387,99,1525),56.0],
 "07-l-pantry": [Vector3(-277,135,1479),Vector3(-380,125,1624),63.0],
 "07-r-steward": [Vector3(271,146,1483),Vector3(375,143,1622),63.0],
 "08-l-orchid": [Vector3(-295,119,1918),Vector3(-376,114,2006),64.0],
 "08-r-potting": [Vector3(260,151,1784),Vector3(377,124,1985),65.0],
 "08-l-heritage": [Vector3(-261,145,2220),Vector3(-357,115,2445),66.0],
 "08-r-reserve": [Vector3(271,133,2222),Vector3(368,122,2442),66.0],
 "cup-table": [Vector3(-80,86,1236),Vector3(-88,82,1250),58.0],
 "walnut-trim": [Vector3(-32,35,1061),Vector3(-56,29,1107),56.0],
 "archive-vestibule": [Vector3(0,121,1530),Vector3(0,125,1631),58.0]
}

func _initialize() -> void: call_deferred("run")

func run() -> void:
 if DisplayServer.get_name()=="headless":
  push_error("Run the room art QA with a supported native graphical driver.")
  quit(2)
  return
 var selected := PackedStringArray()
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--only="): selected=arg.trim_prefix("--only=").split(",")
 if selected.is_empty() or selected.size()>4:
  push_error("Select 1 to 4 named views from ROOMS; avoid overlapping native/physics scenes.")
  quit(2)
  return
 var folder := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if folder.is_empty():
  push_error("Use an isolated, exact-revision NOCTURNE_ART_OUTPUT.")
  quit(2)
  return
 DirAccess.make_dir_recursive_absolute(folder)
 root.size = Vector2i(1280,800)
 var world := World.new()
 world.solid_geometry = RenderOnlyPhysics.new()
 root.add_child(world)
 var exterior = world.scenery
 exterior.set_process(false)
 for layer in exterior.layers: layer.position.z = 0
 exterior.update_salon_spill(0.0)
 if is_instance_valid(world.rain_windows): world.rain_windows.set_process(false)
 var view := Camera3D.new()
 view.near = 0.08
 view.far = 8000
 world.add_child(view)
 view.current = true
 var verified := []
 for key in selected:
  if not ROOMS.has(key):
   push_error("Unknown exact camera: "+key)
   quit(2)
   return
  var pose: Array = ROOMS[key]
  view.position = pose[0]
  view.look_at(pose[1],Vector3.UP)
  view.fov = pose[2]
  await process_frame
  await RenderingServer.frame_post_draw
  var image := root.get_texture().get_image()
  var status := image.save_png(folder+"/"+key+".png")
  print("ROOM_ART ",JSON.stringify({"id":key,"pose":str(pose),"format":str(image.get_size()),"gpu":RenderingServer.get_current_rendering_method(),"png":status, "visible_tris":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"visible_draws":root.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME)}))
  if status!=OK:
   quit(3)
   return
  verified.append(key)
 print("ROOM_ART_DONE ",str(verified))
 world.queue_free()
 await process_frame
 quit(0)
