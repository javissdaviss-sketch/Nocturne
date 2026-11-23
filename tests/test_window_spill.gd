extends SceneTree
const Exterior = preload("res://scripts/exterior.gd")

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 var exterior := Exterior.new()
 root.add_child(exterior)
 exterior.set_process(false)
 exterior.sign_sources = [{"side":-1,"z":Exterior.SALON_BAY_Z-1250.0,"tint":Color("55cbd2")}]
 exterior.build_salon_spill()
 var left: SpotLight3D = exterior.spill_lights[0]
 var right: SpotLight3D = exterior.spill_lights[1]
 assert(not left.shadow_enabled and not right.shadow_enabled)
 assert(absf(left.global_position.x)-left.spot_range > 350.0, "Spill cannot reach the interior evidence tables")
 exterior.update_salon_spill(1250.0)
 assert(is_equal_approx(left.light_energy,Exterior.MAX_SPILL_ENERGY) and right.light_energy==0.0)
 var near_color := left.light_color
 assert(near_color.b > near_color.r, "Left sign causes teal, not a global neutral flash")
 exterior.update_salon_spill(1250.0+Exterior.PERIOD)
 assert(is_equal_approx(left.light_energy,Exterior.MAX_SPILL_ENERGY), "District wrap is continuous")
 exterior.update_salon_spill(1460.0)
 assert(left.light_energy>0.0 and left.light_energy<Exterior.MAX_SPILL_ENERGY)
 exterior.update_salon_spill(1710.0)
 assert(left.light_energy == 0.0)
 exterior.set_effects_enabled(false)
 exterior.update_salon_spill(1250.0)
 assert(not left.visible and left.light_energy == 0.0 and not right.visible)
 exterior.clock = 1250.0/Exterior.TRAIN_SPEED
 exterior.set_effects_enabled(true)
 assert(left.visible and left.light_energy>0.0 and right.light_energy==0.0)
 print("PASS: bounded bay lighting follows same-side signs and train wrap, falls to zero and respects atmosphere off")
 quit(0)
