extends SceneTree
const Game = preload("res://scripts/game.gd")
const Data = preload("res://scripts/case_data.gd")
const State = preload("res://scripts/case_state.gd")

class LockedFurniture extends Node3D:
 var cabinet_door := MeshInstance3D.new()
 var drawer := MeshInstance3D.new()

var errors: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
 if not ok: errors.append(text)
func words(modal: Node) -> String:
 var text := ""
 for label in modal.find_children("*","Label",true,false):
  text += label.text+" | "
 return text

func run() -> void:
 var game := Game.new()
 game.ui = Control.new()
 root.add_child(game.ui)
 game.marker_layer = Control.new()
 game.ui.add_child(game.marker_layer)
 var walls := LockedFurniture.new()
 walls.add_child(walls.cabinet_door)
 walls.add_child(walls.drawer)
 game.world = walls
 game.fly = Game.Fly.new()
 game.state.save_to()
 var before := FileAccess.get_file_as_bytes(State.PATH)
 game.show_notebook("trace")
 check(game.trace_selectors[0].item_count==1 and game.trace_selectors[0].disabled,"No findings or locked labels before physical discovery")
 check(not words(game.modal).contains("bitter little bottle"),"The blank board does not reveal a locked clue")
 check(not game.select_trace(0,"unknown") and not game.select_trace(-1,"cup") and not game.select_trace(1,"cup"),"Reject unknown or unobserved data")
 game.state.discover("cup")
 check(game.select_trace(0,"cup") and not game.select_trace(1,"cup"),"Only one slot can hold the same observed object")
 game.state.discover("chemical")
 game.state.discover("ledger")
 game.state.cabinet_open = true
 game.state.dispatch_open = true
 check(game.trace_choices_available()==["cup"],"Artificial flags and found IDs cannot outrun actual closed furniture")
 walls.cabinet_door.visible = false
 walls.drawer.visible = false
 for id in ["note","label","log"]: game.state.discover(id)
 var available := game.trace_choices_available()
 check(available.size()==6,"Every legitimately found proof and context object is equally available")
 for left in available:
  for right in available:
   game.select_trace(0,"")
   game.select_trace(1,"")
   check(game.select_trace(0,left),"Recognised left slot is available")
   check(game.select_trace(1,right)==(left!=right),"All distinct comparisons, no expected/matching answer list")
 game.select_trace(0,"")
 game.select_trace(1,"")
 game.select_trace(0,"cup")
 game.select_trace(1,"note")
 game.show_notebook("trace")
 var both := words(game.modal)
 check(both.contains("Angular violet flakes") and both.contains("Return the cuttings"),"Both authored observations appear side by side")
 check(not both.contains("Correct") and not both.contains("Proof of") and not both.contains("Case closed"),"The board never grades a choice")
 var bad_photo: String = game.state.evidence_photo_path("cup")
 var good_photo: String = game.state.evidence_photo_path("note")
 DirAccess.make_dir_recursive_absolute(bad_photo.get_base_dir())
 var invalid := FileAccess.open(bad_photo,FileAccess.WRITE)
 invalid.store_string("Fixture only: intentionally not PNG")
 invalid.close()
 var image := Image.create_empty(32,32,false,Image.FORMAT_RGBA8)
 image.fill(Color.MEDIUM_PURPLE)
 check(image.save_png(good_photo)==OK,"Synthetic comparison photo exists")
 game.show_notebook("trace")
 game.show_photo("cup",true)
 check(game.mode=="notebook" and game.modal.get_node_or_null("PhotoStatus_cup")!=null,"Corrupt photo does not remove the physical-observation fallback")
 game.show_photo("note",true)
 check(game.mode=="photo","One corrupt photo cannot prevent the other slot's valid old photo")
 game.close_photo()
 check(game.mode=="notebook" and game.notebook_page=="trace" and game.trace_choices==["cup","note"],"Returning from photo restores both selected findings")
 game.show_deduction()
 game.suspect_select.select(2)
 game.motive_select.select(3)
 game.evidence_checks.cup.button_pressed=true
 game.review_deduction_evidence()
 game.show_notebook("trace")
 game.add_trace_to_draft("log")
 game.add_trace_to_draft("log")
 check(game.deduction_review.evidence.count("log")==1 and game.trace_choices==["cup","note"],"Draft action is optional and de-duplicates without touching the comparison")
 game.close_notebook()
 check(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==3 and game.evidence_checks.cup.button_pressed and game.evidence_checks.log.button_pressed,"Detour preserves all original draft choices and adds only the selected item")
 check(not game.state.complete and Data.solved(0,0,["cup","chemical","ledger","note"]) and not Data.solved(0,0,["cup","chemical","label","log"]),"Original solver unchanged and no forced verdict")
 check(FileAccess.get_file_as_bytes(State.PATH)==before,"Board views, photo reads and draft-only edits never write the case")
 game.fly.free()
 game.ui.free()
 walls.free()
 game.free()
 await process_frame
 if errors.is_empty(): print("PASS: all discovered pair permutations, locked record guards, observed fallback/photo return, and unsent draft; no case writes")
 else: printerr(errors)
 quit(0 if errors.is_empty() else 1)
