extends SceneTree
const Game = preload("res://scripts/game.gd")

func _initialize() -> void:
 var unopened := Game.new()
 var card := unopened.make_loading_card()
 assert(card.layer==3)
 var text_nodes := card.find_children("*","Label",true,false)
 var wording: Array[String] = []
 for item in text_nodes: wording.append(item.text)
 assert(wording.has("Preparing the train") and wording.has("The first load can take a moment."))
 assert(card.find_children("*","ProgressBar",true,false).is_empty())
 assert(not is_instance_valid(unopened.world),"The card does not construct the train")
 card.free()
 unopened.free()
 print("PASS: initial loading card needs no world, has honest copy, and has no false progress")
 quit()
