extends SceneTree
## Real viewport key routing and standard Button focus in production titles.
## Only the action sink is substituted, so this can run without a 3D World.
class TitleFixtureWorld extends Node3D:
 var hotspots: Dictionary = {}
class TitleGame extends "res://scripts/game.gd":
 var starts: Array[bool] = []
 func _ready() -> void:
  world=TitleFixtureWorld.new()
  add_child(world)
  fly=Fly.new()
  add_child(fly)
  fly.set_physics_process(false)
  canvas=CanvasLayer.new()
  add_child(canvas)
  ui=Control.new()
  ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
  ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  canvas.add_child(ui)
  setup_hud()
  set_process(false)
  show_title()
 func start_game(fresh: bool) -> void:
  starts.append(fresh)
  clear_modal()
  mode = "keyboard_test_action"

const Save = preload("res://scripts/case_state.gd")
var problems: Array[String] = []
var game: TitleGame

func _initialize() -> void:
 call_deferred("run")

func expect(ok: bool, description: String) -> void:
 if not ok: problems.append(description)

func focused(label: String) -> bool:
 var current := root.gui_get_focus_owner() as Button
 return current != null and current.text.begins_with(label)

func key(code: Key, shift: bool = false) -> void:
 for is_down in [true,false]:
  var event := InputEventKey.new()
  event.keycode = code
  event.physical_keycode = code
  event.shift_pressed = shift
  event.pressed = is_down
  root.push_input(event,true)
  await process_frame

func run() -> void:
 if FileAccess.file_exists(Save.PATH):
  push_error("Use a fresh isolated synthetic profile for the title keyboard test")
  quit(2)
  return
 root.size=Vector2i(1280,800)
 game=TitleGame.new()
 root.add_child(game)
 await process_frame
 expect(focused("BEGIN INVESTIGATION"),"fresh title has no default Begin focus")
 await key(KEY_ENTER)
 expect(game.starts == [true],"fresh Enter did not start via the focus/button route")
 expect(not FileAccess.file_exists(Save.PATH),"focus or synthetic action wrote to an empty profile")
 var old:=Save.new()
 old.discover("cup")
 if old.save_to() != OK:
  push_error("Could not create synthetic previous-case state")
  quit(3)
  return
 var original:=FileAccess.get_file_as_string(Save.PATH)
 game.starts.clear()
 game.show_title()
 await process_frame
 expect(focused("Continue"),"returning title has no default Continue focus")
 await key(KEY_ENTER)
 expect(game.starts == [false],"returning Enter did not route to Continue")
 game.starts.clear()
 game.show_title()
 await process_frame
 # Prev moves from the Continue button to the deliberately armed Begin button.
 await key(KEY_TAB,true)
 expect(focused("BEGIN INVESTIGATION"),"Shift+Tab did not reach Begin from Continue")
 await key(KEY_ENTER)
 # Run preservation assertions even when the baseline has already failed
 # to provide the safe title focus.
 expect(game.mode=="new_case_confirm","keyboard Begin did not show explicit save-loss confirmation")
 if game.mode!="new_case_confirm":
  game.request_new_case()
 await process_frame
 expect(focused("Cancel"),"save-loss dialog did not default to Cancel")
 await key(KEY_ENTER)
 expect(game.mode=="title" and game.starts.is_empty(),"Enter in confirmation did not safely cancel")
 expect(focused("Continue"),"dialog cancel did not restore Continue focus")
 expect(FileAccess.get_file_as_string(Save.PATH)==original,"synthetic save bytes changed")
 print("TITLE_KEYBOARD checks=11 problems=",problems)
 game.queue_free()
 await process_frame
 quit(0 if problems.is_empty() else 4)
