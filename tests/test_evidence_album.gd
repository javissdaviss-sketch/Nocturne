extends SceneTree
const State = preload("res://scripts/case_state.gd")
const SYNTHETIC_SAVE := "user://test-evidence-album.json"
var failures: Array[String] = []

func check(condition: bool, message: String) -> void:
 if not condition: failures.append(message)

func write_old_save(altered: Dictionary = {}) -> void:
 var contents := {"version":1,"found":["cup"]}
 contents.merge(altered,true)
 var file := FileAccess.open(SYNTHETIC_SAVE,FileAccess.WRITE)
 file.store_string(JSON.stringify(contents))
 file.close()

func _initialize() -> void:
 var first := State.new()
 var second := State.new()
 var first_photo := first.evidence_photo_path("cup")
 var second_photo := second.evidence_photo_path("cup")
 check(first.photo_album.length() == 24 and second.photo_album.length() == 24,"New cases get real IDs")
 check(first_photo != second_photo and first_photo != "user://evidence/cup.png","First and new cases have isolated paths")
 var image := Image.create_empty(32,32,false,Image.FORMAT_RGBA8)
 image.fill(Color.AQUAMARINE)
 DirAccess.make_dir_recursive_absolute(first_photo.get_base_dir())
 check(image.save_png(first_photo) == OK,"Synthetic first photograph can be saved")
 check(not FileAccess.file_exists(second_photo),"A new case cannot see the first case photograph")
 first.discover("cup")
 check(first.save_to(SYNTHETIC_SAVE)==OK,"Save succeeds")
 var reopened := State.new()
 check(reopened.load_from(SYNTHETIC_SAVE),"Continued case loads")
 check(reopened.found.has("cup") and reopened.evidence_photo_path("cup") == first_photo,"Continue preserves evidence and album identity")
 check(FileAccess.file_exists(reopened.evidence_photo_path("cup")),"Continue still sees the earlier photograph")
 var restored := Image.load_from_file(reopened.evidence_photo_path("cup"))
 check(restored != null and not restored.is_empty(),"Continued album photograph decodes")
 write_old_save()
 var legacy := State.new()
 check(legacy.load_from(SYNTHETIC_SAVE) and legacy.evidence_photo_path("cup")=="user://evidence/cup.png","Legacy v1 save retains loose photographs")
 check(not FileAccess.file_exists(second_photo),"Legacy album does not leak into a new case")
 write_old_save({"photo_album":"../../../../../../nope!"})
 var malformed := State.new()
 check(malformed.load_from(SYNTHETIC_SAVE) and malformed.found.has("cup"),"Malformed album does not block loading legitimate case state")
 check(malformed.evidence_photo_path("cup") != first_photo and malformed.photo_album.length() == 24,"Malformed album neither escapes its folder nor reuses a previous album")
 if failures.is_empty(): print("PASS: case-scoped field photographs, Continue, legacy v1 photos, and malformed album")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
