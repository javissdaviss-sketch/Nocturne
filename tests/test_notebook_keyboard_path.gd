extends SceneTree
## Exact production Notebook/Guide menu controls. No 3D, evidence or case writes.
class FixtureWorld extends Node3D:
 var hotspots:Dictionary={}
class Fixture extends "res://scripts/game.gd":
 func _ready()->void:
  world=FixtureWorld.new()
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
  var theme:=Theme.new()
  theme.default_font=SANS
  theme.default_font_size=17
  ui.theme=theme
  for kind in ["normal","hover","pressed","focus"]:
   var sb:=style(Color("25433c") if kind=="normal" else Color("466255"),1)
   theme.set_stylebox(kind,"Button",sb)
  setup_hud()
  set_process(false)
  resume_game()

var game:Fixture
var errors:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,reason:String)->void:
 if not ok:errors.append(reason)
func tap(code:Key)->void:
 for down in [true,false]:
  var e:=InputEventKey.new()
  e.keycode=code
  e.physical_keycode=code
  e.pressed=down
  root.push_input(e,true)
  await process_frame
func focused(caption:String)->bool:
 var target:=root.gui_get_focus_owner() as BaseButton
 return target!=null and target.text.begins_with(caption)
func tab_to(caption:String)->bool:
 for jump in range(12):
  if focused(caption):return true
  await tap(KEY_TAB)
 return false
func fallback_click(caption:String)->void:
 for control in game.modal.find_children("*","Button",true,false):
  if not control.text.begins_with(caption):continue
  var at:Vector2=control.get_global_rect().get_center()
  for down in [true,false]:
   var e:=InputEventMouseButton.new()
   e.position=at
   e.global_position=at
   e.button_index=MOUSE_BUTTON_LEFT
   e.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
   e.pressed=down
   root.push_input(e,true)
   await process_frame
  return
func run()->void:
 if FileAccess.file_exists("user://case.json"):
  push_error("Run in a new synthetic profile")
  quit(2);return
 game=Fixture.new()
 root.add_child(game)
 for target in [Vector2i(960,540),Vector2i(1280,800)]:
  root.size=target
  game.carriage_pin=-1
  await tap(KEY_J)
  check(game.mode=="notebook" and game.notebook_page=="","J did not open the original unspoiled objective")
  check(focused("Close"),str(target)+" notebook has no safe initial keyboard focus")
  await tap(KEY_ENTER)
  check(game.mode=="play" and game.carriage_pin==-1 and game.state.found.is_empty(),
   "Default Notebook Enter did not close without choosing anything")
  await tap(KEY_J)
  var guide_key:=await tab_to("CARRIAGE GUIDE")
  check(guide_key,str(target)+" keyboard could not reach the carriage guide")
  if guide_key:await tap(KEY_ENTER)
  else:await fallback_click("CARRIAGE GUIDE")
  check(game.notebook_page=="guide","Opened notebook guide did not show route panel")
  var pin_key:=await tab_to("08 · Winter garden")
  check(pin_key,str(target)+" keyboard could not reach the guide pin after menu rebuilt")
  if pin_key:await tap(KEY_ENTER)
  else:await fallback_click("08 · Winter garden")
  check(game.carriage_pin==2 and game.notebook_page=="guide","Guide pin did not take effect")
  check(focused("Close"),"Guide rebuild after the pin lost its safe available focus")
  await tap(KEY_J)
  check(game.mode=="play" and game.carriage_pin==2,"J could not return to ungated flight with the opt-in pin")
  check(game.state.found.is_empty() and not FileAccess.file_exists("user://case.json"),"Guide access made a finding or changed the save")
 await tap(KEY_J)
 await fallback_click("CARRIAGE GUIDE")
 check(game.notebook_page=="guide","Existing mouse click to open guide stopped")
 await fallback_click("Clear pin")
 check(game.carriage_pin==-1,"Existing mouse click to clear pin stopped")
 await tap(KEY_J)
 game.state.discover("cup")
 await tap(KEY_TAB)
 check(game.mode=="deduction","Keyboard did not open the unsent deduction")
 game.suspect_select.select(2)
 game.motive_select.select(3)
 game.evidence_checks.cup.button_pressed=true
 await tap(KEY_J)
 check(game.mode=="notebook" and focused("Back to deduction"),
  "Notebook launched from deduction lacks a safe return keyboard target")
 await tap(KEY_ENTER)
 check(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==3
  and game.evidence_checks.cup.button_pressed,"Keyboard Back did not preserve the actual deduction draft")
 check(not FileAccess.file_exists("user://case.json"),"Notebook and draft keyboard actions wrote a save")
 print("NOTEBOOK_KEYBOARD dimensions=2 issues=",errors)
 game.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 4)
