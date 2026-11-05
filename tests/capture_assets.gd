extends SceneTree
## Separate asset review: studio material views and clay geometry view.
class StudioWorld:
 extends "res://scripts/world.gd"
 func _ready() -> void: pass
 func _process(_delta: float) -> void: pass
var w: Node3D
var subject: Node3D
var camera: Camera3D
var output: String
func _initialize() -> void: call_deferred("run")
func clay(node: Node, material: Material) -> void:
 if node is GeometryInstance3D: node.material_override = material
 for child in node.get_children(): clay(child,material)
func run() -> void:
 root.size = Vector2i(1200,1000)
 output = OS.get_environment("NOCTURNE_ART_OUTPUT")
 if output.is_empty(): output = "/workspace/previews/asset-review"
 DirAccess.make_dir_recursive_absolute(output)
 w = StudioWorld.new()
 root.add_child(w)
 var environment := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode = Environment.BG_COLOR
 e.background_color = Color("30383b")
 e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 e.ambient_light_color = Color("c3cbd0")
 e.ambient_light_energy = 0.42
 e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
 if RenderingServer.get_current_rendering_method() == "forward_plus":
  e.ssao_enabled = true
  e.ssao_radius = 9
  e.ssao_intensity = 1.0
 environment.environment = e
 w.add_child(environment)
 for rotation3 in [Vector3(-50,-35,0),Vector3(-25,135,0)]:
  var light := DirectionalLight3D.new()
  w.add_child(light)
  light.rotation_degrees = rotation3
  light.light_energy = 1.3 if rotation3.y < 0 else 0.55
  light.shadow_enabled = rotation3.y < 0
  light.shadow_bias = 0.12
 camera = Camera3D.new()
 camera.near = 0.08
 camera.far = 5000
 camera.fov = 42
 w.add_child(camera)
 camera.current = true
 var group := "hero"
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--group="): group = arg.trim_prefix("--group=")
 var names: Array[String] = ["terminal","bottle","document"]
 if group == "all": names = ["terminal","bottle","document","bed","wardrobe","counter","table","planter"]
 for name in names:
  subject = Node3D.new()
  w.add_child(subject)
  var scale := 55.0
  var target := Vector3(0,10,0)
  match name:
   "terminal": preload("res://scripts/hero_assets.gd").terminal(w,subject,Vector3(0,5,0))
   "bottle":
    preload("res://scripts/hero_assets.gd").chemical_bottle(w,subject,Vector3.ZERO)
    scale = 25
    target.y = 8
   "document":
    preload("res://scripts/hero_assets.gd").dispatch_cover(w,subject,Vector3(0,4,0))
    target.y = 4
   "bed":
    preload("res://scripts/sleeping_assets.gd").build_bed(w,subject,Vector3.ZERO)
    scale = 320
    target.y = 57
   "wardrobe":
    preload("res://scripts/cabinet_assets.gd").wardrobe(w,subject,Vector3.ZERO)
    scale = 330
    target.y = 112
   "counter":
    preload("res://scripts/cabinet_assets.gd").service_counter(w,subject,Vector3.ZERO,180,1)
    scale = 300
    target.y = 90
   "table":
    preload("res://scripts/furniture_models.gd").table(w,subject,110,100)
    scale = 170
    target.y = 40
   "planter":
    var planter := preload("res://scripts/garden_fixture_geometry.gd").new()
    subject.add_child(planter)
    planter.build_planter(Vector3.ZERO)
    scale = 230
    target.y = 33
  preload("res://scripts/material_library.gd").apply(subject)
  for angle in ["three-quarter","side","clay"]:
   if angle == "clay":
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("aaa69d")
    material.roughness = 0.72
    clay(subject,material)
   camera.position = target+Vector3(scale*0.76,scale*0.56,-scale) if angle != "side" else target+Vector3(scale*1.30,scale*0.20,0)
   camera.look_at(target)
   for i in range(5): await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png(output+"/"+name+"-"+angle+".png")
   print("ASSET CAPTURE: ",name," ",angle)
  subject.queue_free()
  await process_frame
 w.queue_free()
 await process_frame
 quit()
