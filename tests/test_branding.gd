extends SceneTree
func _initialize() -> void:
 var title := str(ProjectSettings.get_setting("application/config/name"))
 var profile := OS.get_user_data_dir().replace("\\","/")
 if title != "Fly Spy With My Little Eye" or not profile.ends_with("/app_userdata/A Fly on the Night Train"):
  printerr("FAIL: title or existing save identity changed unexpectedly")
  quit(1)
  return
 print("PASS: Fly Spy With My Little Eye title retains the original save profile")
 quit()
