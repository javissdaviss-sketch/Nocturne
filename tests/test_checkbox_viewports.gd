extends SceneTree
## Mount exact production controls without a 3D scene, exercising actual
## minimum sizes, viewport transforms, input hit targets and their signals.
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
   theme.set_stylebox(kind,"OptionButton",sb)
  theme.set_color("font_color","Button",PAPER)
  theme.set_color("font_hover_color","Button",GOLD)
  theme.set_color("font_color","OptionButton",PAPER)
  theme.set_constant("h_separation","BoxContainer",12)
  setup_hud()
  set_process(false)
 func apply_settings()->void:
  pass # Exercise actual check callbacks, not real world lighting or disk.

var game:Fixture
var issues:Array[String]=[]
var views_done:=0
var actions_done:=0
func _initialize()->void:call_deferred("run")
func require(ok:bool, note:String)->void:
 if not ok:issues.append(note)

func controls_inside(control:Control, note:String)->void:
 var logical:=control.get_global_rect()
 var transform:=root.get_stretch_transform()
 var a:=transform*logical.position
 var b:=transform*logical.end
 require(Rect2(Vector2.ZERO,Vector2(root.size)).encloses(Rect2(a,b-a)),note+" outside viewport pixels")

func require_clear(button_a:Button,button_b:Button,note:String)->void:
 var a:=button_a.get_global_rect()
 var b:=button_b.get_global_rect()
 require(not a.intersects(b),note+" hit targets overlap "+
  str(a.intersection(b).size)+" each "+str(a.size)+" / "+str(b.size))

func locate(label:String)->CheckBox:
 for child in game.modal.find_children("*","CheckBox",true,false):
  if child.text==label:return child
 return null

func click_bottom(control:CheckBox)->void:
 var r:=control.get_global_rect()
 var point:=Vector2(r.position.x+18,r.end.y-4)
 for pressed in [true,false]:
  var event:=InputEventMouseButton.new()
  event.position=point
  event.global_position=point
  event.button_index=MOUSE_BUTTON_LEFT
  event.button_mask=MOUSE_BUTTON_MASK_LEFT if pressed else 0
  event.pressed=pressed
  root.push_input(event,true)
  await process_frame

func run()->void:
 if FileAccess.file_exists("user://settings.cfg") or FileAccess.file_exists("user://case.json"):
  push_error("Use an isolated asset-free synthetic user profile")
  quit(2);return
 game=Fixture.new()
 root.add_child(game)
 for target in [Vector2i(960,540),Vector2i(1280,800),Vector2i(1440,900),Vector2i(1920,1080)]:
  root.size=target
  await process_frame
  var tag:=str(target)
  require(root.size==target,"Wrong actual viewport "+tag)
  game.options.passing_train=false
  game.options.shadows=true
  game.options.atmosphere=true
  game.show_settings()
  await process_frame
  var train:=locate("Passing train")
  var shadows:=locate("Enable shadows")
  var rain:=locate("Rain & atmosphere")
  if train==null or shadows==null or rain==null:
   push_error("Settings controls missing")
   quit(2);return
  require_clear(train,shadows,tag+" passing train/shadows")
  require_clear(shadows,rain,tag+" shadows/rain")
  for c in [train,shadows,rain]:controls_inside(c,tag+" settings "+c.text)
  await click_bottom(train)
  require(game.options.passing_train and game.options.shadows and game.options.atmosphere,
   tag+" clicking bottom of Passing train hit its neighbor")
  await click_bottom(shadows)
  require(game.options.passing_train and not game.options.shadows and game.options.atmosphere,
   tag+" clicking Shadows changed the wrong choice")
  await click_bottom(rain)
  require(game.options.passing_train and not game.options.shadows and not game.options.atmosphere,
   tag+" clicking Rain changed the wrong choice")
  actions_done+=3
  game.state.found=game.Data.ESSENTIAL.duplicate()
  game.deduction_draft.clear()
  game.show_deduction()
  await process_frame
  var ordered:Array=game.evidence_checks.values()
  require(ordered.size()==6,tag+" six found checks")
  for i in range(ordered.size()):
   var c:CheckBox=ordered[i]
   controls_inside(c,tag+" deduction row "+str(i))
   if i+2<ordered.size():require_clear(c,ordered[i+2],tag+" evidence "+str(i))
   await click_bottom(c)
   for j in range(ordered.size()):
    require(ordered[j].button_pressed==(i>=j),tag+" evidence row "+str(i)+" click toggled wrong row "+str(j))
   actions_done+=1
  require(not FileAccess.file_exists("user://settings.cfg") and not FileAccess.file_exists("user://case.json"),
   tag+" browsing controls unexpectedly wrote a saved file")
  views_done+=1
  print("CHECKBOX_VIEW ",tag," scale=",root.get_stretch_transform().x.x," completed")
 print("CHECKBOX_VIEWPORTS dimensions=",views_done," clicks=",actions_done," issues=",issues)
 game.queue_free()
 await process_frame
 quit(0 if issues.is_empty() else 4)
