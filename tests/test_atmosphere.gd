extends SceneTree
## Run with separate XDG_DATA_HOME: this checks the real settings save/load flow.
var failures: Array[String] = []

func check(value: bool, message: String) -> void:
 if not value:
  failures.append(message)
  printerr("FAIL: ",message)

func _initialize() -> void:
 call_deferred("run")

func find_text(node: Node, text: String) -> BaseButton:
 if node is BaseButton and node.text == text: return node
 for child in node.get_children():
  var found := find_text(child,text)
  if found != null: return found
 return null

func check_enabled(game: Node, enabled: bool) -> void:
 check(game.world.rain_windows.visible == enabled,"Window rain follows atmosphere setting")
 check(game.world.environment.fog_enabled == enabled,"Distance haze follows atmosphere setting")
 for emitter in game.world.atmosphere.emitters:
  check(emitter.emitting == enabled and emitter.is_visible_in_tree() == enabled,"Particle emission and rendering follow atmosphere setting")
 for halo in game.world.scenery.halos:
  check(halo.is_visible_in_tree() == enabled,"Neon halos follow atmosphere setting")

func run() -> void:
 # An existing player's settings file has no atmosphere key yet.
 var old_settings := ConfigFile.new()
 old_settings.set_value("game","shadows",false)
 old_settings.save("user://settings.cfg")
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(bool(game.options.atmosphere),"Existing settings default to enabled atmosphere")
 check(not bool(game.options.shadows),"Existing graphics preferences are preserved")
 check_enabled(game,true)
 # Even the worst random spread must leave every exterior drop outside glass.
 for emitter in game.world.atmosphere.emitters:
  if not emitter.name.begins_with("ExteriorRain"): continue
  var sideways_travel: float = sin(deg_to_rad(emitter.spread))*emitter.initial_velocity_max*emitter.lifetime
  sideways_travel += abs(emitter.gravity.x)*emitter.lifetime*emitter.lifetime*0.5
  var nearest_x: float = abs(emitter.global_position.x)-emitter.emission_box_extents.x-sideways_travel
  check(nearest_x > 515.0,"Exterior rain cannot enter the sealed cabin at maximum spread")
 game.show_settings()
 var toggle := find_text(game,"Rain & atmosphere") as CheckBox
 check(toggle != null,"Atmosphere toggle is reachable in settings")
 if toggle != null: toggle.button_pressed = false
 await process_frame
 check_enabled(game,false)
 var save := find_text(game,"Save & return")
 check(save != null,"Settings save action is reachable")
 if save != null: save.pressed.emit()
 game.queue_free()
 await process_frame
 game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(not bool(game.options.atmosphere),"Disabled atmosphere survives application restart")
 check_enabled(game,false)
 game.show_settings()
 toggle = find_text(game,"Rain & atmosphere") as CheckBox
 if toggle != null: toggle.button_pressed = true
 await process_frame
 check_enabled(game,true)
 game.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: rain stays outside, existing settings migrate, atmosphere toggles emission/visibility and survives restart")
 quit(0 if failures.is_empty() else 1)
