extends SceneTree
## Forward+ studio review of the separately exported furniture model scenes.
class AssetWorld extends "res://scripts/world.gd":
 func _ready(): pass
func _initialize(): call_deferred("run")
func run():
 root.size = Vector2i(1400,900)
 var world := AssetWorld.new()
 root.add_child(world)
 var env := WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("101a1f")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("b5c5cd")
 env.environment.ambient_light_energy = 0.5
 env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 if RenderingServer.get_current_rendering_method() == "forward_plus":
  env.environment.ssao_enabled = true
  env.environment.ssao_radius = 12
  env.environment.ssao_intensity = 1.2
  env.environment.ssao_detail = 0.6
 world.add_child(env)
 var key := DirectionalLight3D.new()
 key.rotation_degrees = Vector3(-55,-25,0)
 key.light_color = Color("ffe3bd")
 key.light_energy = 1.1
 key.shadow_enabled = true
 world.add_child(key)
 var fill := DirectionalLight3D.new()
 fill.rotation_degrees = Vector3(-30,135,0)
 fill.light_color = Color("bad4e2")
 fill.light_energy = 0.45
 world.add_child(fill)
 world.box(Vector3(0,-2,0),Vector3(500,4,400),Color("293333"))
 for model in [["walnut_table",Vector3(0,0,-20)],["parlour_chair",Vector3(100,0,0)],["chaise",Vector3(-115,0,10)]]:
  var instance: Node3D = load("res://assets/models/"+model[0]+".scn").instantiate()
  world.add_child(instance)
  instance.position = model[1]
 var camera := Camera3D.new()
 camera.near = 0.08
 camera.far = 2000
 camera.fov = 52
 world.add_child(camera)
 camera.current = true
 var output := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/assets"
 DirAccess.make_dir_recursive_absolute(output)
 var views := [
  ["furniture-front",Vector3(160,140,-265),Vector3(-15,52,0)],
  ["furniture-rear",Vector3(-180,140,255),Vector3(-15,52,0)],
  ["furniture-detail",Vector3(53,98,-82),Vector3(91,63,0)]
 ]
 for view in views:
  camera.position = view[1]
  camera.look_at(view[2])
  for frame in range(8): await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png(output+"/"+view[0]+".png")
  print("Furniture asset preview captured: ",view[0])
 quit()
