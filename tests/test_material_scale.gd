extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 if RenderingServer.get_current_rendering_method() != "forward_plus":
  printerr("FAIL: material scale needs an actual Forward+ frame")
  quit(1)
  return
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
 root.content_scale_size = Vector2i.ZERO
 root.size = Vector2i(512,256)
 var scene := Node3D.new()
 root.add_child(scene)
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.background_mode = Environment.BG_COLOR
 environment.environment.background_color = Color("101c22")
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color.WHITE
 environment.environment.ambient_light_energy = 1.0
 scene.add_child(environment)
 var material := ShaderMaterial.new()
 material.shader = preload("res://shaders/cabin_surfaces.gdshader")
 material.set_shader_parameter("finish",2)
 material.set_shader_parameter("finish_color",Color("66503c"))
 material.set_shader_parameter("wood_texture",preload("res://assets/textures/table_mahogany_albedo.png"))
 var unbatched: MeshInstance3D
 for x in [-55,55,200]:
  var node := MeshInstance3D.new()
  var mesh := BoxMesh.new()
  mesh.size = Vector3(80,40,60)
  node.mesh = mesh
  node.material_override = material
  scene.add_child(node)
  node.position.x = x
  if x == -55: unbatched = node
 preload("res://scripts/interior_batches.gd").new().build(scene,[unbatched])
 var camera := Camera3D.new()
 scene.add_child(camera)
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 110
 camera.position = Vector3(0,0,300)
 camera.look_at(Vector3.ZERO)
 camera.current = true
 for _i in range(8): await process_frame
 await RenderingServer.frame_post_draw
 var picture := root.get_texture().get_image()
 var error := 0.0
 var samples := 0
 var minimum := 1.0
 var maximum := 0.0
 var batch_minimum := 1.0
 var batch_maximum := 0.0
 for x in range(70,185,3):
  for y in range(95,160,3):
   var a := picture.get_pixel(x,y)
   var b := picture.get_pixel(x+256,y)
   error += absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
   minimum = minf(minimum,a.get_luminance())
   maximum = maxf(maximum,a.get_luminance())
   batch_minimum = minf(batch_minimum,b.get_luminance())
   batch_maximum = maxf(batch_maximum,b.get_luminance())
   samples += 3
 error /= samples
 var output := OS.get_environment("NOCTURNE_ART_OUTPUT")
 if not output.is_empty():
  DirAccess.make_dir_recursive_absolute(output)
  picture.save_png(output+"/material-scale.png")
 var failed := error>0.002 or maximum-minimum<0.02 or batch_maximum-batch_minimum<(maximum-minimum)*0.8
 print("TEXTURE SCALE mean error=",error," range=",maximum-minimum)
 if failed: printerr("FAIL: batching changed physical wood texture scale or flattened its detail")
 else: print("PASS: authored and batched wood surfaces retain the same physical texture detail")
 scene.queue_free()
 await process_frame
 quit(1 if failed else 0)
