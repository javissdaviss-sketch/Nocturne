extends SceneTree
const Game = preload("res://scripts/game.gd")
const Guide = preload("res://scripts/carriage_guide.gd")

class LayoutFixture extends Node3D:
 var rooms: Array = []

var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(ok: bool, why: String) -> void:
 if not ok: failures.append(why)
func select_node(parent: Control, type: String, words: String) -> Node:
 for node in parent.find_children("*",type,true,false):
  if node.text.contains(words): return node
 return null

func run() -> void:
 var layout := LayoutFixture.new()
 layout.name = "CompartmentLayout"
 var limits := [[0.0,360.0,800.0],[840.0,990.0,1390.0,1640.0],[1680.0,2045.0,2480.0]]
 for car in range(3):
  for s in [-1,1]:
   var side := 0 if s==-1 else 1
   for i in range(limits[car].size()-1):
    var width := 84.0 if (car==0 and s==1 and i==0) or (car==1 and i==0) or (car==1 and s==1 and i==2) else 92.0
    var r := {"car":car,"side":s,"lo":limits[car][i],"hi":limits[car][i+1],"entry":Guide.Layout.ENTRIES[car][side][i],"width":width}
    layout.rooms.append(r)
    var walls := Guide.solid_runs(r)
    check(is_equal_approx(walls[1].x-walls[0].y,width),"The mapped aperture preserves actual width")
    var pin := (car+1)%3
    var from := Vector3(s*115,92,r.entry)
    var exit := Guide.guidance(from,0,pin,layout.rooms)
    check(exit.kind=="door" and exit.door==Vector3(s*55,92,r.entry),"Correct room exit on each side, never a cross-wall shortcut")
    check(Guide.guidance(Vector3(s*51,92,r.entry),0,pin,layout.rooms).kind!="door","The instruction switches at the actual corridor")
 check(layout.rooms.size()==14,"All fourteen doorways are represented")
 var middle := Vector3(0,110,1234)
 check(Guide.guidance(middle,PI,2,layout.rooms).kind=="ahead","Positive Z is ahead at yaw PI")
 check(Guide.guidance(middle,0,2,layout.rooms).kind=="behind","Positive Z is behind at yaw zero")
 check(Guide.guidance(middle,PI/2,2,layout.rooms).kind=="left","Positive Z is to the left at yaw PI/2")
 check(Guide.guidance(middle,-PI/2,2,layout.rooms).kind=="right","Positive Z is to the right at yaw -PI/2")
 check(Guide.guidance(middle,0,0,layout.rooms).kind=="ahead","Negative Z is ahead at yaw zero")
 check(Guide.guidance(middle,0,1,layout.rooms).kind=="arrived","Pin reports arrival in the destination")
 check(Guide.guidance(middle,0,-1,layout.rooms).is_empty(),"No guide or cue until the player chooses it")
 var bounds := Rect2(0,0,800,205)
 check(Guide.map_point(Vector3(-510,0,0),bounds).is_zero_approx(),"Map origin uses negative X and zero Z")
 check(Guide.map_point(Vector3(510,0,2480),bounds).is_equal_approx(bounds.size),"Map end matches the final carriage")

 # Drive real notebook and button handlers without booting the world asset tree.
 var game := Game.new()
 game.ui = Control.new()
 root.add_child(game.ui)
 game.marker_layer = Control.new()
 game.ui.add_child(game.marker_layer)
 game.carriage_pin_label = Label.new()
 game.ui.add_child(game.carriage_pin_label)
 game.world = Node3D.new()
 game.world.add_child(layout)
 game.fly = Game.Fly.new()
 game.fly.position = middle
 game.state.discover("cup")
 game.show_notebook()
 check(select_node(game.modal,"Label","symbol lock")==null and select_node(game.modal,"Label","cable opening")==null,"Opening notebook does not spoil clue routes")
 var open_guide := select_node(game.modal,"Button","Open the carriage guide")
 if open_guide!=null: open_guide.pressed.emit()
 check(select_node(game.modal,"Label","You’re here: 07")!=null,"Actual notebook reads current carriage")
 var target := select_node(game.modal,"Button","08 · Winter garden")
 if target!=null: target.pressed.emit()
 check(game.carriage_pin==2 and game.state.found==["cup"],"Pin updates UI, not evidence")
 game.mode = "play"
 game.update_carriage_cue()
 check(game.carriage_pin_label.visible and game.carriage_pin_label.text.begins_with("08"),"Opt-in cue displays in flight")
 game.show_notebook("guide")
 var clear_pin := select_node(game.modal,"Button","Clear pin")
 if clear_pin!=null: clear_pin.pressed.emit()
 game.mode = "play"
 game.update_carriage_cue()
 check(game.carriage_pin==-1 and not game.carriage_pin_label.visible,"Clear removes the in-flight cue")
 game.show_deduction()
 game.suspect_select.select(2)
 game.motive_select.select(2)
 game.evidence_checks.cup.button_pressed = true
 game.review_deduction_evidence()
 game.show_notebook("guide")
 game.close_notebook()
 check(game.mode=="deduction" and game.suspect_select.selected==2 and game.motive_select.selected==2 and game.evidence_checks.cup.button_pressed,"Visiting the guide preserves the unsent deduction")
 game.fly.free()
 game.world.free()
 game.ui.free()
 game.free()
 await process_frame
 if failures.is_empty(): print("PASS: all 14 mapped apertures, yaw, pin/no pin, notebook and unsent deduction")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
