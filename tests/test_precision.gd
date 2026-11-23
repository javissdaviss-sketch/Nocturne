extends SceneTree
## Drive the actual fly's input and physics methods without a display or train.
const Fly = preload("res://scripts/fly.gd")
var fly: CharacterBody3D

func _initialize() -> void:
 call_deferred("run")

func shift(pressed: bool, repeat: bool = false) -> void:
 var event := InputEventKey.new()
 event.physical_keycode = KEY_SHIFT
 event.keycode = KEY_SHIFT
 event.pressed = pressed
 event.echo = repeat
 Input.parse_input_event(event)
 Input.flush_buffered_events()

func frame() -> void:
 await physics_frame
 await process_frame

func run() -> void:
 fly = Fly.new()
 root.add_child(fly)
 fly.active = true
 await frame()
 assert(not fly.precision_toggle and not fly.precision)
 shift(true)
 await frame()
 assert(fly.precision and not fly.precision_latched)
 shift(false)
 await frame()
 assert(not fly.precision)
 fly.set_precision_toggle(true)
 shift(true)
 await frame()
 assert(fly.precision and fly.precision_latched)
 shift(true,true)
 shift(false)
 await frame()
 assert(fly.precision, "Release and typematic repeat must not cancel toggle")
 fly.active = false
 shift(true)
 shift(false)
 await frame()
 assert(fly.precision_latched, "Menu input must not affect active preference")
 fly.active = true
 fly.inspection = true
 shift(true)
 shift(false)
 await frame()
 assert(fly.precision_latched, "Inspection input must not toggle flight speed")
 fly.inspection = false
 shift(true)
 shift(false)
 await frame()
 assert(not fly.precision and not fly.precision_latched)
 shift(true)
 shift(false)
 await frame()
 fly.set_precision_toggle(false)
 assert(not fly.precision and not fly.precision_latched)
 fly.set_precision_toggle(true)
 shift(true)
 shift(false)
 await frame()
 fly.reset_precision()
 assert(not fly.precision and not fly.precision_latched)
 print("PASS: default Hold Shift, toggling and key repeat, modal isolation, preference and session reset")
 quit(0)
