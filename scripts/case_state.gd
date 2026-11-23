extends RefCounted
const Data = preload("res://scripts/case_data.gd")
const PATH = "user://case.json"
var found: Array = []
var cabinet_open := false
var dispatch_open := false
var complete := false
var nursery_diagnosed := false
var nursery_restored := false
var saved_position: Array = [-75.0,88.0,1225.0]
# Optional in existing version-1 files. The flight controller keeps its
# current physical position, momentum reset and legacy orientation defaults.
var saved_view: Array = []
var photo_album := Crypto.new().generate_random_bytes(12).hex_encode()

func evidence_photo_path(id: String) -> String:
 # Case-specific albums keep photos from previous investigations out of new
 # ones. Older v1 saves continue to use their existing loose photos.
 var folder := "user://evidence"
 if not photo_album.is_empty(): folder += "/" + photo_album
 return folder + "/" + id + ".png"

func recover_photo_album(value: Variant) -> void:
 if not value is String: return
 if value.is_empty():
  photo_album = ""
  return
 if value.length() != 24: return
 for symbol in value:
  if not symbol in "0123456789abcdef": return
 photo_album = value

func discover(id: String) -> bool:
 if Data.record(id).is_empty() or found.has(id): return false
 found.append(id)
 return true

func evidence_count() -> int:
 var count := 0
 for id in Data.ESSENTIAL:
  if found.has(id): count += 1
 return count

func remember_view(yaw: float, pitch: float) -> void:
 saved_view.clear()
 if is_finite(yaw) and is_finite(pitch):
  saved_view = [wrapf(yaw,-PI,PI),clampf(pitch,-1.25,1.25)]

func save_to(path: String = PATH) -> Error:
 var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f == null: return FileAccess.get_open_error()
 var snapshot := {"version":1,"found":found,"cabinet":cabinet_open,"dispatch":dispatch_open,"complete":complete,"nursery_diagnosed":nursery_diagnosed,"nursery_restored":nursery_restored,"position":saved_position,"photo_album":photo_album}
 if not saved_view.is_empty(): snapshot["view"] = saved_view
 f.store_string(JSON.stringify(snapshot))
 f.close()
 return DirAccess.rename_absolute(path+".tmp",path)

func load_from(path: String = PATH) -> bool:
 if not FileAccess.file_exists(path): return false
 var parser := JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path)) != OK: return false
 var parsed: Variant = parser.data
 if not parsed is Dictionary or parsed.get("version",0) != 1: return false
 recover_photo_album(parsed.get("photo_album",""))
 saved_view.clear()
 var view: Variant = parsed.get("view",[])
 if view is Array and view.size()==2:
  if (view[0] is float or view[0] is int) and (view[1] is float or view[1] is int):
   var yaw := float(view[0])
   var pitch := float(view[1])
   if is_finite(yaw) and is_finite(pitch) and absf(yaw)<=PI+0.0001 and absf(pitch)<=1.25:
    remember_view(yaw,pitch)
 found.clear()
 var entries: Variant = parsed.get("found",[])
 if entries is Array:
  for id in entries:
   if id is String and not Data.record(id).is_empty() and not found.has(id): found.append(id)
 cabinet_open = parsed.get("cabinet",false) == true
 dispatch_open = parsed.get("dispatch",false) == true
 complete = parsed.get("complete",false) == true
 nursery_diagnosed = parsed.get("nursery_diagnosed",false) == true
 nursery_restored = nursery_diagnosed and parsed.get("nursery_restored",false) == true
 if nursery_restored: discover("nursery_restored")
 else: found.erase("nursery_restored")
 var p: Variant = parsed.get("position",[])
 if p is Array and p.size()==3:
  if (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int) and (p[2] is float or p[2] is int):
   if abs(p[0])<510 and p[1]>1 and p[1]<285 and p[2]>0 and p[2]<2480: saved_position = p
 # Locked clues may never leak from an inconsistent save.
 if not cabinet_open: found.erase("chemical")
 if not dispatch_open: found.erase("ledger")
 return true
