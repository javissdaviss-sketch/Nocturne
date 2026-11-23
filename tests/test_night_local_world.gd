extends SceneTree
const SavedState = preload("res://scripts/case_state.gd")
var failures: Array[String] = []
var game: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, message: String) -> void:
 if not ok: failures.append(message)
func settle() -> void:
 await physics_frame
 await process_frame
 await physics_frame
 await process_frame

func run() -> void:
 # This only runs with a brand-new XDG test profile. Do not replace another
 # save or configuration file, and exercise the real Settings controls.
 var settings_path := "user://settings.cfg"
 if FileAccess.file_exists(settings_path) or FileAccess.file_exists(SavedState.PATH):
  push_error("Night Local fixture requires a fresh isolated user profile")
  quit(3);return
 var cfg:=ConfigFile.new()
 cfg.set_value("game","atmosphere",false)
 if cfg.save(settings_path)!=OK:
  quit(3);return
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading": await game.investigation_ready
 game.start_game(true)
 var original_lights: int = game.world.find_children("*","Light3D",true,false).size()
 var original_hotspots: int = game.world.hotspots.size()
 var local: Node3D = game.world.scenery.night_local
 check(game.options.atmosphere==false and not local.ambient_enabled and not local.visible,
  "Actual saved atmosphere preference applies before the title")
 game.fly.active = false
 game.fly.restore_pending = false
 var before_preferences := FileAccess.get_file_as_bytes(SavedState.PATH)
 game.show_settings()
 var atmospheric: CheckBox
 var explicit_train: CheckBox
 var save_settings: Button
 for button: Button in game.modal.find_children("*","Button",true,false):
  if button.text=="Rain & atmosphere": atmospheric=button as CheckBox
  if button.text=="Passing train": explicit_train=button as CheckBox
  if button.text=="Save & return": save_settings=button
 if is_instance_valid(atmospheric) and is_instance_valid(explicit_train) and is_instance_valid(save_settings):
  check(not explicit_train.button_pressed and not game.options.passing_train,
   "Legacy settings with no passing-train key start explicitly off")
  atmospheric.button_pressed=true
  check(game.options.atmosphere and not local.ambient_enabled and not local.visible,
   "Restoring the existing rain setting must never opt the player in")
  game.world.scenery.observe_salon_view(Vector3(-448,119,1127),Vector3.LEFT)
  check(not local.played,"Even looking out the correct window must not trigger without opt-in")
  explicit_train.button_pressed=true
  check(game.options.passing_train and local.ambient_enabled,
   "Explicit optional setting starts eligible but remains dormant until valid view")
  save_settings.pressed.emit()
  var saved_settings:=ConfigFile.new()
  check(saved_settings.load(settings_path)==OK and saved_settings.get_value("game","atmosphere",false)==true and saved_settings.get_value("game","passing_train",false)==true,
   "Actual Save & return preserves the matching setting")
 else:
  failures.append("Cannot resolve exact in-game Settings controls")
 check(FileAccess.get_file_as_bytes(SavedState.PATH)==before_preferences,"Settings do not change case data")
 game.resume_game()
 game.fly.active = false
 game.fly.global_position = Vector3(-444,154,2230)
 game.fly.camera.look_at(Vector3(-500,141,2257))
 await settle()
 check(not local.played and not local.visible,"Unrelated Garden window remains dormant with effects enabled")
 game.fly.global_position = Vector3(-448,119,1127)
 game.fly.camera.global_position = Vector3(-448,119,1127)
 game.fly.camera.look_at(Vector3(-400,125,1146))
 await settle()
 check(not local.played,"Getting near the bay is not enough while looking into the train")
 game.show_pause()
 game.fly.camera.look_at(Vector3(-500,125,1146))
 await settle()
 check(not local.played,"A menu cannot start the visual crossing")
 game.options.atmosphere = false
 game.apply_settings()
 game.resume_game()
 game.fly.active = false
 var exterior_z: float = game.world.scenery.layers[0].position.z
 await settle()
 check(not local.played and not local.visible and game.world.scenery.layers[0].position.z!=exterior_z,"Atmosphere off hides crossing without freezing the base 3D city")
 var saved_before := FileAccess.get_file_as_bytes(SavedState.PATH)
 game.options.atmosphere = true
 game.apply_settings()
 await settle()
 check(local.played and local.in_motion and local.visible,"Facing open salon view in play briefly admits the separate passing train")
 var hit: KinematicCollision3D = game.fly.move_and_collide(Vector3(-175,0,0),true)
 check(hit!=null and hit.get_position().x>-520.0,"A cosmetic neighbor cannot alter the actual sealed window collision")
 game.options.atmosphere = false
 game.apply_settings()
 await settle()
 game.options.atmosphere = true
 game.apply_settings()
 await settle()
 check(local.played and not local.visible and not local.in_motion,"Effect toggle cannot resurrect a partly seen crossing")
 game.options.passing_train=false
 game.apply_settings()
 check(game.options.atmosphere and not local.ambient_enabled and game.world.scenery.effects_enabled,
  "Turning this encounter off must not disable city atmosphere")
 check(FileAccess.get_file_as_bytes(SavedState.PATH)==saved_before and game.state.found.is_empty(),"The visual pass cannot write or add evidence")
 check(game.world.find_children("*","Light3D",true,false).size()==original_lights and game.world.hotspots.size()==original_hotspots and original_hotspots==21,"No new light or case hotspot")
 game.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: saved setting restore, real Settings save, far/window viewport gates, original glass collider, unchanged city, no case writes")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
