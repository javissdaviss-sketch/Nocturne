extends SceneTree
const Identity := preload("res://scripts/room_identity.gd")
const Layout := preload("res://scripts/train_layout.gd")
const Fitted := preload("res://scripts/fitted_veneer.gd")
const Sleep := preload("res://scripts/sleeping_assets.gd")
class Stage extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var stage := Stage.new()
 root.add_child(stage)
 var rooms := Layout.new()
 stage.add_child(rooms)
 rooms.hospitality(stage,-1,990,1390)
 rooms.hospitality(stage,1,990,1390)
 var count := 0
 var unique: Dictionary = {}
 for table: Node in stage.get_children():
  if table.name == "CraftedWalnutTable" or table.has_node("MouldedWalnutTop"):
   var board := table.get_node("MouldedWalnutTop") as MeshInstance3D
   var finish := board.material_override as ShaderMaterial
   if finish.shader==Fitted.SHADER and finish.get_shader_parameter("strand_world").is_equal_approx(Vector3.BACK):
    count += 1
    unique[str(finish.get_shader_parameter("timber_tint"))]=true
 var wall := Identity.wall({"car":0,"side":-1,"lo":0}) as ShaderMaterial
 var outfit := Sleep.build_bed(stage,rooms,Vector3(-415,0,180),Identity.sleeping(-1,0))
 var head := outfit.get_node("ShapedHeadboard") as MeshInstance3D
 var timber := head.material_override as ShaderMaterial
 var success := count==4 and unique.size()==2 and wall.shader==Fitted.SHADER and timber.shader==Fitted.SHADER
 success=success and timber.get_shader_parameter("strand_world").is_equal_approx(Vector3.RIGHT) and wall.get_shader_parameter("strand_world").is_equal_approx(Vector3.UP)
 if success: print("PASS: 4 outer dining tops, 2 independent tones, headboard length grain and vertical wall grain; material-only."
  )
 else: push_error("large covered surfaces don't have their distinct physical grain mapping")
 stage.queue_free()
 await process_frame
 quit(0 if success else 1)
