extends Node3D
const World = preload("res://scripts/world.gd")
const Fly = preload("res://scripts/fly.gd")
const Data = preload("res://scripts/case_data.gd")
const State = preload("res://scripts/case_state.gd")
const SERIF = preload("res://assets/Editorial.ttf")
const SANS = preload("res://assets/Interface.ttf")
const INK = Color("102522")
const PAPER = Color("e9e0cd")
const MUTED = Color("a7b8a9")
const GOLD = Color("d9bc7e")
var world: Node3D
var fly: CharacterBody3D
var state = State.new()
var canvas: CanvasLayer
var ui: Control
var modal: Control
var hud: Control
var marker_layer: Control
var room_label: Label
var evidence_label: Label
var controls_label: Label
var prompt: Label
var toast_label: Label
var mode := "title"
var nearest := ""
var current_id := ""
var toast_time := 0.0
var save_clock := 0.0
var elapsed := 0.0
var markers: Dictionary = {}
var thumbnails: Dictionary = {}
var ambience: AudioStreamPlayer
var wings: AudioStreamPlayer
var options: Dictionary = {"sensitivity":0.0025,"train":0.55,"wings":0.12,"shadows":true,"atmosphere":true,"limit":60,"resolution":0}
var smoke := false
var capture_mode := false
var capture_step := 0
var quitting := false
var suspect_select: OptionButton
var motive_select: OptionButton
var evidence_checks: Dictionary = {}
var ending_text: Label

func _ready() -> void:
 get_tree().auto_accept_quit = false
 smoke = "--smoke" in OS.get_cmdline_user_args()
 capture_mode = "--capture" in OS.get_cmdline_user_args()
 var cfg := ConfigFile.new()
 if cfg.load("user://settings.cfg") == OK:
  for key in options: options[key] = cfg.get_value("game",key,options[key])
 world = World.new()
 add_child(world)
 fly = Fly.new()
 add_child(fly)
 canvas = CanvasLayer.new()
 add_child(canvas)
 ui = Control.new()
 ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 canvas.add_child(ui)
 var theme := Theme.new()
 theme.default_font = SANS
 theme.default_font_size = 17
 ui.theme = theme
 for kind in ["normal","hover","pressed","focus"]:
  var sb := style(Color("25433c") if kind == "normal" else Color("466255"),1)
  theme.set_stylebox(kind,"Button",sb)
  theme.set_stylebox(kind,"OptionButton",sb)
 theme.set_color("font_color","Button",PAPER)
 theme.set_color("font_hover_color","Button",GOLD)
 theme.set_color("font_color","OptionButton",PAPER)
 theme.set_constant("h_separation","BoxContainer",12)
 setup_hud()
 setup_audio()
 apply_settings()
 DisplayServer.window_set_size([Vector2i(1280,800),Vector2i(1440,900),Vector2i(1920,1080)][clampi(int(options.resolution),0,2)])
 state.load_from()
 if state.cabinet_open: world.unlock_cabinet()
 if state.dispatch_open: world.unlock_dispatch()
 show_title()
 if smoke:
  await get_tree().process_frame
  run_smoke()

func style(color: Color, border: int = 0) -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = color
 s.border_color = Color("617162")
 s.set_border_width_all(border)
 s.set_content_margin_all(16)
 s.corner_radius_top_left = 3
 s.corner_radius_top_right = 3
 s.corner_radius_bottom_left = 3
 s.corner_radius_bottom_right = 3
 return s

func rect(parent: Node, pos: Vector2, size: Vector2, color: Color) -> ColorRect:
 var r := ColorRect.new()
 r.position = pos
 r.size = size
 r.color = color
 r.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(r)
 return r

func label(parent: Node, text: String, pos: Vector2, size: Vector2, font_size: int = 18, color: Color = PAPER, editorial: bool = false) -> Label:
 var l := Label.new()
 l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 l.add_theme_font_override("font",SERIF if editorial else SANS)
 l.add_theme_font_size_override("font_size",font_size)
 l.add_theme_color_override("font_color",color)
 l.text = text
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 parent.add_child(l)
 l.position = pos
 l.size = size
 return l

func button(parent: Node, text: String, pos: Vector2, size: Vector2, action: Callable) -> Button:
 var b := Button.new()
 b.text = text
 b.position = pos
 b.size = size
 b.pressed.connect(action)
 b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 parent.add_child(b)
 return b

func panel(parent: Node, pos: Vector2, size: Vector2, color: Color = Color("122a27")) -> Panel:
 var p := Panel.new()
 p.position = pos
 p.size = size
 p.add_theme_stylebox_override("panel",style(color,1))
 parent.add_child(p)
 return p

func clear_modal() -> void:
 if is_instance_valid(modal):
  ui.remove_child(modal)
  modal.queue_free()
 modal = Control.new()
 modal.mouse_filter = Control.MOUSE_FILTER_IGNORE
 modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.add_child(modal)

func overlay(shade: float = 0.7) -> void:
 clear_modal()
 rect(modal,Vector2.ZERO,Vector2(1440,900),Color(0.018,0.045,0.039,shade))
 Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
 fly.active = false
 fly.space_tap_remaining = 0.0
 marker_layer.visible = false

func setup_hud() -> void:
 hud = Control.new()
 hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(hud)
 rect(hud,Vector2(0,0),Vector2(1440,104),Color(0.025,0.07,0.065,0.91))
 label(hud,"N / N",Vector2(36,22),Vector2(110,50),34,GOLD,true)
 rect(hud,Vector2(145,25),Vector2(1,49),Color("526257"))
 label(hud,"THE NOCTURNE",Vector2(169,23),Vector2(280,24),14,GOLD)
 room_label = label(hud,"07   /   THE NIGHT LOUNGE",Vector2(169,49),Vector2(620,32),22,PAPER,true)
 evidence_label = label(hud,"THE VALE CASE   /   0 OF 6 CLUES",Vector2(947,30),Vector2(440,22),14,GOLD)
 label(hud,"J  Notebook     Tab  Deduction     Esc  Pause",Vector2(947,57),Vector2(465,25),14,MUTED)
 rect(hud,Vector2(0,823),Vector2(1440,77),Color(0.025,0.07,0.065,0.94))
 rect(hud,Vector2(35,822),Vector2(1370,1),Color("647263"))
 controls_label = label(hud,"WASD  Fly    SPACE / CTRL  Rise / descend    SHIFT  Precision    E  Inspect    L  Land",Vector2(36,842),Vector2(1100,30),14,PAPER)
 label(hud,"SCROLL  Camera",Vector2(1220,842),Vector2(200,30),14,MUTED)
 rect(hud,Vector2(395,732),Vector2(650,75),Color(0.025,0.07,0.065,0.9))
 prompt = label(hud,"",Vector2(405,735),Vector2(630,68),19,GOLD)
 prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 toast_label = label(hud,"",Vector2(400,125),Vector2(640,75),18,PAPER)
 toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 marker_layer = Control.new()
 marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
 marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 ui.add_child(marker_layer)
 for id in world.hotspots:
  var l := label(marker_layer,"◇",Vector2.ZERO,Vector2(260,52),21,GOLD)
  l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  markers[id] = l

func show_title() -> void:
 mode = "title"
 hud.visible = false
 overlay(0.0)
 fly.inspection = false
 fly.camera.position = Vector3(-8,126,930)
 fly.camera.look_at(Vector3(-65,100,1285))
 var shade := ColorRect.new()
 shade.size = Vector2(1440,900)
 var shader := Shader.new()
 shader.code = "shader_type canvas_item; void fragment(){ float a = mix(0.97,0.04,smoothstep(0.18,0.93,UV.x)); COLOR=vec4(0.018,0.064,0.058,a); }"
 var sm := ShaderMaterial.new()
 sm.shader = shader
 shade.material = sm
 modal.add_child(shade)
 label(modal,"N O C T U R N E    /    A  S M A L L  M Y S T E R Y",Vector2(72,76),Vector2(700,36),14,GOLD)
 rect(modal,Vector2(73,141),Vector2(61,2),GOLD)
 label(modal,"A fly on the\nnight train.",Vector2(66,186),Vector2(750,230),76,PAPER,true)
 label(modal,"Twelve carriages. Three suspects.\nOne very small witness.",Vector2(74,449),Vector2(510,90),23,MUTED)
 label(modal,"A cozy cyberpunk murder mystery,\nseen from six millimetres above the table.",Vector2(74,556),Vector2(520,70),17,PAPER)
 button(modal,"BEGIN INVESTIGATION   →",Vector2(74,665),Vector2(345,58),func(): start_game(true))
 if FileAccess.file_exists(State.PATH): button(modal,"Continue",Vector2(74,738),Vector2(160,48),func(): start_game(false))
 button(modal,"Settings",Vector2(251,738),Vector2(168,48),show_settings)
 label(modal,"ORIGINAL CASE  /  THIRD-PERSON EXPLORATION",Vector2(74,846),Vector2(760,22),12,MUTED)
 label(modal,"06 — 07 — 08\nRESIDENCES / LOUNGE / WINTER GARDEN",Vector2(1000,785),Vector2(385,60),13,GOLD)

func start_game(fresh: bool) -> void:
 if fresh:
  state = State.new()
  thumbnails.clear()
  # Restore puzzle meshes and collisions on a new run.
  world.queue_free()
  remove_child(world)
  world = World.new()
  add_child(world)
 else:
  state.load_from()
  if state.cabinet_open: world.unlock_cabinet()
  if state.dispatch_open: world.unlock_dispatch()
 apply_settings()
 fly.restore_position(Vector3(state.saved_position[0],state.saved_position[1],state.saved_position[2]))
 fly.yaw = PI
 fly.pitch = -0.12
 resume_game()
 save_game()
 toast("You are a housefly. Vale is dead. Start with the cup on his table.\nScroll out to orient yourself; hold Shift near small objects.",9)

func resume_game() -> void:
 clear_modal()
 mode = "play"
 hud.visible = true
 marker_layer.visible = true
 fly.inspection = false
 fly.camera.h_offset = 0
 fly.active = true
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func save_game() -> void:
 state.saved_position = [fly.safe_position.x,fly.safe_position.y,fly.safe_position.z]
 var err: Error = state.save_to()
 if err != OK: toast("Could not save progress. Your current investigation is still active.",4)

func toast(text: String, seconds: float = 4.0) -> void:
 toast_label.text = text
 toast_time = seconds

func available(id: String) -> bool:
 if id == "chemical": return state.cabinet_open
 if id == "ledger": return state.dispatch_open
 return true

func reach(id: String) -> float:
 if Data.TALKS.has(id): return 85.0
 if id == "latch": return 5.0
 return 24.0

func _process(delta: float) -> void:
 elapsed += delta
 toast_time = max(0,toast_time-delta)
 toast_label.visible = toast_time>0
 if mode == "play":
  save_clock += delta
  if save_clock>12:
   save_clock = 0
   save_game()
  var room := clampi(int(fly.position.z/840.0),0,2)
  room_label.text = ["06   /   THE RESIDENCES","07   /   THE NIGHT LOUNGE","08   /   THE WINTER GARDEN"][room]
  evidence_label.text = "THE VALE CASE   /   %d OF 6 CLUES" % state.evidence_count()
  controls_label.text = "WASD  Walk    SPACE  Jump · double-tap Take off    E  Inspect    L  Land / take off" if fly.landed or fly.jumping else "WASD  Fly    SPACE / CTRL  Rise / descend    SHIFT  Precision    E  Inspect    L  Land"
  nearest = ""
  var best := INF
  for id in world.hotspots:
   var p: Vector3 = world.hotspots[id].position
   var d := fly.position.distance_to(p)
   var visible_marker: bool = available(id) and not fly.camera.is_position_behind(p) and d<270
   if id=="latch" and state.cabinet_open: visible_marker = false
   if id=="dispatch" and state.dispatch_open: visible_marker = false
   var screen: Vector2 = fly.camera.unproject_position(p)
   var in_screen: bool = screen.x>15 and screen.x<1425 and screen.y>105 and screen.y<805
   var l: Label = markers[id]
   l.visible = visible_marker and in_screen
   l.position = screen-Vector2(130,55)
   l.text = ("·" if state.found.has(id) else "◇") + ("\n"+str(Data.record(id).title) if d < 95 else "")
   l.modulate.a = 1 if d < reach(id) else 0.55
   if available(id) and d<reach(id) and d<best and visible_marker:
    if (id=="latch" and state.cabinet_open) or (id=="dispatch" and state.dispatch_open): continue
    var q := PhysicsRayQueryParameters3D.create(fly.position,p,1)
    var hit := get_world_3d().direct_space_state.intersect_ray(q)
    if interaction_is_blocked(hit,id,p): continue
    best = d
    nearest = id
  if nearest != "": prompt.text = "E   " + ("Listen · " if Data.TALKS.has(nearest) else "Inspect · ") + Data.record(nearest).title
  elif fly.landed: prompt.text = "SPACE   Jump   ·   Double-tap SPACE   Take off"
  elif fly.jumping: prompt.text = "SPACE again   Take off" if fly.space_tap_remaining > 0.0 else "Landing…"
  else: prompt.text = "E   Land on a nearby surface"
 if is_instance_valid(wings): wings.volume_db = linear_to_db(max(0.0001,float(options.wings)*(0.25 if fly.landed or fly.jumping or mode!="play" else 1.0)))
 if capture_mode: capture_sequence()

func interaction_is_blocked(hit: Dictionary, id: String, target: Vector3) -> bool:
 if hit.is_empty(): return false
 # A person's own surface is the interaction target, even when the authored
 # conversation point lies beneath their coat. Other objects still occlude it.
 if Data.TALKS.has(id):
  var node: Node = hit.collider
  while node != null and node != world:
   if node.get_meta("hotspot_id","") == id: return false
   node = node.get_parent()
 return hit.position.distance_to(target) > (10.0 if id=="cup" else 4.0)

func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode == KEY_ESCAPE:
  if mode == "play": show_pause()
  elif mode == "title": quit_game()
  elif mode == "settings":
   if hud.visible: show_pause()
   else: show_title()
  else: resume_game()
  get_viewport().set_input_as_handled()
 elif mode == "play":
  match event.keycode:
   KEY_E:
    if nearest!="": show_inspection(nearest)
    elif not fly.try_land(): toast("Move within 18 cm of a horizontal surface to land. Tap Space to jump; double-tap to take off.")
   KEY_L:
    if not fly.try_land(): toast("Move within 18 cm of a horizontal surface to land.")
   KEY_J: show_notebook()
   KEY_TAB: show_deduction()
   KEY_H: show_controls()
 elif mode == "inspection" and event.keycode == KEY_E: resume_game()
 elif mode == "notebook" and event.keycode == KEY_J: resume_game()
 elif mode == "deduction" and event.keycode == KEY_TAB: resume_game()

func show_inspection(id: String) -> void:
 current_id = id
 var carriage_index := clampi(int(fly.position.z/840.0),0,2)
 room_label.text = ["06   /   THE RESIDENCES","07   /   THE NIGHT LOUNGE","08   /   THE WINTER GARDEN"][carriage_index]
 mode = "inspection"
 overlay(0)
 fly.active = true
 toast_time = 0
 prompt.text = ""
 fly.inspect_at(world.hotspots[id].position,70.0 if Data.TALKS.has(id) else 24.0)
 fly.update_camera(0)
 # Keep the inspected prop left of the evidence card.
 fly.camera.h_offset = 5.5 if not Data.TALKS.has(id) else 16.0
 var r := Data.record(id)
 var p := panel(modal,Vector2(925,150),Vector2(470,625),Color(0.035,0.10,0.085,0.97))
 label(p,r.kind+"   /   "+r.place,Vector2(26,27),Vector2(416,50),12,GOLD)
 label(p,r.title,Vector2(26,94),Vector2(410,100),34,PAPER,true)
 rect(p,Vector2(27,197),Vector2(45,2),GOLD)
 label(p,r.text,Vector2(26,225),Vector2(414,220),18,PAPER)
 if id=="latch":
  button(p,"BRIDGE THE CONTACT",Vector2(26,490),Vector2(414,50),release_latch)
 elif id=="dispatch":
  button(p,"EXAMINE SYMBOL LOCK",Vector2(26,490),Vector2(414,50),show_lock)
 else:
  var fresh: bool = state.discover(id)
  label(p,"✓  RECORDED IN YOUR NOTEBOOK" if fresh else "✓  PREVIOUSLY RECORDED",Vector2(26,495),Vector2(415,36),12,GOLD)
  evidence_label.text = "THE VALE CASE   /   %d OF 6 CLUES" % state.evidence_count()
  save_game()
 button(p,"Return to flight   [E / Esc]",Vector2(26,555),Vector2(414,46),resume_game)
 label(modal,"A CLOSER LOOK",Vector2(45,145),Vector2(500,32),14,GOLD)
 label(modal,"Hold right mouse and drag to orbit · Scroll to zoom",Vector2(45,778),Vector2(780,30),15,PAPER)
 capture_evidence(id)

func _input(event: InputEvent) -> void:
 if mode=="inspection":
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
   Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
   get_viewport().set_input_as_handled()

func capture_evidence(id: String) -> void:
 if DisplayServer.get_name()=="headless" or thumbnails.has(id): return
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 if mode!="inspection" or current_id!=id: return
 var image := get_viewport().get_texture().get_image()
 if image==null or image.is_empty(): return
 var crop := image.get_region(Rect2i(0,0,int(image.get_width()*0.62),image.get_height()))
 crop.resize(560,420,Image.INTERPOLATE_LANCZOS)
 thumbnails[id] = ImageTexture.create_from_image(crop)
 DirAccess.make_dir_recursive_absolute("user://evidence")
 crop.save_png("user://evidence/"+id+".png")

func release_latch() -> void:
 if fly.position.distance_to(world.hotspots.latch.position)>5.5:
  toast("Approach the contact through the cable opening first.")
  return
 state.cabinet_open = true
 world.unlock_cabinet()
 state.discover("latch")
 save_game()
 resume_game()
 toast("The service door releases. A small violet bottle waits inside.",6)

func show_lock() -> void:
 mode = "lock"
 overlay(0.8)
 var p := panel(modal,Vector2(340,165),Vector2(760,565))
 label(p,"BOTANICAL DISPATCH   /   SYMBOL LOCK",Vector2(35,30),Vector2(680,35),14,GOLD)
 label(p,"A little order in the jungle.",Vector2(35,94),Vector2(680,90),36,PAPER,true)
 label(p,"Match the shipping sequence. Inspect the torn label on the potting bench for the order.",Vector2(35,194),Vector2(680,75),19,MUTED)
 var picks: Array[OptionButton] = []
 for i in range(3):
  var select := OptionButton.new()
  for name_text in ["Choose symbol…","LEAF","MOON","DROP"]: select.add_item(name_text)
  select.position = Vector2(35+i*233,300)
  select.size = Vector2(218,54)
  p.add_child(select)
  picks.append(select)
 var status := label(p,"",Vector2(35,376),Vector2(680,65),17,GOLD)
 button(p,"Release drawer",Vector2(35,467),Vector2(330,52),func():
  if attempt_dispatch([picks[0].selected,picks[1].selected,picks[2].selected]):
   resume_game()
   toast("The dispatch drawer opens. Inspect the ledger inside.",6)
  else: status.text = "The lock stays closed. Look for an ordered sequence on the shipment label."
 )
 button(p,"Back to flight",Vector2(390,467),Vector2(330,52),resume_game)

func attempt_dispatch(sequence: Array) -> bool:
 if sequence != [1,2,3]: return false
 state.dispatch_open = true
 world.unlock_dispatch()
 state.discover("dispatch")
 save_game()
 return true

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func quit_game() -> void:
 if quitting: return
 quitting = true
 if mode != "title": save_game()
 if is_instance_valid(ambience):
  ambience.stop()
  ambience.stream = null
 if is_instance_valid(wings):
  wings.stop()
  wings.stream = null
 await get_tree().create_timer(0.15).timeout
 get_tree().quit()

func show_notebook(selected: String = "") -> void:
 mode = "notebook"
 overlay(0.85)
 var p := panel(modal,Vector2(55,130),Vector2(1330,655))
 label(p,"FIELD NOTES   /   THE VALE CASE",Vector2(28,24),Vector2(1000,28),14,GOLD)
 label(p,"Small observations. A larger truth.",Vector2(28,66),Vector2(1200,70),36,PAPER,true)
 button(p,"Close  [J]",Vector2(1120,22),Vector2(180,44),resume_game)
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(26,157)
 scroll.size = Vector2(380,462)
 p.add_child(scroll)
 var list := VBoxContainer.new()
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 var objective := Button.new()
 objective.text = "THE CASE / CARRIAGE GUIDE"
 objective.custom_minimum_size = Vector2(360,53)
 objective.pressed.connect(func(): show_notebook())
 list.add_child(objective)
 for id in state.found:
  var b := Button.new()
  b.text = ("◆  " if Data.CLUES.has(id) else "·  ")+Data.record(id).title
  b.alignment = HORIZONTAL_ALIGNMENT_LEFT
  b.custom_minimum_size = Vector2(360,50)
  b.pressed.connect(show_notebook.bind(id))
  list.add_child(b)
 rect(p,Vector2(427,155),Vector2(1,459),Color("536355"))
 if selected=="":
  label(p,"Elias Vale died after his evening tea.",Vector2(465,158),Vector2(810,55),27,PAPER,true)
  label(p,"Find a means, a motive, and a link to the culprit. You are a witness, not a courier: examine the objects where they lie. Eavesdrop near the residents to hear their accounts.",Vector2(465,233),Vector2(800,110),19,MUTED)
  label(p,"06   RESIDENCES      ← behind the lounge\nVale’s desk · engineer · maintenance terminal\n\n07   DINING LOUNGE\nVale’s cup · steward · service cabinet and cable opening\n\n08   WINTER GARDEN   → beyond the lounge\nBotanist · shipment label · symbol lock and ledger",Vector2(465,360),Vector2(810,245),17,PAPER)
 else:
  var r := Data.record(selected)
  label(p,r.place+"   /   "+r.kind,Vector2(465,157),Vector2(820,35),12,GOLD)
  label(p,r.title,Vector2(465,205),Vector2(810,70),32,PAPER,true)
  label(p,r.text,Vector2(465,287),Vector2(795,200),19,PAPER)
  label(p,r.get("detail","A detail of life aboard the Nocturne."),Vector2(465,506),Vector2(800,65),16,GOLD)
  button(p,"View field photograph",Vector2(465,570),Vector2(335,48),func(): show_photo(selected))

func show_photo(id: String) -> void:
 if not thumbnails.has(id) and FileAccess.file_exists("user://evidence/"+id+".png"):
  var image := Image.load_from_file("user://evidence/"+id+".png")
  if image: thumbnails[id] = ImageTexture.create_from_image(image)
 if not thumbnails.has(id):
  toast("Reinspect this object to capture a field photograph.")
  return
 mode = "photo"
 overlay(0.94)
 var pic := TextureRect.new()
 pic.texture = thumbnails[id]
 pic.position = Vector2(300,110)
 pic.size = Vector2(840,630)
 pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 modal.add_child(pic)
 label(modal,Data.record(id).title,Vector2(300,755),Vector2(650,50),25,PAPER,true)
 button(modal,"Back to notes",Vector2(970,755),Vector2(180,48),show_notebook.bind(id))

func show_deduction() -> void:
 mode = "deduction"
 overlay(0.9)
 evidence_checks.clear()
 var p := panel(modal,Vector2(155,135),Vector2(1130,645))
 label(p,"THE FINAL DEDUCTION",Vector2(32,25),Vector2(1000,30),14,GOLD)
 label(p,"Who silenced Elias Vale?",Vector2(32,75),Vector2(1030,65),40,PAPER,true)
 label(p,"Build a case from physical evidence. Wrong answers let you keep investigating.",Vector2(32,150),Vector2(1040,50),18,MUTED)
 suspect_select = OptionButton.new()
 for text in ["Culprit: Mara Sable · steward","Culprit: Dr Lian Moss · botanist","Culprit: Ivo Chen · engineer"]: suspect_select.add_item(text)
 suspect_select.position = Vector2(32,225)
 suspect_select.size = Vector2(505,52)
 p.add_child(suspect_select)
 motive_select = OptionButton.new()
 for text in ["Motive: conceal illegal plant sales","Motive: revenge for the orchids","Motive: cover up faulty maintenance"]: motive_select.add_item(text)
 motive_select.position = Vector2(567,225)
 motive_select.size = Vector2(530,52)
 p.add_child(motive_select)
 label(p,"SUPPORTING EVIDENCE   /   SELECT THE RELEVANT CLUES",Vector2(32,308),Vector2(1060,28),13,GOLD)
 for i in range(Data.ESSENTIAL.size()):
  var id: String = Data.ESSENTIAL[i]
  var check := CheckBox.new()
  check.position = Vector2(32+(i%2)*535,353+(i/2)*48)
  check.size = Vector2(520,42)
  check.text = Data.record(id).title if state.found.has(id) else "Undiscovered physical clue"
  check.disabled = not state.found.has(id)
  p.add_child(check)
  evidence_checks[id] = check
 ending_text = label(p,"",Vector2(32,505),Vector2(1050,53),17,GOLD)
 button(p,"Present deduction   →",Vector2(32,570),Vector2(505,48),submit_case)
 button(p,"Keep investigating",Vector2(567,570),Vector2(530,48),resume_game)

func submit_case() -> void:
 var selected: Array = []
 for id in evidence_checks:
  if evidence_checks[id].button_pressed: selected.append(id)
 if Data.solved(suspect_select.selected,motive_select.selected,selected):
  state.complete = true
  save_game()
  show_ending()
 else:
  ending_text.text = "Follow the cup to its source, then connect the sales ledger to Vale’s ultimatum. You need proof of means and motive."

func show_ending() -> void:
 mode = "ending"
 overlay(0.87)
 label(modal,"CASE CLOSED   /   THE LAST TEA",Vector2(220,190),Vector2(1000,40),16,GOLD)
 label(modal,"The smallest witness\nsaw the whole thing.",Vector2(215,270),Vector2(1050,160),53,PAPER,true)
 label(modal,"Mara Sable poisoned Vale’s cup to conceal her trade in protected orchids. The bottle, the ledger, and his final note tell the story she could not.\n\nAt dawn, a routine cabin search brings the truth to light. The Nocturne rolls on. In the winter garden, the orchids keep growing.",Vector2(220,475),Vector2(965,190),22,PAPER)
 button(modal,"Return to the train",Vector2(220,719),Vector2(390,58),resume_game)
 button(modal,"Title screen",Vector2(640,719),Vector2(390,58),show_title)

func show_pause() -> void:
 mode = "pause"
 overlay(0.78)
 var p := panel(modal,Vector2(465,170),Vector2(510,580))
 label(p,"A MOMENT BETWEEN STATIONS",Vector2(30,30),Vector2(450,50),13,GOLD)
 label(p,"The train rolls on.",Vector2(30,100),Vector2(450,80),35,PAPER,true)
 button(p,"Resume flight",Vector2(30,209),Vector2(450,50),resume_game)
 button(p,"Settings",Vector2(30,275),Vector2(450,50),show_settings)
 button(p,"Flight & investigation guide",Vector2(30,341),Vector2(450,50),show_controls)
 button(p,"Return to a safe perch",Vector2(30,407),Vector2(450,50),func():
  fly.position = Vector3(-75,88,1225)
  fly.safe_position = fly.position
  fly.velocity = Vector3.ZERO
  fly.reset_movement()
  resume_game()
 )
 button(p,"Save & title",Vector2(30,473),Vector2(450,50),func(): save_game(); show_title())

func show_controls() -> void:
 mode = "controls"
 overlay(0.9)
 var p := panel(modal,Vector2(230,150),Vector2(980,620))
 label(p,"A HOUSEFLY’S FIELD GUIDE",Vector2(35,30),Vector2(900,40),14,GOLD)
 label(p,"Think small. Look closely.",Vector2(35,95),Vector2(900,65),38,PAPER,true)
 label(p,"WASD: move relative to the camera’s horizontal direction\nMouse: look around · Scroll: adjust camera distance\nSpace / Ctrl: rise / descend · Shift: slow precision movement\nE: inspect / listen · L: land / take off\nLanded: tap Space to jump; double-tap Space to take off\nJ: notebook · Tab: deduction · Esc: pause\n\nFollow diamond markers; move close until the E prompt appears.\nInspection: hold right mouse and drag to orbit, scroll to zoom.\nThe fly is 6 mm long. You can land on tables, shelves, and floors.\nYou cannot carry human-sized objects or crawl on ceilings.\n\nProgress saves automatically. Pause offers a safe-perch recovery.",Vector2(35,190),Vector2(910,330),19,PAPER)
 button(p,"Return to flight",Vector2(35,538),Vector2(910,48),resume_game)

func show_settings() -> void:
 mode = "settings"
 overlay(0.88)
 var p := panel(modal,Vector2(340,120),Vector2(760,680))
 label(p,"SETTINGS",Vector2(35,27),Vector2(650,40),14,GOLD)
 label(p,"Make yourself at home.",Vector2(35,80),Vector2(680,70),36,PAPER,true)
 var rows := [["Mouse sensitivity","sensitivity",0.001,0.006,0.0001],["Train ambience","train",0.0,1.0,0.01],["Wing buzz","wings",0.0,1.0,0.01]]
 for i in range(rows.size()):
  var row: Array = rows[i]
  label(p,row[0],Vector2(35,175+i*75),Vector2(300,30),18,PAPER)
  var slider := HSlider.new()
  slider.min_value = row[2]
  slider.max_value = row[3]
  slider.step = row[4]
  slider.value = options[row[1]]
  slider.position = Vector2(340,181+i*75)
  slider.size = Vector2(370,30)
  p.add_child(slider)
  slider.value_changed.connect(func(value: float): options[row[1]]=value; apply_settings())
 var shadow := CheckBox.new()
 shadow.text = "Enable shadows"
 shadow.button_pressed = options.shadows
 shadow.position = Vector2(35,413)
 p.add_child(shadow)
 shadow.toggled.connect(func(value: bool): options.shadows=value; apply_settings())
 var atmosphere_toggle := CheckBox.new()
 atmosphere_toggle.text = "Rain & atmosphere"
 atmosphere_toggle.button_pressed = bool(options.atmosphere)
 atmosphere_toggle.position = Vector2(385,413)
 p.add_child(atmosphere_toggle)
 atmosphere_toggle.toggled.connect(func(value: bool): options.atmosphere=value; apply_settings())
 var fps := OptionButton.new()
 for text in ["30 FPS limit","60 FPS limit","120 FPS limit","Uncapped"]: fps.add_item(text)
 fps.selected = [30,60,120,0].find(int(options.limit))
 fps.position = Vector2(35,478)
 fps.size = Vector2(325,50)
 p.add_child(fps)
 fps.item_selected.connect(func(index: int): options.limit=[30,60,120,0][index]; apply_settings())
 var res := OptionButton.new()
 for text in ["1280 × 800","1440 × 900","1920 × 1080"]: res.add_item(text)
 res.selected = int(options.resolution)
 res.position = Vector2(385,478)
 res.size = Vector2(325,50)
 p.add_child(res)
 res.item_selected.connect(func(index: int):
  options.resolution=index
  DisplayServer.window_set_size([Vector2i(1280,800),Vector2i(1440,900),Vector2i(1920,1080)][index])
  apply_settings()
 )
 button(p,"Save & return",Vector2(35,588),Vector2(675,52),func():
  var cfg := ConfigFile.new()
  for key in options: cfg.set_value("game",key,options[key])
  cfg.save("user://settings.cfg")
  if hud.visible: show_pause()
  else: show_title()
 )

func apply_settings() -> void:
 world.set_atmosphere_enabled(bool(options.atmosphere))
 fly.sensitivity = float(options.sensitivity)
 Engine.max_fps = int(options.limit)
 for child in world.get_children():
  if child is DirectionalLight3D: child.shadow_enabled = bool(options.shadows)
 if is_instance_valid(ambience): ambience.volume_db = linear_to_db(max(0.0001,float(options.train)))

func setup_audio() -> void:
 if DisplayServer.get_name()=="headless" or AudioServer.get_driver_name()=="Dummy": return
 ambience = AudioStreamPlayer.new()
 ambience.stream = preload("res://assets/train.wav")
 ambience.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 ambience.stream.loop_end = 176400
 add_child(ambience)
 ambience.play()
 wings = AudioStreamPlayer.new()
 wings.stream = preload("res://assets/wings.wav")
 wings.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 wings.stream.loop_end = 44100
 add_child(wings)
 wings.play()

func capture_sequence() -> void:
 var times := [2.0,4.0,6.0,8.0,10.0,12.0,14.0,16.0,18.0,20.0]
 if capture_step>=times.size() or elapsed<times[capture_step]: return
 var step := capture_step
 capture_step += 1
 match step:
  0: capture_frame("01-title")
  1:
   start_game(true)
   fly.active = false
   fly.camera.position = Vector3(0,133,940)
   fly.camera.look_at(Vector3(-50,105,1390))
   capture_frame("02-lounge")
  2:
   fly.position = Vector3(0,130,1800)
   fly.camera.position = Vector3(-18,144,1725)
   fly.camera.look_at(Vector3(0,125,2280))
   capture_frame("03-garden")
  3:
   fly.position = Vector3(-85,89,1242)
   fly.safe_position = fly.position
   show_inspection("cup")
   capture_frame("04-inspection")
  4:
   resume_game()
   fly.active = false
   fly.position = Vector3(0,125,180)
   fly.camera.position = Vector3(0,125,60)
   fly.camera.look_at(Vector3(-30,115,620))
   capture_frame("05-residences")
  5:
   show_notebook("cup")
   capture_frame("06-notebook")
  6:
   show_deduction()
   capture_frame("07-deduction")
  7:
   resume_game()
   fly.position = Vector3(-88,87.5,1236)
   fly.yaw = PI
   fly.pitch = -0.12
   fly.distance = 10
   fly.update_camera(0)
   capture_frame("08-fly-perspective")
  8:
   show_ending()
   capture_frame("09-ending")
  9: quit_game()

func capture_frame(name_text: String) -> void:
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 var image := get_viewport().get_texture().get_image()
 image.save_png("/workspace/previews/"+name_text+".png")
 print("CAPTURE ",name_text)

func run_smoke() -> void:
 # Integration traversal uses the same interaction/state/UI paths as normal play.
 start_game(true)
 assert(world.hotspots.size()==15)
 show_inspection("cup")
 assert(state.found.has("cup"))
 resume_game()
 fly.position = world.hotspots.latch.position+Vector3(0,0.4,0)
 release_latch()
 assert(state.cabinet_open)
 show_inspection("chemical")
 assert(state.found.has("chemical"))
 for id in ["note","label","log","steward","botanist","engineer","pastry","photo","orchid","body"]:
  show_inspection(id)
 assert(not attempt_dispatch([3,2,1]))
 assert(not state.dispatch_open)
 show_lock()
 var unlocked: bool = attempt_dispatch([1,2,3])
 assert(unlocked)
 show_inspection("ledger")
 assert(state.evidence_count()==6)
 show_notebook("cup")
 show_deduction()
 suspect_select.selected = 1
 submit_case()
 assert(not state.complete)
 suspect_select.selected = 0
 for id in ["cup","chemical","ledger","note"]: evidence_checks[id].button_pressed = true
 submit_case()
 assert(state.complete)
 var restored = State.new()
 var loaded: bool = restored.load_from()
 assert(loaded)
 assert(restored.complete and restored.evidence_count()==6)
 show_settings()
 show_pause()
 resume_game()
 clear_modal()
 ui.remove_child(modal)
 modal.queue_free()
 await get_tree().process_frame
 print("INTEGRATION PASS: 3 carriages, 15 hotspots, inspection, cabinet, notebook, deduction, ending, save/reload, settings")
 quit_game()
