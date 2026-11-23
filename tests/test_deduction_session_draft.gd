extends SceneTree
const Saved=preload("res://scripts/case_state.gd")
var game:Node
var errors:Array[String]=[]
func _initialize()->void:call_deferred("run")
func check(ok:bool,detail:String)->void:
 if not ok:errors.append(detail)
func key(name:Key)->void:
 var event:=InputEventKey.new()
 event.keycode=name
 event.physical_keycode=name
 event.pressed=true
 game._unhandled_input(event)
func find_button(mark:String)->Button:
 for n:Button in game.modal.find_children("*","Button",true,false):
  if n.text==mark:return n
 return null
func run()->void:
 if FileAccess.file_exists(Saved.PATH):
  push_error("Deduction test must use a new synthetic profile.")
  quit(2);return
 game=load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 if game.mode=="loading":await game.investigation_ready
 game.start_game(true)
 await physics_frame
 await process_frame
 var saved_before:=FileAccess.get_file_as_bytes(Saved.PATH)
 key(KEY_TAB)
 check(game.mode=="deduction" and game.evidence_checks.is_empty(),"Undiscovered clues must not appear as choices")
 check(game.deduction_submit.disabled,"Initial choices must never preselect a verdict")
 game.suspect_select.select(2)
 game.motive_select.select(3)
 game.update_deduction_choices(0)
 game.submit_case()
 check(not game.state.complete and game.ending_text.text.contains("physical evidence you’ve found"),"Early guess received unclear evidence feedback")
 key(KEY_TAB)
 check(game.mode=="play","Tab should return to existing flight")
 game.state.discover("cup")
 game.state.discover("log")
 key(KEY_TAB)
 check(game.suspect_select.selected==2 and game.motive_select.selected==3 and game.evidence_checks.size()==2,"A draft did not resume across flight or displayed other clues")
 if game.evidence_checks.has("cup"):game.evidence_checks.cup.button_pressed=true
 var leave:=find_button("Keep investigating")
 if is_instance_valid(leave):leave.pressed.emit()
 else:check(false,"Actual Keep investigating button missing")
 check(game.mode=="play","Button should return to flight")
 key(KEY_J)
 check(game.mode=="notebook" and game.deduction_review.is_empty(),"A normal flight notebook should not accidentally become review")
 key(KEY_J)
 check(game.mode=="play","Ordinary notebook close should return to flight")
 key(KEY_TAB)
 check(game.mode=="deduction" and game.evidence_checks.cup.button_pressed,"Ordinary notebook outing did not preserve case theory")
 game.submit_case()
 var neutral:String=game.ending_text.text
 check(not game.state.complete and neutral.contains("isn’t supported") and
  not neutral.to_lower().contains("ledger") and not neutral.to_lower().contains("ultimatum") and
  not neutral.contains("Mara") and not neutral.contains("Ivo") and not neutral.contains("Lian"),
  "Wrong submission named undiscovered objects or suspects")
 key(KEY_J)
 check(game.mode=="notebook" and not game.deduction_review.is_empty(),"Deduction J must keep its review return")
 game.add_trace_to_draft("log")
 game.add_trace_to_draft("ledger")
 key(KEY_J)
 check(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==3 and
  game.evidence_checks.cup.button_pressed and game.evidence_checks.log.button_pressed and not game.evidence_checks.has("ledger"),
  "Review must add only actual found evidence and return to the current opt-in draft")
 key(KEY_ESCAPE)
 key(KEY_TAB)
 check(game.mode=="deduction" and game.evidence_checks.log.button_pressed,"Escape/Tab round-trip lost a reviewed finding")
 check(FileAccess.get_file_as_bytes(Saved.PATH)==saved_before,"Navigation or a failed deduction overwrote the file")
 for id in ["chemical","ledger","note"]:game.state.discover(id)
 key(KEY_TAB)
 key(KEY_TAB)
 game.suspect_select.select(1)
 game.motive_select.select(1)
 for id in ["cup","chemical","ledger","note"]:game.evidence_checks[id].button_pressed=true
 game.submit_case()
 check(game.mode=="ending" and game.state.complete,"The original proved verdict cannot close the actual case")
 var saved_after:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(Saved.PATH))
 check(saved_after.get("complete",false)==true and not saved_after.has("deduction_draft") and not saved_after.has("deduction_review"),"Draft was persisted or genuine verdict was not saved")
 game.show_title()
 game.start_game(true)
 key(KEY_TAB)
 check(game.deduction_draft.is_empty() and game.deduction_review.is_empty() and game.evidence_checks.is_empty() and game.deduction_submit.disabled,"Intentional new case retained a prior session’s deduction")
 print("Deduction flight/UI session issues=",errors)
 game.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 1)
