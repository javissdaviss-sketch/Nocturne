extends Node3D
const RoomShadowPolicy = preload("res://scripts/room_shadow_policy.gd")
signal first_boot_paint_acknowledged
signal investigation_ready
const World = preload("res://scripts/world.gd")
const Fly = preload("res://scripts/fly.gd")
const Data = preload("res://scripts/case_data.gd")
const State = preload("res://scripts/case_state.gd")
const ListeningMix = preload("res://scripts/listening_mix.gd")
const CarriageGuide = preload("res://scripts/carriage_guide.gd")
const CarriageGuideMap = preload("res://scripts/carriage_guide_map.gd")
const TraceNotes = preload("res://scripts/trace_notes.gd")
const TraceGraphic = preload("res://scripts/trace_graphic.gd")
const SERIF = preload("res://assets/Editorial.ttf")
const SANS = preload("res://assets/Interface.ttf")
const INK = Color("102522")
const PAPER = Color("e9e0cd")
const MUTED = Color("a7b8a9")
const GOLD = Color("d9bc7e")
const ROOM_TITLES := ["06   /   THE RESIDENCES","07   /   THE NIGHT LOUNGE","08   /   THE WINTER GARDEN"]
const WALK_CONTROLS := "WASD  Walk    SPACE  Jump · double-tap Take off    E  Inspect    L  Land / take off"
const HOLD_CONTROLS := "WASD  Fly    SPACE / CTRL  Rise / descend    SHIFT  Hold for precision    E  Inspect    L  Land"
const TOGGLE_CONTROLS := "WASD  Fly    SPACE / CTRL  Rise / descend    SHIFT  Toggle precision    E  Inspect    L  Land"
const PNG_HEADER := [137,80,78,71,13,10,26,10]
const FIRST_LOOK_ROOM_CM := 8.0
const FIRST_LOOK_CUP_MAX_CM := 34.0
const RESOLVED_ARCHIVE_FOCUS := Vector3(-100,81.7,2235)
const RESOLVED_ARCHIVE_EYES := [Vector3(-171,114,2170),Vector3(-146,111,2165),Vector3(-161,108,2279)]
const FIRST_LOOK_PROMPT := "Move towards the cup · E   Inspect when close\nL   Land"
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
var lead_label: Label
var carriage_pin_label: Label
var precision_label: Label
var controls_label: Label
var prompt: Label
var toast_label: Label
var prompt_backdrop: ColorRect
var mode := "title"
var nearest := ""
var first_look_armed := false
var first_look_origin := Vector3.ZERO
var current_id := ""
var toast_time := 0.0
var save_clock := 0.0
var elapsed := 0.0
var markers: Dictionary = {}
var carriage_pin := -1
var thumbnails: Dictionary = {}
var ambience: AudioStreamPlayer
var wings: AudioStreamPlayer
var listening_mix := ListeningMix.new()
var options: Dictionary = {"sensitivity":0.0025,"train":0.55,"wings":0.12,"shadows":true,"atmosphere":true,"passing_train":false,"precision_toggle":false,"limit":60,"resolution":0}
var smoke := false
var capture_mode := false
var profile_photos := false
var capture_step := 0
var quitting := false
var boot_waiting_for_paint := false
var boot_frame_rendered := false
var loading_card: CanvasLayer
var suspect_select: OptionButton
var motive_select: OptionButton
var deduction_submit: Button
var deduction_review: Dictionary = {}
var deduction_draft: Dictionary = {}
var photo_entry := ""
var photo_return_page := ""
var trace_camera_state: Dictionary = {}
var trace_choices: Array[String] = ["",""]
var trace_selectors: Array[OptionButton] = []
var notebook_page := ""
var night_relay_choice: OptionButton
var night_relay_status: Label
var night_relay_pulse: Button
var evidence_checks: Dictionary = {}
var ending_text: Label
var resolved_archive_camera: Camera3D
var had_hud_before_resolved_view := false

func _ready() -> void:
 var started_at := Time.get_ticks_msec()
 var report_startup := "--profile-startup" in OS.get_cmdline_user_args()
 get_tree().auto_accept_quit = false
 mode = "loading"
 set_process(false)
 set_process_input(false)
 set_process_unhandled_input(false)
 loading_card = make_loading_card()
 add_child(loading_card)
 var card_ready_at := Time.get_ticks_msec()
 await allow_loading_card_to_paint()
 if report_startup:
  print("BOOT_CARD created at ",card_ready_at-started_at,"ms; World starts at ",Time.get_ticks_msec()-started_at,
   "ms; graphical frame completed=",boot_frame_rendered)
 if quitting: return
 sync_desktop_title()
 smoke = "--smoke" in OS.get_cmdline_user_args()
 capture_mode = "--capture" in OS.get_cmdline_user_args()
 profile_photos = "--profile-photos" in OS.get_cmdline_user_args()
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
 world.set_nursery_task_light(state.nursery_restored)
 world.seed_lift.set_returned(state.found.has("seed_return_ready"))
 show_title()
 remove_child(loading_card)
 loading_card.queue_free()
 loading_card = null
 set_process(true)
 set_process_input(true)
 set_process_unhandled_input(true)
 if report_startup: print("BOOT_TITLE ready at ",Time.get_ticks_msec()-started_at,"ms")
 investigation_ready.emit()
 if smoke:
  await get_tree().process_frame
  run_smoke()

func make_loading_card() -> CanvasLayer:
 var layer := CanvasLayer.new()
 layer.name = "InitialLoadingCard"
 layer.layer = 3
 var backdrop := Control.new()
 backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
 layer.add_child(backdrop)
 backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 rect(backdrop,Vector2.ZERO,Vector2(1440,900),INK)
 rect(backdrop,Vector2(73,142),Vector2(64,2),GOLD)
 label(backdrop,"N O C T U R N E",Vector2(74,76),Vector2(640,36),14,GOLD)
 label(backdrop,"Preparing the train",Vector2(69,194),Vector2(1050,160),57,PAPER,true)
 label(backdrop,"The first load can take a moment.",Vector2(74,392),Vector2(760,82),21,MUTED)
 return layer

func allow_loading_card_to_paint() -> void:
 # Server tests and console runs must not wait for a frame that will never draw.
 if DisplayServer.get_name()=="headless" or "--disable-render-loop" in OS.get_cmdline_args():
  await get_tree().process_frame
  return
 boot_waiting_for_paint = true
 var acknowledge_draw := _acknowledge_boot_paint.bind(true)
 RenderingServer.frame_post_draw.connect(acknowledge_draw,CONNECT_DEFERRED|CONNECT_ONE_SHOT)
 # A minimised window or paused render loop must not block startup indefinitely.
 var fallback := get_tree().create_timer(0.35,true,false,true)
 fallback.timeout.connect(_acknowledge_boot_paint.bind(false),CONNECT_ONE_SHOT)
 await first_boot_paint_acknowledged
 if RenderingServer.frame_post_draw.is_connected(acknowledge_draw):
  RenderingServer.frame_post_draw.disconnect(acknowledge_draw)

func _acknowledge_boot_paint(rendered: bool) -> void:
 if not boot_waiting_for_paint: return
 boot_waiting_for_paint = false
 boot_frame_rendered = rendered
 first_boot_paint_acknowledged.emit()

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

func set_visible_text(target: Label, value: String) -> void:
 if target.text != value: target.text = value

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
 room_label = label(hud,"07   /   THE NIGHT LOUNGE",Vector2(169,47),Vector2(620,32),22,PAPER,true)
 lead_label = label(hud,"",Vector2(169,79),Vector2(748,19),14,MUTED)
 evidence_label = label(hud,"THE VALE CASE   /   0 OF 6 PHYSICAL FINDS",Vector2(947,30),Vector2(440,22),14,GOLD)
 label(hud,"J  Notebook     Tab  Deduction     Esc  Pause",Vector2(947,57),Vector2(465,25),14,MUTED)
 carriage_pin_label = label(hud,"",Vector2(947,79),Vector2(450,19),13,GOLD)
 carriage_pin_label.hide()
 rect(hud,Vector2(0,823),Vector2(1440,77),Color(0.025,0.07,0.065,0.94))
 rect(hud,Vector2(35,822),Vector2(1370,1),Color("647263"))
 controls_label = label(hud,"WASD  Fly    SPACE / CTRL  Rise / descend    SHIFT  Precision    E  Inspect    L  Land",Vector2(36,842),Vector2(1100,30),14,PAPER)
 label(hud,"SCROLL  Camera",Vector2(1220,842),Vector2(200,30),14,MUTED)
 precision_label = label(hud,"PRECISION",Vector2(1220,784),Vector2(200,24),14,GOLD)
 precision_label.hide()
 prompt_backdrop = rect(hud,Vector2(395,732),Vector2(650,75),Color(0.025,0.07,0.065,0.9))
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
  # Hold an edge on ivory, glass and paper without brightening any clue.
  l.add_theme_color_override("font_outline_color",Color("13221f"))
  l.add_theme_constant_override("outline_size",3)
  l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  markers[id] = l

func show_title() -> void:
 restore_player_camera_after_resolved_view()
 first_look_armed = false
 mode = "title"
 hud.visible = false
 overlay(0.0)
 fly.inspection = false
 fly.camera.position = Vector3(-225,138,1022)
 fly.camera.look_at(Vector3(-386,100,1260))
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
 label(modal,"Fly Spy\nWith My Little Eye",Vector2(66,186),Vector2(750,230),61,PAPER,true)
 label(modal,"Twelve carriages. Three suspects.\nOne very small witness.",Vector2(74,449),Vector2(510,90),23,MUTED)
 label(modal,"A cozy cyberpunk murder mystery,\nseen from six millimetres above the table.",Vector2(74,556),Vector2(520,70),17,PAPER)
 var primary := button(modal,"BEGIN INVESTIGATION   →",Vector2(74,665),Vector2(345,58),request_new_case)
 if FileAccess.file_exists(State.PATH):
  primary = button(modal,"Continue",Vector2(74,738),Vector2(160,48),func(): start_game(false))
 button(modal,"Settings",Vector2(251,738),Vector2(168,48),show_settings)
 label(modal,"ORIGINAL CASE  /  THIRD-PERSON EXPLORATION",Vector2(74,846),Vector2(760,22),12,MUTED)
 label(modal,"06 — 07 — 08\nRESIDENCES / LOUNGE / WINTER GARDEN",Vector2(1000,785),Vector2(385,60),13,GOLD)
 # Enter starts a fresh case or continues safely. A deliberate New Case
 # still opens a separate dialog with Cancel focused.
 primary.grab_focus()

func request_new_case() -> void:
 if not FileAccess.file_exists(State.PATH):
  start_game(true)
  return
 mode = "new_case_confirm"
 overlay(0.86)
 var p := panel(modal,Vector2(385,262),Vector2(670,354))
 label(p,"BEGIN A NEW INVESTIGATION?",Vector2(34,38),Vector2(602,40),15,GOLD)
 label(p,"Your current case is saved.",Vector2(34,92),Vector2(602,65),32,PAPER,true)
 label(p,"Starting again replaces your current investigation. To keep it, cancel and choose Continue.",Vector2(34,171),Vector2(602,83),18,PAPER)
 var cancel := button(p,"Cancel  [Esc]",Vector2(34,274),Vector2(280,50),show_title)
 button(p,"Start new case",Vector2(354,274),Vector2(282,50),func(): start_game(true))
 cancel.grab_focus()

func show_save_unavailable() -> void:
 mode = "save_unavailable"
 hud.hide()
 overlay(0.86)
 var p := panel(modal,Vector2(385,262),Vector2(670,360))
 label(p,"SAVED INVESTIGATION UNAVAILABLE",Vector2(34,38),Vector2(602,40),15,GOLD)
 label(p,"This save couldn’t be opened.",Vector2(34,92),Vector2(602,65),32,PAPER,true)
 label(p,"The game hasn’t changed your save. Go back to retry, or choose Begin Investigation if you want to start a new case.",Vector2(34,171),Vector2(602,85),18,PAPER)
 button(p,"Back to title  [Esc]",Vector2(34,280),Vector2(280,50),show_title).grab_focus()

func start_game(fresh: bool) -> void:
 var previous_album: String = state.photo_album
 if not fresh and not state.load_from():
  # A refusal must not enter the gameplay auto-save or replace a recovery file.
  show_save_unavailable()
  return
 deduction_review.clear()
 trace_camera_state.clear()
 if fresh:
  state = State.new()
  deduction_draft.clear()
  carriage_pin = -1
  trace_choices = ["",""]
  thumbnails.clear()
  # A first-time player is already looking into a freshly built world.
  # Rebuild only if an earlier case moved one of the two puzzle meshes.
  if not world.cabinet_door.visible or not world.drawer.visible:
   remove_child(world)
   # Release the detailed tree before creating a second one in memory.
   world.free()
   world = World.new()
   add_child(world)
 else:
  if state.photo_album != previous_album:
   thumbnails.clear()
   deduction_draft.clear()
  if state.cabinet_open: world.unlock_cabinet()
  if state.dispatch_open: world.unlock_dispatch()
 world.set_nursery_task_light(state.nursery_restored)
 world.seed_lift.set_returned(state.found.has("seed_return_ready"))
 apply_settings()
 fly.reset_precision()
 fly.restore_position(Vector3(state.saved_position[0],state.saved_position[1],state.saved_position[2]))
 fly.yaw = PI
 fly.pitch = -0.12
 if not fresh and state.saved_view.size()==2:
  fly.yaw = float(state.saved_view[0])
  fly.pitch = float(state.saved_view[1])
 first_look_armed = fresh
 first_look_origin = fly.global_position
 if fresh and world.hotspots.has("cup"):
  face_opening_objective()
 resume_game()
 save_game()

func face_opening_objective() -> void:
 var target: Vector3 = world.hotspots.cup.position
 var approach: Vector3 = target-first_look_origin
 fly.yaw = atan2(-approach.x,-approach.z)
 fly.pitch = atan2(approach.y,Vector2(approach.x,approach.z).length())

func investigation_lead() -> String:
 if state.complete: return ""
 if not state.found.has("cup"): return "Vale is dead. Start with the cup beside him."
 if not state.found.has("steward") and not state.found.has("chemical"):
  return "The pot is clean. Who handled Vale’s cup?"
 if not state.found.has("chemical"): return "Check the locked cabinet in the Steward’s Store (07)."
 var missing_writing: bool = not state.found.has("note")
 var missing_archive: bool = not state.found.has("ledger")
 if missing_writing and missing_archive:
  return "Check the Writing Berth (06) and the Heritage Archive (08)."
 if missing_writing: return "Check the Writing Berth (06)."
 if missing_archive: return "Check the Heritage Archive (08)."
 return "Connect your clues in the notebook. Press Tab when you’re ready."

func resume_game() -> void:
 restore_player_camera_after_resolved_view()
 if mode == "deduction": remember_deduction_draft()
 if mode in ["inspection","notebook","deduction","pause"]: fly.settle_after_modal_return()
 clear_modal()
 mode = "play"
 nearest = ""
 sync_evidence_hud()
 hud.visible = true
 marker_layer.visible = true
 fly.inspection = false
 fly.camera.h_offset = 0
 fly.active = true
 Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func sync_evidence_hud() -> void:
 set_visible_text(evidence_label,"THE VALE CASE   /   %d OF 6 PHYSICAL FINDS" % state.evidence_count())
 set_visible_text(lead_label,investigation_lead())

func save_game() -> void:
 state.saved_position = [fly.safe_position.x,fly.safe_position.y,fly.safe_position.z]
 state.remember_view(fly.yaw,fly.pitch)
 var err: Error = state.save_to()
 if err != OK: toast("Could not save progress. Your current investigation is still active.",4)

func toast(text: String, seconds: float = 4.0) -> void:
 toast_label.text = text
 toast_time = seconds

func available(id: String) -> bool:
 if id == "chemical": return state.cabinet_open
 if id == "ledger": return state.dispatch_open
 if id == "crate_tag":
  var local: Vector3 = fly.position-Data.CRATE_ORIGIN
  return absf(local.x)<14 and absf(local.z)<16.5 and local.y>2.6 and local.y<24.5
 return true

func hotspot_is_available(id: String) -> bool:
 if not available(id) or (id=="latch" and state.cabinet_open) or (id=="dispatch" and state.dispatch_open): return false
 if id=="night_relay": return fly.position.x<Data.NIGHT_RELAY_POINT.x-0.2
 if id=="nursery_sensor": return fly.position.z<Data.NURSERY_SENSOR_POINT.z-0.2
 if Data.RAIN_POSTS.has(id):
  var point: Vector3 = world.hotspots[id].position
  return signf(point.x)*fly.position.x < 50.4
 return true

func reach(id: String) -> float:
 if Data.TALKS.has(id): return 85.0
 if id == "latch": return 5.0
 if id == "crate_tag": return 5.5
 if id in ["night_relay","nursery_sensor"]: return 8.5
 if Data.RAIN_POSTS.has(id): return 12.5
 return 24.0

func guide_rooms() -> Array:
 if not is_instance_valid(world): return []
 var layout := world.get_node_or_null("CompartmentLayout")
 return layout.get("rooms") if layout != null else []

func set_carriage_pin(index: int) -> void:
 carriage_pin = index if CarriageGuide.valid_pin(index) else -1
 show_notebook("guide")

func update_carriage_cue() -> void:
 var pinned := CarriageGuide.valid_pin(carriage_pin)
 carriage_pin_label.visible = mode=="play" and pinned
 if not carriage_pin_label.visible: return
 var cue := CarriageGuide.guidance(fly.position,fly.yaw,carriage_pin,guide_rooms())
 set_visible_text(carriage_pin_label,cue.get("text",""))

func _process(delta: float) -> void:
 elapsed += delta
 toast_time = max(0,toast_time-delta)
 toast_label.visible = toast_time>0
 prompt_backdrop.visible = mode == "play"
 update_carriage_cue()
 precision_label.visible = mode == "play" and fly.precision and not fly.landed and not fly.jumping
 if mode == "play":
  expire_first_look()
  if fly.position.x < -390.0:
   world.scenery.observe_salon_view(fly.global_position,-fly.camera.global_transform.basis.z)
  save_clock += delta
  if save_clock>12:
   save_clock = 0
   save_game()
  var room := clampi(int(fly.position.z/840.0),0,2)
  set_visible_text(room_label,ROOM_TITLES[room])
  set_visible_text(controls_label,WALK_CONTROLS if fly.landed or fly.jumping else (TOGGLE_CONTROLS if fly.precision_toggle else HOLD_CONTROLS))
  nearest = ""
  var best := INF
  for id in world.hotspots:
   var p: Vector3 = world.hotspots[id].position
   var d := fly.position.distance_to(p)
   var l: Label = markers[id]
   var is_rain_post = Data.RAIN_POSTS.has(id)
   if not hotspot_is_available(id) or d>=(90.0 if is_rain_post else 270.0) or fly.camera.is_position_behind(p):
    l.hide()
    continue
   var screen: Vector2 = fly.camera.unproject_position(p)
   var in_screen: bool = screen.x>15 and screen.x<1425 and screen.y>105 and screen.y<805
   var in_reach := d<reach(id)
   if not in_screen and not in_reach:
    l.hide()
    continue
   # The same solid-world check gates the guide diamond and the interaction.
   # An unobstructed camera can see around the tiny fly, but not through a wall.
   var q := PhysicsRayQueryParameters3D.create(fly.position,p,1)
   var hit := get_world_3d().direct_space_state.intersect_ray(q)
   if interaction_is_blocked(hit,id,p):
    l.hide()
    continue
   l.visible = in_screen
   l.position = screen-Vector2(130,55)
   var sign_text := "·" if state.found.has(id) else ("○" if is_rain_post else "◇")
   var marker_name := "Rain post" if is_rain_post else str(Data.record(id).title)
   set_visible_text(l,sign_text + ("\n"+marker_name if d < (24.0 if is_rain_post else 95.0) else ""))
   var alpha := 1.0 if in_reach else 0.55
   if not is_equal_approx(l.modulate.a,alpha): l.modulate.a = alpha
   if in_reach and d<best:
    best = d
    nearest = id
  if nearest != "":
   if Data.RAIN_POSTS.has(nearest):
    set_visible_text(prompt,"E   Read · Rain post")
   else:
    set_visible_text(prompt,"E   " + ("Listen · " if Data.TALKS.has(nearest) else "Inspect · ") + Data.record(nearest).title)
  elif fly.landed: set_visible_text(prompt,"SPACE   Jump   ·   Double-tap SPACE   Take off")
  elif fly.jumping: set_visible_text(prompt,"SPACE again   Take off" if fly.space_tap_remaining > 0.0 else "Landing…")
  elif world.seed_lift.show_landing_hint(fly.global_position): set_visible_text(prompt,"L   Land on the balance spoon")
  elif first_look_cue_is_current(): set_visible_text(prompt,FIRST_LOOK_PROMPT)
  else: set_visible_text(prompt,"E   Land on a nearby surface")
 listening_mix.step(is_eavesdropping(),delta)
 apply_audio_mix()
 if capture_mode: capture_sequence()

func opening_case_unstarted() -> bool:
 if state.complete or state.cabinet_open or state.dispatch_open: return false
 for id in state.found:
  # Corridor letters and completed side stories are not progress on the case.
  if not Data.RAIN_POSTS.has(id) and not Data.JOURNAL_ONLY.has(id): return false
 return true

func expire_first_look() -> void:
 if first_look_armed and (fly.global_position.distance_to(first_look_origin)>FIRST_LOOK_ROOM_CM or
  fly.landed or fly.jumping or not opening_case_unstarted()):
  first_look_armed = false

func first_look_cue_is_current() -> bool:
 if not first_look_armed or mode!="play" or not world.hotspots.has("cup"):
  return false
 var target: Vector3 = world.hotspots.cup.position
 var gap: float = fly.global_position.distance_to(target)
 if gap<reach("cup") or gap>FIRST_LOOK_CUP_MAX_CM or not hotspot_is_available("cup"):
  return false
 if fly.camera.is_position_behind(target):return false
 if (-fly.camera.global_transform.basis.z).dot(fly.camera.global_position.direction_to(target))<0.70:
  return false
 var ray := PhysicsRayQueryParameters3D.create(fly.global_position,target,1)
 return not interaction_is_blocked(get_world_3d().direct_space_state.intersect_ray(ray),"cup",target)

func closest_current_interaction() -> String:
 # Input can arrive just after a body sweep but before the next HUD update.
 # Refresh a missing target using the normal physical reach and line of sight.
 var closest:=""
 var distance:=INF
 for id in world.hotspots:
  var at:Vector3=world.hotspots[id].position
  var d:float=fly.global_position.distance_to(at)
  if d<distance and interaction_is_current(id):
   closest=id
   distance=d
 return closest

func interaction_is_current(id: String) -> bool:
 if not world.hotspots.has(id) or not hotspot_is_available(id): return false
 var target: Vector3 = world.hotspots[id].position
 if fly.position.distance_to(target)>=reach(id) or fly.camera.is_position_behind(target): return false
 var ray := PhysicsRayQueryParameters3D.create(fly.position,target,1)
 return not interaction_is_blocked(get_world_3d().direct_space_state.intersect_ray(ray),id,target)

func interaction_is_blocked(hit: Dictionary, id: String, target: Vector3) -> bool:
 if hit.is_empty(): return false
 # A person's own surface is the interaction target, even when the authored
 # conversation point lies beneath their coat. Other objects still occlude it.
 if Data.TALKS.has(id):
  var node: Node = hit.collider
  while node != null and node != world:
   if node.get_meta("hotspot_id","") == id: return false
   node = node.get_parent()
 # These station points are placed just in front of existing physical faces.
 if id in ["night_relay","nursery_sensor"] or Data.RAIN_POSTS.has(id): return hit.position.distance_to(target)>0.45
 return hit.position.distance_to(target) > (10.0 if id=="cup" else 4.0)

func _unhandled_input(event: InputEvent) -> void:
 if not event is InputEventKey or not event.pressed or event.echo: return
 if event.keycode == KEY_ESCAPE:
  if mode == "play": show_pause()
  elif mode == "title": quit_game()
  elif mode in ["new_case_confirm","save_unavailable"]: show_title()
  elif mode == "ending_view": show_ending()
  elif mode == "notebook": close_notebook()
  elif mode == "photo": close_photo()
  elif mode == "trace_macro": close_trace_macro()
  elif mode == "settings":
   if hud.visible: show_pause()
   else: show_title()
  else: resume_game()
  get_viewport().set_input_as_handled()
 elif mode == "play":
  match event.keycode:
   KEY_E:
    expire_first_look()
    if nearest=="" or (first_look_armed and not interaction_is_current(nearest)):
     nearest = closest_current_interaction()
    if nearest!="":
     # E may arrive after the marker's frame. Verify the same record and its
     # current sight line without silently falling through to a land action.
     if interaction_is_current(nearest): show_inspection(nearest)
     else:
      nearest = ""
      toast("Move closer and get a clear view to inspect.")
    elif first_look_cue_is_current():
     toast("Get a little closer to the cup. L lands.")
    elif not fly.try_land(): toast("Move within 18 cm of a horizontal surface to land. Tap Space to jump; double-tap to take off.")
   KEY_L:
    first_look_armed = false
    var previously_landed: bool = fly.landed
    if not fly.try_land(): toast("Move within 18 cm of a horizontal surface to land.")
    elif not previously_landed and fly.landed: release_seed_on_spoon()
   KEY_J: show_notebook()
   KEY_TAB: show_deduction()
   KEY_H: show_controls()
 elif mode == "inspection" and event.keycode == KEY_E: resume_game()
 elif mode == "trace_macro" and event.keycode == KEY_E: close_trace_macro()
 elif mode == "notebook" and event.keycode == KEY_J: close_notebook()
 elif mode == "photo" and event.keycode == KEY_J: close_photo()
 elif mode == "deduction":
  if event.keycode == KEY_TAB: resume_game()
  elif event.keycode == KEY_J: review_deduction_evidence()

func release_seed_on_spoon() -> void:
 if state.found.has("seed_return_ready") or not is_instance_valid(world.seed_lift): return
 if not world.seed_lift.supports_landing(fly.global_position,get_world_3d().direct_space_state): return
 if state.discover("seed_return_ready"):
  save_game()
  world.seed_lift.begin_return()
  toast("One seed for the shore.")

func show_inspection(id: String,first_pass: bool = true) -> void:
 first_look_armed = false
 current_id = id
 var carriage_index := clampi(int(fly.position.z/840.0),0,2)
 set_visible_text(room_label,ROOM_TITLES[carriage_index])
 mode = "inspection"
 overlay(0)
 fly.active = true
 toast_time = 0
 prompt.text = ""
 if Data.RAIN_POSTS.has(id):
  var point: Vector3 = world.hotspots[id].position
  # There is real wall geometry behind each pocket. Keep this inspection
  # camera on the corridor side and leave ordinary object orbit unaffected.
  fly.inspect_at(point,22.0)
  fly.inspect_yaw = -signf(point.x)*PI/2
  fly.inspect_pitch = 0.27
  fly.camera.h_offset = 4.8
  fly.active = false
 elif id=="crate_tag":
  # Keep an inspection camera at actual fly scale inside the slats.
  fly.inspect_at(world.hotspots[id].position,4.4,5.2)
  fly.inspect_yaw = -PI/2
  fly.inspect_pitch = 0.28
  fly.camera.h_offset = 1.1
 elif id in ["night_relay","nursery_sensor"]:
  # Start on the physical control face, not behind the radio or planter.
  fly.inspect_at(world.hotspots[id].position,13.5,35.0)
  fly.inspect_yaw = -PI/2 if id=="night_relay" else PI
  fly.inspect_pitch = 0.27
  fly.camera.h_offset = 2.4
 else:
  fly.inspect_at(world.hotspots[id].position,70.0 if Data.TALKS.has(id) else 24.0)
  # Keep the inspected prop left of the evidence card.
  fly.camera.h_offset = 5.5 if not Data.TALKS.has(id) else 16.0
 fly.update_camera(0)
 var r := Data.record(id)
 var p := panel(modal,Vector2(925,150),Vector2(470,625),Color(0.035,0.10,0.085,0.97))
 label(p,r.kind+"   /   "+r.place,Vector2(26,27),Vector2(416,50),12,GOLD)
 label(p,r.title,Vector2(26,94),Vector2(410,100),34,PAPER,true)
 rect(p,Vector2(27,197),Vector2(45,2),GOLD)
 var reading_text: String = r.text
 if id=="nursery_sensor" and state.nursery_restored:
  reading_text = "Air moving. Night lamps on. The seedlings can wait for morning."
 label(p,reading_text,Vector2(26,225),Vector2(414,220),18,PAPER)
 if id=="nursery_sensor":
  if not state.nursery_diagnosed:
   state.nursery_diagnosed = true
   save_game()
 elif id=="night_relay":
  show_night_relay_controls(p)
 elif id=="latch":
  button(p,"BRIDGE THE CONTACT",Vector2(26,490),Vector2(414,50),release_latch)
 elif id=="dispatch":
  button(p,"EXAMINE SYMBOL LOCK",Vector2(26,490),Vector2(414,50),show_lock)
 else:
  var fresh: bool = state.discover(id) if first_pass else false
  var can_study := TraceNotes.MACROS.has(id) and trace_is_discovered(id)
  label(p,"✓  RECORDED IN YOUR NOTEBOOK" if fresh else "✓  PREVIOUSLY RECORDED",Vector2(26,452 if can_study else 495),Vector2(415,34),12,GOLD)
  if can_study:
   button(p,"Study the mark",Vector2(26,493),Vector2(414,44),show_trace_macro.bind(id))
  sync_evidence_hud()
  if first_pass: save_game()
 button(p,"Return to flight   [E / Esc]",Vector2(26,555),Vector2(414,46),resume_game).grab_focus()
 label(modal,"A CLOSER LOOK",Vector2(45,145),Vector2(500,32),14,GOLD)
 rect(modal,Vector2(35,767),Vector2(795,47),Color(0.035,0.10,0.085,0.95))
 label(modal,"Press E or Esc to return to flight" if Data.RAIN_POSTS.has(id) else "Hold right mouse and drag to orbit · Scroll to zoom",
  Vector2(45,778),Vector2(780,30),15,PAPER)
 if first_pass and id not in ["nursery_sensor","night_relay"] and not Data.RAIN_POSTS.has(id): capture_evidence(id)

func trace_is_discovered(id: String) -> bool:
 if not state.found.has(id) or not available(id): return false
 if id=="chemical": return is_instance_valid(world) and not world.cabinet_door.visible
 if id=="ledger": return is_instance_valid(world) and not world.drawer.visible
 return true

func set_trace_lens(id: String) -> bool:
 var note: Dictionary = TraceNotes.MACROS[id]
 var camera: Camera3D = fly.camera
 var prior := camera.global_transform
 var prior_offset := camera.h_offset
 camera.h_offset = 0.95
 var space := get_world_3d().direct_space_state
 for authored_eye in note.eyes:
  camera.global_position = authored_eye
  camera.look_at(note.focus,Vector3.UP)
  if not fly.inspection_eye_is_clear(): continue
  var optical_eye := camera.get_camera_transform().origin
  var blocker := space.intersect_ray(PhysicsRayQueryParameters3D.create(optical_eye,note.focus,1))
  # The last few millimetres may be the target's own surface, not a wall.
  if blocker.is_empty() or blocker.position.distance_to(note.focus)<0.35: return true
 camera.global_transform = prior
 camera.h_offset = prior_offset
 return false

func show_trace_macro(id: String) -> void:
 if mode!="inspection" or current_id!=id or not TraceNotes.MACROS.has(id) or not trace_is_discovered(id): return
 var prior := {"focus":fly.focus,"distance":fly.inspect_distance,"max_distance":fly.inspect_max_distance,"yaw":fly.inspect_yaw,"pitch":fly.inspect_pitch,"offset":fly.camera.h_offset}
 if not set_trace_lens(id):
  toast("There isn’t a clear close-up from this angle.")
  return
 trace_camera_state = prior
 fly.inspection = false
 mode = "trace_macro"
 overlay(0)
 var note: Dictionary = TraceNotes.MACROS[id]
 var p := panel(modal,Vector2(925,150),Vector2(470,480),Color(0.035,0.10,0.085,0.97))
 label(p,"FIELD STUDY    /    "+Data.record(id).place,Vector2(26,34),Vector2(418,42),13,GOLD)
 label(p,note.label,Vector2(26,104),Vector2(418,77),32,PAPER,true)
 label(p,note.description,Vector2(26,208),Vector2(410,133),18,PAPER)
 button(p,"Back to inspection   [E / Esc]",Vector2(26,391),Vector2(414,46),close_trace_macro).grab_focus()

func close_trace_macro() -> void:
 if mode!="trace_macro" or trace_camera_state.is_empty(): return
 var prior := trace_camera_state.duplicate()
 trace_camera_state.clear()
 show_inspection(current_id,false)
 fly.inspect_at(prior.focus,prior.distance,prior.max_distance)
 fly.inspect_yaw = prior.yaw
 fly.inspect_pitch = prior.pitch
 fly.camera.h_offset = prior.offset
 fly.update_camera(0)

func _input(event: InputEvent) -> void:
 if mode=="inspection" and not Data.RAIN_POSTS.has(current_id):
  if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT:
   Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
   get_viewport().set_input_as_handled()

func read_evidence_thumbnail(path: String) -> ImageTexture:
 var file := FileAccess.open(path,FileAccess.READ)
 if file == null or file.get_length() < 24 or file.get_length() > 8*1024*1024: return null
 if file.get_buffer(PNG_HEADER.size()) != PackedByteArray(PNG_HEADER): return null
 file.seek(0)
 var image := Image.new()
 if image.load_png_from_buffer(file.get_buffer(file.get_length())) != OK or image.is_empty(): return null
 return ImageTexture.create_from_image(image)

func format_field_photograph(image: Image) -> Image:
 # Keep the same object-side frame, but scale it uniformly. Stretching this
 # near-square portrait to 4:3 used to turn round evidence into ovals.
 var crop := image.get_region(Rect2i(0,0,maxi(1,int(image.get_width()*0.62)),image.get_height()))
 var scale_factor := minf(1.0,minf(560.0/crop.get_width(),420.0/crop.get_height()))
 if scale_factor<1.0:
  crop.resize(maxi(1,roundi(crop.get_width()*scale_factor)),maxi(1,roundi(crop.get_height()*scale_factor)),Image.INTERPOLATE_LANCZOS)
 return crop

func capture_evidence(id: String) -> void:
 if DisplayServer.get_name()=="headless" or thumbnails.has(id): return
 var output_path: String = state.evidence_photo_path(id)
 # Continuing a case should retain the first good photograph, not recapture
 # it on every opening or overwrite the player's earlier point of view.
 if FileAccess.file_exists(output_path):
  var saved := read_evidence_thumbnail(output_path)
  if saved != null:
   thumbnails[id] = saved
   return
 var requested := Time.get_ticks_usec() if profile_photos else 0
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 if mode!="inspection" or current_id!=id or output_path!=state.evidence_photo_path(id) or thumbnails.has(id): return
 var draw_complete := Time.get_ticks_usec() if profile_photos else 0
 var image := get_viewport().get_texture().get_image()
 if image==null or image.is_empty(): return
 var readback_complete := Time.get_ticks_usec() if profile_photos else 0
 var crop := format_field_photograph(image)
 var resize_complete := Time.get_ticks_usec() if profile_photos else 0
 thumbnails[id] = ImageTexture.create_from_image(crop)
 DirAccess.make_dir_recursive_absolute(output_path.get_base_dir())
 var write_started := Time.get_ticks_usec() if profile_photos else 0
 crop.save_png(output_path)
 if profile_photos:
  print("PHOTO_PROFILE %s frame_wait=%.2fms readback=%.2fms resize=%.2fms png_write=%.2fms" % [
   id,(draw_complete-requested)/1000.0,(readback_complete-draw_complete)/1000.0,
   (resize_complete-readback_complete)/1000.0,(Time.get_ticks_usec()-write_started)/1000.0
  ])

func show_night_relay_controls(p: Panel) -> void:
 var notice := ""
 if not state.nursery_diagnosed: notice = "Check the nursery readings in Live Reserve (08) first."
 elif state.nursery_restored: notice = "Airflow already restored."
 night_relay_status = label(p,notice,Vector2(26,345),Vector2(414,82),17,GOLD)
 night_relay_choice = OptionButton.new()
 for name_text in ["Choose a circuit…","HEAT","WATER","AIR"]: night_relay_choice.add_item(name_text)
 night_relay_choice.set_item_disabled(0,true)
 night_relay_choice.disabled = not state.nursery_diagnosed or state.nursery_restored
 night_relay_choice.position = Vector2(26,430)
 night_relay_choice.size = Vector2(414,48)
 p.add_child(night_relay_choice)
 night_relay_pulse = button(p,"Send test pulse",Vector2(26,490),Vector2(414,44),func():
  night_relay_status.text = send_night_relay_pulse(night_relay_choice.selected)
  night_relay_choice.disabled = state.nursery_restored
  # A second deliberate pulse only reports that the circuit is already on.
 )
 night_relay_pulse.disabled = not state.nursery_diagnosed

func send_night_relay_pulse(circuit: int) -> String:
 if mode!="inspection" or current_id!="night_relay" or not interaction_is_current("night_relay"):
  return "Move to the front of the relay to send a test pulse."
 if not state.nursery_diagnosed: return "Check the nursery readings in Live Reserve (08) first."
 if state.nursery_restored: return "Airflow already restored."
 if circuit<=0: return "Choose a circuit first."
 if circuit!=3: return "That circuit is already in tolerance. Nothing changed."
 state.nursery_restored = true
 state.discover("nursery_restored")
 world.set_nursery_task_light(true)
 sync_evidence_hud()
 save_game()
 return "AIR • FLOW RESTORED"

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
 button(p,"Back to flight",Vector2(390,467),Vector2(330,52),resume_game).grab_focus()

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
 if mode not in ["loading","title","new_case_confirm","save_unavailable"] and is_instance_valid(fly): save_game()
 if is_instance_valid(ambience):
  ambience.stop()
  ambience.stream = null
 if is_instance_valid(wings):
  wings.stop()
  wings.stream = null
 await get_tree().create_timer(0.15).timeout
 get_tree().quit()

func remember_deduction_draft() -> void:
 if not is_instance_valid(suspect_select) or not is_instance_valid(motive_select): return
 var checked: Array[String] = []
 for id in evidence_checks:
  if state.found.has(id) and evidence_checks[id].button_pressed: checked.append(id)
 deduction_draft = {"suspect":suspect_select.selected,"motive":motive_select.selected,"evidence":checked}

func review_deduction_evidence() -> void:
 remember_deduction_draft()
 deduction_review = deduction_draft.duplicate(true)
 show_notebook()

func close_notebook() -> void:
 if deduction_review.is_empty():
  resume_game()
  return
 deduction_draft = deduction_review.duplicate(true)
 deduction_review.clear()
 show_deduction()

func show_notebook(selected: String = "") -> void:
 if Data.RAIN_POSTS.has(selected) and not state.found.has(selected): selected = "world"
 notebook_page = selected
 mode = "notebook"
 overlay(0.85)
 var p := panel(modal,Vector2(55,130),Vector2(1330,655))
 label(p,"FIELD NOTES   /   THE VALE CASE",Vector2(28,24),Vector2(1000,28),14,GOLD)
 label(p,"Small observations. A larger truth.",Vector2(28,66),Vector2(1200,70),36,PAPER,true)
 var close := button(p,"Close  [J]" if deduction_review.is_empty() else "Back to deduction  [J]",Vector2(1050,22),Vector2(250,44),close_notebook)
 var scroll := ScrollContainer.new()
 scroll.position = Vector2(26,157)
 scroll.size = Vector2(380,462)
 p.add_child(scroll)
 var list := VBoxContainer.new()
 list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 scroll.add_child(list)
 var objective := Button.new()
 objective.text = "THE VALE CASE"
 objective.custom_minimum_size = Vector2(360,53)
 objective.pressed.connect(func(): show_notebook())
 list.add_child(objective)
 var guide := Button.new()
 guide.text = "▸  CARRIAGE GUIDE" if selected=="guide" else "CARRIAGE GUIDE"
 if selected=="guide":
  guide.add_theme_color_override("font_color",GOLD)
  guide.add_theme_stylebox_override("normal",style(Color("31594e"),1))
 guide.custom_minimum_size = Vector2(360,50)
 guide.pressed.connect(func(): show_notebook("guide"))
 list.add_child(guide)
 var traces := Button.new()
 traces.text = "▸  TRACE BOARD" if selected=="trace" else "TRACE BOARD"
 traces.custom_minimum_size = Vector2(360,50)
 if selected=="trace":
  traces.add_theme_color_override("font_color",GOLD)
  traces.add_theme_stylebox_override("normal",style(Color("31594e"),1))
 traces.pressed.connect(func(): show_notebook("trace"))
 list.add_child(traces)
 var life := Button.new()
 life.text = "LIFE ABOARD THE NOCTURNE"
 life.custom_minimum_size = Vector2(360,50)
 life.pressed.connect(func(): show_notebook("world"))
 list.add_child(life)
 for id in state.found:
  if Data.RAIN_POSTS.has(id): continue
  var b := Button.new()
  b.text = ("◆  " if Data.CLUES.has(id) else "·  ")+Data.record(id).title
  b.alignment = HORIZONTAL_ALIGNMENT_LEFT
  b.custom_minimum_size = Vector2(360,50)
  b.pressed.connect(show_notebook.bind(id))
  list.add_child(b)
 rect(p,Vector2(427,155),Vector2(1,459),Color("536355"))
 if selected=="":
  label(p,"Elias Vale died after his evening tea.",Vector2(465,158),Vector2(810,55),27,PAPER,true)
  var lead := investigation_lead()
  if not lead.is_empty(): label(p,lead,Vector2(465,207),Vector2(800,24),16,GOLD)
  label(p,"Find a means, a motive, and a link to the culprit. You are a witness, not a courier: examine the objects where they lie. Eavesdrop near the residents to hear their accounts.",Vector2(465,233),Vector2(800,110),19,MUTED)
  label(p,"Need your bearings? The carriage guide shows the corridor, doors and where you are now.",Vector2(465,366),Vector2(800,75),18,PAPER)
  button(p,"Open the carriage guide",Vector2(465,458),Vector2(335,50),func(): show_notebook("guide"))
 elif selected=="guide":
  show_carriage_guide(p)
 elif selected=="trace":
  show_trace_board(p)
 elif selected=="world":
  label(p,"A CITY THAT NEVER QUITE ARRIVES",Vector2(465,158),Vector2(810,35),14,GOLD)
  label(p,"A home between stations.",Vector2(465,205),Vector2(810,65),32,PAPER,true)
  label(p,"The Nocturne is a twelve-carriage home on the night network. Outside, the city changes districts. Inside, neighbours keep the same tables, small rituals and long memories.",
   Vector2(465,286),Vector2(448,101),17,PAPER)
  label(p,"OLD CRAFT / QUIET MACHINES",Vector2(465,396),Vector2(448,25),13,GOLD)
  label(p,"Mahogany hides service conduits. Brass frames the displays. Velvet quiets the rails. Comfort comes before spectacle.",
   Vector2(465,427),Vector2(448,82),17,MUTED)
  label(p,"THE LIVING ARCHIVE",Vector2(465,525),Vector2(448,25),13,GOLD)
  label(p,"The botanical trust keeps threatened plants for their return to the wild. A cutting is a future forest.",
   Vector2(465,552),Vector2(448,74),17,PAPER)
  show_rain_post_list(p)
 else:
  var r := Data.record(selected)
  label(p,r.place+"   /   "+r.kind,Vector2(465,157),Vector2(820,35),12,GOLD)
  label(p,r.title,Vector2(465,205),Vector2(810,70),32,PAPER,true)
  label(p,r.text,Vector2(465,287),Vector2(795,200),19,PAPER)
  label(p,r.get("detail","A detail of life aboard the Nocturne."),Vector2(465,506),Vector2(800,65),16,GOLD)
  if Data.RAIN_POSTS.has(selected): button(p,"Back to the Rain Post",Vector2(465,570),Vector2(335,48),func(): show_notebook("world"))
  elif not Data.JOURNAL_ONLY.has(selected):
   if thumbnails.has(selected) or FileAccess.file_exists(state.evidence_photo_path(selected)):
    button(p,"View field photograph",Vector2(465,570),Vector2(335,48),func(): show_photo(selected))
   else:
    label(p,"No photograph yet. Reinspect the object to capture one.",Vector2(465,570),Vector2(795,48),15,MUTED)
 # Each page rebuild removes its previous focused control; provide a safe
 # keyboard starting point without making a hidden selection.
 close.grab_focus()

func show_carriage_guide(p: Panel) -> void:
 var actual := CarriageGuide.carriage(fly.position)
 label(p,"PASSENGER PLAN    /    CARRIAGES 06–08",Vector2(465,158),Vector2(807,34),14,GOLD)
 label(p,"Find your way along the train.",Vector2(465,205),Vector2(807,59),30,PAPER,true)
 var rooms:=guide_rooms()
 var space:PhysicsDirectSpaceState3D = get_world_3d().direct_space_state if is_inside_tree() else null
 var detail:=CarriageGuide.location_detail(fly.position,fly.yaw,fly.pitch,rooms,space)
 var location:String="You’re here: "+CarriageGuide.NUMBERS[actual]+" · "+CarriageGuide.NAMES[actual]
 if not detail.get("name","").is_empty():
  location+=("   /   Room: " if detail.kind=="room" else "   /   Facing door: ")+detail.name
 label(p,location,Vector2(465,268),Vector2(807,33),17,PAPER)
 var map := CarriageGuideMap.new()
 map.position = Vector2(465,316)
 map.size = Vector2(800,205)
 map.rooms = rooms
 map.player = fly.position
 map.pin = carriage_pin
 map.mouse_filter = Control.MOUSE_FILTER_IGNORE
 p.add_child(map)
 for index in range(CarriageGuide.NUMBERS.size()):
  var name_text: String = CarriageGuide.NUMBERS[index]+" · "+CarriageGuide.NAMES[index]
  var pin_button := button(p,name_text+("  ✓" if carriage_pin==index else ""),Vector2(465+index*269,532),Vector2(258,44),set_carriage_pin.bind(index))
  pin_button.set_meta("carriage_pin",index)
  pin_button.tooltip_text = "Pin this carriage to see a corridor cue during flight"
 if CarriageGuide.valid_pin(carriage_pin):
  label(p,"Gold dot: you. Gold outline: pinned carriage.",Vector2(465,590),Vector2(571,38),15,MUTED)
  button(p,"Clear pin",Vector2(1047,589),Vector2(216,40),set_carriage_pin.bind(-1)).set_meta("clear_carriage_pin",true)
 else:
  label(p,"Gold dot: your position. Select a carriage to pin it during flight.",Vector2(465,590),Vector2(799,38),15,MUTED)

func show_rain_post_list(p: Panel) -> void:
 rect(p,Vector2(932,278),Vector2(1,346),Color("536355"))
 label(p,"THE RAIN POST",Vector2(955,281),Vector2(337,30),15,GOLD)
 label(p,"Neighbours leave notes in little brass pockets along the corridor.",Vector2(955,319),Vector2(337,57),16,MUTED)
 var index := 0
 var read := 0
 var places := ["06 · Sleeper corridor","07 · Service end","08 · Seed archive corridor"]
 for id in Data.RAIN_POSTS:
  var opened: bool = state.found.has(id)
  if opened: read += 1
  var note := button(p,places[index]+"   /   "+("Read" if opened else "Unread"),Vector2(955,389+index*58),Vector2(344,48),show_notebook.bind(id))
  note.set_meta("rain_post_id",id)
  note.alignment = HORIZONTAL_ALIGNMENT_LEFT
  note.add_theme_color_override("font_disabled_color",MUTED)
  note.add_theme_stylebox_override("disabled",style(Color("172e29"),1))
  note.disabled = not opened
  index += 1
 if read == Data.RAIN_POSTS.size():
  label(p,"The boards tell you which carriage you’re in. The scraps tell you who lives there.",Vector2(955,573),Vector2(345,63),15,MUTED)

func trace_choices_available() -> Array[String]:
 var available_ids: Array[String] = []
 for id in TraceNotes.ORDER:
  if trace_is_discovered(id): available_ids.append(id)
 return available_ids

func select_trace(slot: int,id: String) -> bool:
 if slot<0 or slot>1: return false
 if not id.is_empty() and (not TraceNotes.FIELD.has(id) or not trace_is_discovered(id) or trace_choices[1-slot]==id): return false
 trace_choices[slot] = id
 return true

func trace_selected(item: int,slot: int) -> void:
 var chosen: String = trace_selectors[slot].get_item_metadata(item)
 if not select_trace(slot,chosen): return
 show_notebook("trace")
 trace_selectors[slot].grab_focus()

func show_trace_board(p: Panel) -> void:
 var current := trace_choices_available()
 for slot in range(2):
  if not current.has(trace_choices[slot]): trace_choices[slot] = ""
 trace_selectors.clear()
 label(p,"TRACE BOARD    /    FIELD COMPARISON",Vector2(465,155),Vector2(810,34),14,GOLD)
 label(p,"Look at two findings together.",Vector2(465,192),Vector2(810,51),30,PAPER,true)
 label(p,"A resemblance can be a lead. It isn’t proof by itself.",Vector2(465,248),Vector2(810,28),16,MUTED)
 for slot in range(2):
  var x := 465+slot*409
  var options := OptionButton.new()
  p.add_child(options)
  options.position = Vector2(x,296)
  options.size = Vector2(393,48)
  options.set_meta("trace_slot",slot)
  options.add_item("Choose a finding")
  options.set_item_metadata(0,"")
  options.select(0)
  for id in current:
   options.add_item(Data.record(id).title)
   var item := options.item_count-1
   options.set_item_metadata(item,id)
   if trace_choices[1-slot]==id: options.set_item_disabled(item,true)
   if trace_choices[slot]==id: options.select(item)
  options.disabled = current.is_empty()
  options.item_selected.connect(trace_selected.bind(slot))
  trace_selectors.append(options)
  show_trace_tile(p,Vector2(x,359),trace_choices[slot])

func show_trace_tile(p: Panel,at: Vector2,id: String) -> void:
 var tile := panel(p,at,Vector2(394,264),Color("172d28"))
 if id.is_empty():
  label(tile,"No finding selected",Vector2(23,37),Vector2(348,48),22,PAPER,true)
  label(tile,"Inspect an object aboard the train to bring it here.",Vector2(23,104),Vector2(348,76),17,MUTED)
  return
 var observed: Dictionary = TraceNotes.FIELD[id]
 var record := Data.record(id)
 label(tile,record.place,Vector2(22,14),Vector2(349,26),12,MUTED)
 label(tile,record.title,Vector2(22,45),Vector2(351,57),24,PAPER,true)
 label(tile,observed.feature,Vector2(22,111),Vector2(349,27),15,GOLD)
 var has_tracing: bool = observed.graphic=="fragments"
 if has_tracing:
  var graphic := TraceGraphic.new()
  graphic.position = Vector2(289,141)
  graphic.size = Vector2(75,55)
  graphic.mouse_filter = Control.MOUSE_FILTER_IGNORE
  tile.add_child(graphic)
  label(tile,"Field tracing",Vector2(281,194),Vector2(93,14),11,MUTED)
 label(tile,observed.words,Vector2(22,147),Vector2(256 if has_tracing else 348,54),15,PAPER)
 if thumbnails.has(id) or FileAccess.file_exists(state.evidence_photo_path(id)):
  button(tile,"Photo",Vector2(22,211),Vector2(104,37),show_photo.bind(id,true))
 var visible_draft: Dictionary = deduction_draft if deduction_review.is_empty() else deduction_review
 var queued: bool = id in visible_draft.get("evidence",[])
 var note_button := button(tile,"In deduction draft" if queued else "Add to deduction draft",Vector2(140,211),Vector2(231,37),add_trace_to_draft.bind(id))
 note_button.disabled = queued

func add_trace_to_draft(id: String) -> void:
 if not TraceNotes.FIELD.has(id) or not trace_is_discovered(id): return
 if deduction_review.is_empty():
  deduction_review = deduction_draft.duplicate(true)
  if deduction_review.is_empty(): deduction_review = {"suspect":0,"motive":0,"evidence":[]}
 if not deduction_review.evidence.has(id): deduction_review.evidence.append(id)
 show_notebook("trace")

func close_photo() -> void:
 show_notebook(photo_return_page if not photo_return_page.is_empty() else photo_entry)

func show_photo(id: String,from_trace: bool = false) -> void:
 if from_trace and not trace_is_discovered(id): return
 var status_name := "PhotoStatus_"+id if from_trace else "PhotoStatus"
 if modal.get_node_or_null(status_name) != null: return
 var path: String = state.evidence_photo_path(id)
 if not thumbnails.has(id) and FileAccess.file_exists(path):
  var texture := read_evidence_thumbnail(path)
  if texture != null: thumbnails[id] = texture
 if not thumbnails.has(id):
  # The play-layer toast is hidden by the notebook shade.
  label(modal,"This photograph couldn’t be opened. Reinspect the object to take another.",Vector2(520,752),Vector2(795,30),15,GOLD).name = status_name
  return
 mode = "photo"
 photo_entry = id
 photo_return_page = "trace" if from_trace else id
 overlay(0.94)
 var pic := TextureRect.new()
 pic.texture = thumbnails[id]
 pic.position = Vector2(300,110)
 pic.size = Vector2(840,630)
 pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 modal.add_child(pic)
 label(modal,Data.record(id).title,Vector2(300,755),Vector2(650,50),25,PAPER,true)
 button(modal,"Back to board" if from_trace else "Back to notes",Vector2(970,755),Vector2(180,48),close_photo)

func show_deduction() -> void:
 mode = "deduction"
 overlay(0.9)
 evidence_checks.clear()
 var p := panel(modal,Vector2(155,135),Vector2(1130,645))
 label(p,"THE FINAL DEDUCTION",Vector2(32,25),Vector2(1000,30),14,GOLD)
 label(p,"Who silenced Elias Vale?",Vector2(32,75),Vector2(1030,65),40,PAPER,true)
 label(p,"Choose findings that support your case. You can keep investigating and return to this draft.",Vector2(32,150),Vector2(1040,50),18,MUTED)
 suspect_select = OptionButton.new()
 suspect_select.add_item("Choose a suspect…")
 for text in ["Culprit: Mara Sable · steward","Culprit: Dr Lian Moss · botanist","Culprit: Ivo Chen · engineer"]: suspect_select.add_item(text)
 suspect_select.position = Vector2(32,225)
 suspect_select.size = Vector2(505,52)
 p.add_child(suspect_select)
 suspect_select.set_item_disabled(0,true)
 motive_select = OptionButton.new()
 motive_select.add_item("Choose a motive…")
 for text in ["Motive: conceal illegal plant sales","Motive: revenge for the orchids","Motive: cover up faulty maintenance"]: motive_select.add_item(text)
 motive_select.position = Vector2(567,225)
 motive_select.size = Vector2(530,52)
 p.add_child(motive_select)
 motive_select.set_item_disabled(0,true)
 label(p,"SUPPORTING EVIDENCE   /   %d FOUND" % state.evidence_count(),Vector2(32,308),Vector2(790,28),13,GOLD)
 button(p,"Review notebook  [J]",Vector2(847,296),Vector2(250,44),review_deduction_evidence)
 for id in Data.ESSENTIAL:
  if not state.found.has(id):continue
  var i:=evidence_checks.size()
  var check := CheckBox.new()
  # The themed checkbox is 53 px tall even when its requested height is 42.
  check.position = Vector2(32+(i%2)*535,353+(i/2)*56)
  check.size = Vector2(520,42)
  check.text = Data.record(id).title
  p.add_child(check)
  evidence_checks[id] = check
 if evidence_checks.is_empty():
  label(p,"No physical findings yet. Inspect objects aboard the train to gather evidence.",
   Vector2(32,357),Vector2(1040,52),17,MUTED)
 ending_text = label(p,"",Vector2(32,526),Vector2(1050,36),17,GOLD)
 deduction_submit = button(p,"Present deduction   →",Vector2(32,570),Vector2(505,48),submit_case)
 suspect_select.item_selected.connect(update_deduction_choices)
 motive_select.item_selected.connect(update_deduction_choices)
 if not deduction_draft.is_empty():
  suspect_select.select(clampi(int(deduction_draft.suspect),0,suspect_select.item_count-1))
  motive_select.select(clampi(int(deduction_draft.motive),0,motive_select.item_count-1))
  for id in deduction_draft.evidence:
   if evidence_checks.has(id): evidence_checks[id].button_pressed=true
 update_deduction_choices(0)
 button(p,"Keep investigating",Vector2(567,570),Vector2(530,48),resume_game)

func update_deduction_choices(_index: int) -> void:
 var ready := suspect_select.selected > 0 and motive_select.selected > 0
 deduction_submit.disabled = not ready
 ending_text.text = "" if ready else "Choose a suspect and a motive before presenting your deduction."

func submit_case() -> void:
 if suspect_select.selected <= 0 or motive_select.selected <= 0:
  update_deduction_choices(0)
  return
 remember_deduction_draft()
 var selected: Array = deduction_draft.get("evidence",[])
 if selected.is_empty():
  ending_text.text = "Select physical evidence you’ve found before presenting your deduction."
  return
 if Data.solved(suspect_select.selected-1,motive_select.selected-1,selected):
  state.complete = true
  save_game()
  show_ending()
 else:
  ending_text.text = "This deduction isn’t supported yet. Review the evidence for how Vale died and why."

func show_ending() -> void:
 restore_player_camera_after_resolved_view()
 mode = "ending"
 overlay(0.87)
 label(modal,"CASE CLOSED   /   THE LAST TEA",Vector2(220,190),Vector2(1000,40),16,GOLD)
 label(modal,"The smallest witness\nsaw the whole thing.",Vector2(215,270),Vector2(1050,160),53,PAPER,true)
 var aftermath := "At dawn, the inspector finds the dispatch drawer still open. Vale’s ledger is in plain sight. No one thinks to thank the fly." if state.dispatch_open else "At dawn, an inspector searches the train. No one thinks to thank the fly."
 label(modal,"Mara Sable poisoned Vale’s cup to conceal her trade in protected orchids. The bottle, the ledger, and his final note tell the story she could not.\n\n"+aftermath,Vector2(220,475),Vector2(965,190),22,PAPER)
 button(modal,"Return to the train",Vector2(220,719),Vector2(390,58),resume_game)
 button(modal,"Title screen",Vector2(640,719),Vector2(390,58),show_title)
 if resolved_archive_eye().is_finite():
  button(modal,"Linger in the archive",Vector2(1060,719),Vector2(320,58),show_resolved_archive)

func resolved_archive_eye() -> Vector3:
 # Only the real resolved room is staged; do not manufacture a fallback
 # epilogue, alter the sealed drawer, or use a view that intersects a wall.
 if not state.complete or not state.dispatch_open or not is_instance_valid(world) or not is_instance_valid(world.drawer) or world.drawer.visible:
  return Vector3.INF
 var space:=get_world_3d().direct_space_state
 var camera_sphere:=SphereShape3D.new()
 camera_sphere.radius = 0.26
 var query:=PhysicsShapeQueryParameters3D.new()
 query.shape = camera_sphere
 query.collision_mask = 1
 for eye: Vector3 in RESOLVED_ARCHIVE_EYES:
  query.transform.origin=eye
  if not space.intersect_shape(query,1).is_empty():continue
  var ray:=PhysicsRayQueryParameters3D.create(eye,RESOLVED_ARCHIVE_FOCUS,1)
  var hit:=space.intersect_ray(ray)
  if hit.is_empty() or hit.position.distance_to(RESOLVED_ARCHIVE_FOCUS)<2.5:
   return eye
 return Vector3.INF

func show_resolved_archive() -> void:
 if mode!="ending":return
 var eye:=resolved_archive_eye()
 if not eye.is_finite():return
 had_hud_before_resolved_view = hud.visible
 mode = "ending_view"
 overlay(0.0)
 hud.visible = false
 resolved_archive_camera=Camera3D.new()
 resolved_archive_camera.name="QuietArchiveView"
 resolved_archive_camera.near=0.08
 resolved_archive_camera.far=8000
 resolved_archive_camera.fov=60.0
 add_child(resolved_archive_camera)
 resolved_archive_camera.global_position=eye
 resolved_archive_camera.look_at(RESOLVED_ARCHIVE_FOCUS,Vector3.UP)
 resolved_archive_camera.make_current()
 rect(modal,Vector2(0,754),Vector2(1440,146),Color(0.022,0.055,0.045,0.94))
 label(modal,"AFTER THE LAST TEA",Vector2(56,773),Vector2(630,33),14,GOLD)
 label(modal,"The train carries on.",Vector2(53,805),Vector2(650,54),28,PAPER,true)
 button(modal,"Back to the result  [Esc]",Vector2(752,805),Vector2(323,52),show_ending)
 button(modal,"Return to the train",Vector2(1105,805),Vector2(295,52),resume_game)

func restore_player_camera_after_resolved_view() -> void:
 if not is_instance_valid(resolved_archive_camera):return
 fly.camera.make_current()
 remove_child(resolved_archive_camera)
 resolved_archive_camera.queue_free()
 resolved_archive_camera = null
 hud.visible = had_hud_before_resolved_view

func show_pause() -> void:
 mode = "pause"
 overlay(0.78)
 var p := panel(modal,Vector2(465,170),Vector2(510,580))
 label(p,"A MOMENT BETWEEN STATIONS",Vector2(30,30),Vector2(450,50),13,GOLD)
 label(p,"The train rolls on.",Vector2(30,100),Vector2(450,80),35,PAPER,true)
 var resume := button(p,"Resume flight",Vector2(30,209),Vector2(450,50),resume_game)
 button(p,"Settings",Vector2(30,275),Vector2(450,50),show_settings)
 button(p,"Flight & investigation guide",Vector2(30,341),Vector2(450,50),show_controls)
 button(p,"Return to a safe perch",Vector2(30,407),Vector2(450,50),func():
  fly.position = Vector3(-75,88,1225)
  fly.safe_position = fly.position
  fly.velocity = Vector3.ZERO
  fly.reset_movement()
  if opening_case_unstarted() and world.hotspots.has("cup"):
   first_look_origin = fly.global_position
   first_look_armed = true
   face_opening_objective()
  resume_game()
 )
 button(p,"Save & title",Vector2(30,473),Vector2(450,50),func(): save_game(); show_title())
 resume.grab_focus()

func show_controls() -> void:
 mode = "controls"
 overlay(0.9)
 var p := panel(modal,Vector2(230,150),Vector2(980,620))
 label(p,"A HOUSEFLY’S FIELD GUIDE",Vector2(35,30),Vector2(900,40),14,GOLD)
 label(p,"Think small. Look closely.",Vector2(35,95),Vector2(900,65),38,PAPER,true)
 label(p,"WASD: move relative to the camera’s horizontal direction\nMouse: look around · Scroll: adjust camera distance\nSpace / Ctrl: rise / descend · Shift: slow precision flight (hold by default; toggle in Settings)\nE: inspect / listen · L: land / take off\nLanded: tap Space to jump; double-tap Space to take off\nJ: notebook · Tab: deduction · Esc: pause\n\nFollow diamond markers; move close until the E prompt appears.\nInspection: hold right mouse and drag to orbit, scroll to zoom.\nThe fly is 6 mm long. You can land on tables, shelves, and floors.\nYou cannot carry human-sized objects or crawl on ceilings.\n\nProgress saves automatically. Pause offers a safe-perch recovery.",Vector2(35,190),Vector2(910,330),19,PAPER)
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
 var encounter_toggle := CheckBox.new()
 encounter_toggle.text = "Passing train"
 encounter_toggle.button_pressed = bool(options.passing_train)
 # Keep its whole hit area above the Shadows row, including theme margins.
 encounter_toggle.position = Vector2(35,354)
 encounter_toggle.tooltip_text = "Optional exterior motion. Requires Rain & atmosphere."
 p.add_child(encounter_toggle)
 encounter_toggle.toggled.connect(func(value: bool): options.passing_train=value; apply_settings())
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
 label(p,"Precision flight",Vector2(35,545),Vector2(300,30),18,PAPER)
 var precision_mode := OptionButton.new()
 precision_mode.add_item("Hold Shift")
 precision_mode.add_item("Press Shift to toggle")
 precision_mode.select(1 if options.precision_toggle else 0)
 precision_mode.position = Vector2(385,535)
 precision_mode.size = Vector2(325,46)
 p.add_child(precision_mode)
 precision_mode.item_selected.connect(func(index: int): options.precision_toggle=index==1; apply_settings())
 button(p,"Save & return",Vector2(35,588),Vector2(675,52),func():
  var cfg := ConfigFile.new()
  for key in options: cfg.set_value("game",key,options[key])
  cfg.save("user://settings.cfg")
  if hud.visible: show_pause()
  else: show_title()
 )

func apply_settings() -> void:
 world.set_atmosphere_enabled(bool(options.atmosphere))
 world.scenery.set_passing_train_enabled(bool(options.passing_train))
 fly.sensitivity = float(options.sensitivity)
 fly.set_precision_toggle(options.precision_toggle == true)
 Engine.max_fps = int(options.limit)
 var renderer := RenderingServer.get_current_rendering_method()
 for child: Light3D in world.find_children("*","Light3D",true,false):
  if child is DirectionalLight3D or child.get_meta("room_key",false):
   child.shadow_enabled = RoomShadowPolicy.allows(child,bool(options.shadows),renderer)
 apply_audio_mix()

func is_eavesdropping() -> bool:
 return mode=="inspection" and Data.TALKS.has(current_id)

func apply_audio_mix() -> void:
 if not is_instance_valid(ambience) and not is_instance_valid(wings): return
 var wings_context := 0.25 if fly.landed or fly.jumping or mode!="play" else 1.0
 var gains := listening_mix.gains(float(options.train),float(options.wings),wings_context)
 if is_instance_valid(ambience):
  var train_db := linear_to_db(maxf(0.0001,gains.x))
  if not is_equal_approx(ambience.volume_db,train_db): ambience.volume_db = train_db
 if is_instance_valid(wings):
  var wing_db := linear_to_db(maxf(0.0001,gains.y))
  if not is_equal_approx(wings.volume_db,wing_db): wings.volume_db = wing_db

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
 assert(mode=="title" and loading_card==null and is_processing())
 var original_world_id := world.get_instance_id()
 var puzzle_geometry_altered: bool = not world.cabinet_door.visible or not world.drawer.visible
 start_game(true)
 assert((world.get_instance_id()!=original_world_id) == puzzle_geometry_altered)
 assert(world.cabinet_door.visible and world.drawer.visible)
 assert(world.hotspots.size()==21)
 assert(investigation_lead() == "Vale is dead. Start with the cup beside him.")
 show_inspection("cup")
 assert(state.found.has("cup"))
 assert(investigation_lead() == "The pot is clean. Who handled Vale’s cup?")
 show_title()
 var prior_save := FileAccess.get_file_as_string(State.PATH)
 request_new_case()
 assert(mode == "new_case_confirm" and state.found.has("cup"))
 var cancel_new_case := InputEventKey.new()
 cancel_new_case.keycode = KEY_ESCAPE
 cancel_new_case.pressed = true
 _unhandled_input(cancel_new_case)
 assert(mode == "title" and FileAccess.get_file_as_string(State.PATH) == prior_save)
 start_game(false)
 assert(mode == "play" and fly.active)
 assert(investigation_lead() == "The pot is clean. Who handled Vale’s cup?")
 fly.position = world.hotspots.latch.position+Vector3(-24,14,0)
 release_latch()
 assert(not state.cabinet_open, "Being near the front of the cabinet cannot release the latch")
 fly.position = world.hotspots.latch.position+Vector3(0,0.4,0)
 assert(not fly.landed, "The release does not require landing")
 release_latch()
 assert(state.cabinet_open)
 show_inspection("chemical")
 assert(state.found.has("chemical"))
 for id in ["note","label","log","steward","botanist","engineer","pastry","photo","orchid","body"]:
  show_inspection(id)
  assert(is_eavesdropping()==Data.TALKS.has(id))
 assert(not attempt_dispatch([3,2,1]))
 assert(not state.dispatch_open)
 show_lock()
 var unlocked: bool = attempt_dispatch([1,2,3])
 assert(unlocked)
 show_inspection("ledger")
 assert(state.evidence_count()==6)
 show_notebook("cup")
 show_deduction()
 for id in ["cup","chemical","ledger","note"]: evidence_checks[id].button_pressed = true
 assert(suspect_select.selected == 0 and motive_select.selected == 0 and deduction_submit.disabled)
 submit_case()
 assert(not state.complete)
 suspect_select.select(1)
 suspect_select.item_selected.emit(1)
 assert(deduction_submit.disabled)
 submit_case()
 assert(not state.complete)
 motive_select.select(2)
 motive_select.item_selected.emit(2)
 assert(not deduction_submit.disabled)
 submit_case()
 assert(not state.complete)
 var journal_key := InputEventKey.new()
 journal_key.keycode = KEY_J
 journal_key.pressed = true
 _unhandled_input(journal_key)
 assert(mode == "notebook")
 show_notebook("cup")
 _unhandled_input(journal_key)
 assert(mode == "deduction" and suspect_select.selected == 1 and motive_select.selected == 2)
 assert(evidence_checks.cup.button_pressed and evidence_checks.chemical.button_pressed)
 assert(evidence_checks.ledger.button_pressed and evidence_checks.note.button_pressed and not evidence_checks.log.button_pressed)
 motive_select.select(1)
 motive_select.item_selected.emit(1)
 submit_case()
 assert(state.complete and state.dispatch_open and investigation_lead().is_empty())
 var restored = State.new()
 var loaded: bool = restored.load_from()
 assert(loaded)
 assert(restored.complete and restored.evidence_count()==6)
 var ledger_label: Label3D = world.dispatch_writing
 assert(is_instance_valid(ledger_label))
 for repeat in range(2):
  show_title()
  start_game(false)
  assert(state.complete and state.dispatch_open and not world.drawer.visible)
  assert(world.dispatch_writing==ledger_label and world.find_children("DispatchLedgerWriting","Label3D",false,false).size()==1)
 show_settings()
 show_pause()
 resume_game()
 clear_modal()
 ui.remove_child(modal)
 modal.queue_free()
 await get_tree().process_frame
 print("INTEGRATION PASS: 3 carriages, 21 hotspots, inspection, cabinet, notebook, deduction, ending, save/reload, settings")
 quit_game()

func sync_desktop_title() -> void:
 if OS.get_name() != "Windows" or FileAccess.file_exists("user://desktop-title-v2"): return
 var script := FileAccess.get_file_as_string("res://platform/rename_shortcut.ps1")
 if script.is_empty(): return
 var system_root := OS.get_environment("SystemRoot")
 if system_root.is_empty(): return
 var output: Array = []
 var code := OS.execute(system_root.path_join("System32/WindowsPowerShell/v1.0/powershell.exe"),["-NoProfile","-NonInteractive","-WindowStyle","Hidden","-Command",script],output,true,false)
 if code == 0:
  var marker := FileAccess.open("user://desktop-title-v2",FileAccess.WRITE)
  if marker: marker.store_string("Fly Spy With My Little Eye")
