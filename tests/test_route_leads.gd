extends SceneTree
## Exact game HUD and Notebook on the narrow virtual viewport.
## Synthetic case progression only; the original pack still runs the full case.
const Data=preload("res://scripts/case_data.gd")
const State=preload("res://scripts/case_state.gd")
const Plates=preload("res://scripts/door_purpose_plates.gd")
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
  ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
  canvas.add_child(ui)
  setup_hud()
  set_process(false)

var game:Fixture
var issues:Array[String]=[]
var verified:=0
func _initialize()->void:call_deferred("run")
func want(ok:bool,reason:String)->void:
 if not ok:issues.append(reason)
func label_for(text:String)->Label:
 for item in game.modal.find_children("*","Label",true,false):
  if item.text==text:return item
 return null
func fits(label:Label, maximum_height:int)->bool:
 var bounds:=label.get_global_rect()
 var line_height:=label.get_line_height(0)
 var stretch:=root.get_stretch_transform()
 var start:=stretch*bounds.position
 var end:=stretch*(bounds.position+Vector2(bounds.size.x,line_height))
 # Auto-wrapping Labels can keep a larger allocated but empty rectangle.
 # Verify the actual shaped glyph line, and its allotted top-down slot.
 return Rect2(Vector2.ZERO,Vector2(root.size)).encloses(Rect2(start,end-start)) and line_height<=maximum_height and label.get_line_count()==1 and label.get_visible_line_count()==1
func check_lead(revealed:Array,text:String)->void:
 game.state.found.assign(revealed)
 game.sync_evidence_hud()
 want(game.lead_label.text==text,"HUD lead mismatch "+str(revealed))
 game.show_notebook()
 await process_frame
 var note:=label_for(text)
 want(note!=null,"Notebook mismatch "+str(revealed))
 if note!=null:
  want(fits(note,26) and fits(game.lead_label,25),"Wrapped/clipped lead at "+str(root.size)+" "+str(revealed))
 want(not FileAccess.file_exists(State.PATH),"Reading the guidance wrote progress")
 verified+=1
func run()->void:
 if FileAccess.file_exists(State.PATH):quit(2);return
 game=Fixture.new()
 root.add_child(game)
 want(Plates.PURPOSE["0:-1:0"]=="WRITING BERTH" and Plates.PURPOSE["2:-1:2045"]=="HERITAGE ARCHIVE"
  and Plates.PURPOSE["1:1:1390"]=="STEWARD'S STORE","Expected physical case door signs changed")
 want(Plates.PURPOSE["0:1:0"]=="CREW BERTH" and Plates.PURPOSE["2:1:2045"]=="LIVE RESERVE",
  "Expected physical service door signs changed")
 for target in [Vector2i(960,540),Vector2i(1280,800)]:
  root.size=target
  await process_frame
  want(root.size==target,"Wrong actual viewport "+str(target))
  await check_lead([],"Vale is dead. Start with the cup beside him.")
  await check_lead(["cup"],"The pot is clean. Who handled Vale’s cup?")
  await check_lead(["cup","steward"],"Check the locked cabinet in the Steward’s Store (07).")
  await check_lead(["cup","chemical"],"Check the Writing Berth (06) and the Heritage Archive (08).")
  await check_lead(["cup","chemical","note"],"Check the Heritage Archive (08).")
  await check_lead(["cup","chemical","ledger"],"Check the Writing Berth (06).")
  await check_lead(["cup","chemical","note","ledger"],"Connect your clues in the notebook. Press Tab when you’re ready.")
 game.state.complete=true
 game.sync_evidence_hud()
 want(game.lead_label.text.is_empty() and game.investigation_lead().is_empty(),"Solved case re-arms the play guidance")
 want(Data.record("night_relay").place=="06 · Crew Berth" and Data.record("nursery_sensor").text.contains("Crew Berth (06)")
  and Data.record("nursery_sensor").place=="08 · Live Reserve" and Data.record("nursery_restored").place=="08 · Live Reserve",
  "Optional fixture records no longer agree with both physical doors")
 print("ROUTE_LEADS_DONE exact_hud_notebook_pairs=",verified," errors=",issues)
 game.queue_free()
 await process_frame
 quit(0 if issues.is_empty() and verified==14 else 1)
