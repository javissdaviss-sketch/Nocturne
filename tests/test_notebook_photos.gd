extends SceneTree
const Game = preload("res://scripts/game.gd")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")

func check(value: bool, message: String) -> void:
 if not value: failures.append(message)

func find_text(panel: Control, type: String, words: String) -> Node:
 for node in panel.find_children("*",type,true,false):
  if node.text.contains(words): return node
 return null

func run() -> void:
 # Exercise the actual notebook without invoking the heavyweight Game._ready.
 var game := Game.new()
 game.ui = Control.new()
 root.add_child(game.ui)
 game.marker_layer = Control.new()
 game.ui.add_child(game.marker_layer)
 game.fly = Game.Fly.new()
 game.state.discover("cup")
 game.show_notebook("cup")
 check(find_text(game.modal,"Button","View field photograph")==null,"Missing photograph is not a dead button")
 check(find_text(game.modal,"Label","No photograph yet")!=null,"Missing-photo guidance is visible in notebook, not offscreen")
 var path: String = game.state.evidence_photo_path("cup")
 DirAccess.make_dir_recursive_absolute(path.get_base_dir())
 var synthetic := Image.create_empty(32,32,false,Image.FORMAT_RGBA8)
 synthetic.fill(Color.REBECCA_PURPLE)
 check(synthetic.save_png(path)==OK,"Synthetic photo write")
 game.show_notebook("cup")
 var view_button: Node = find_text(game.modal,"Button","View field photograph")
 check(view_button!=null,"A readable photograph is available in the actual notebook")
 if view_button!=null:
  view_button.pressed.emit()
  check(game.mode=="photo" and game.photo_entry=="cup","Button opens the correct photograph")
  var back: Node = find_text(game.modal,"Button","Back to notes")
  if back!=null: back.pressed.emit()
  check(game.mode=="notebook" and find_text(game.modal,"Button","View field photograph")!=null,"Back returns to the same evidence entry")
 game.thumbnails.clear()
 var invalid := FileAccess.open(path,FileAccess.WRITE)
 invalid.store_string("deliberately malformed synthetic photo")
 invalid.close()
 game.show_photo("cup")
 game.show_photo("cup")
 check(game.mode=="notebook" and game.modal.get_node_or_null("PhotoStatus")!=null,"Malformed photograph leaves notebook usable with a visible recovery line")
 var symptoms := 0
 for label in game.modal.find_children("*","Label",true,false):
  if label.name=="PhotoStatus": symptoms+=1
 check(symptoms==1,"Repeated clicks do not stack recovery labels")
 game.fly.free()
 game.ui.free()
 game.free()
 await process_frame
 if failures.is_empty(): print("PASS: notebook missing-photo guidance, reopen and Back, and damaged photo recovery")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
