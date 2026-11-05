extends SceneTree
## A real Forward+ frame catches unsupported drivers and shader/startup failures.
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 if RenderingServer.get_current_rendering_method() != "forward_plus":
  printerr("FAIL: realism validation requires Forward+")
  quit(1)
  return
 root.size = Vector2i(640,400)
 var world = load("res://scripts/world.gd").new()
 root.add_child(world)
 var camera := Camera3D.new()
 camera.near = 0.08
 camera.far = 6000
 world.add_child(camera)
 camera.position = Vector3(-73,92,1226)
 camera.look_at(Vector3(-88,82,1250))
 camera.current = true
 for i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 var frame := root.get_texture().get_image()
 var darkest := 1.0
 var lightest := 0.0
 for x in range(20,620,20):
  for y in range(20,380,20):
   var color := frame.get_pixel(x,y)
   var value := color.get_luminance()
   darkest = minf(darkest,value)
   lightest = maxf(lightest,value)
 if lightest-darkest < 0.15 or lightest < 0.25:
  printerr("FAIL: rendered evidence frame lacks readable tonal detail")
  quit(1)
  return
 print("PASS: Forward+ rendered a readable evidence frame with SSAO, SSIL and room reflections")
 world.queue_free()
 await process_frame
 quit()
