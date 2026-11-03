extends RefCounted
const Data = preload("res://scripts/case_data.gd")
const PATH = "user://case.json"
var found: Array = []
var cabinet_open := false
var dispatch_open := false
var complete := false
var saved_position: Array = [-75.0,88.0,1225.0]

func discover(id: String) -> bool:
 if Data.record(id).is_empty() or found.has(id): return false
 found.append(id)
 return true

func evidence_count() -> int:
 var count := 0
 for id in Data.ESSENTIAL:
  if found.has(id): count += 1
 return count

func save_to(path: String = PATH) -> Error:
 var f := FileAccess.open(path+".tmp",FileAccess.WRITE)
 if f == null: return FileAccess.get_open_error()
 f.store_string(JSON.stringify({"version":1,"found":found,"cabinet":cabinet_open,"dispatch":dispatch_open,"complete":complete,"position":saved_position}))
 f.close()
 return DirAccess.rename_absolute(path+".tmp",path)

func load_from(path: String = PATH) -> bool:
 if not FileAccess.file_exists(path): return false
 var parser := JSON.new()
 if parser.parse(FileAccess.get_file_as_string(path)) != OK: return false
 var parsed: Variant = parser.data
 if not parsed is Dictionary or parsed.get("version",0) != 1: return false
 found.clear()
 var entries: Variant = parsed.get("found",[])
 if entries is Array:
  for id in entries:
   if id is String and not Data.record(id).is_empty() and not found.has(id): found.append(id)
 cabinet_open = parsed.get("cabinet",false) == true
 dispatch_open = parsed.get("dispatch",false) == true
 complete = parsed.get("complete",false) == true
 var p: Variant = parsed.get("position",[])
 if p is Array and p.size()==3:
  if (p[0] is float or p[0] is int) and (p[1] is float or p[1] is int) and (p[2] is float or p[2] is int):
   if abs(p[0])<170 and p[1]>1 and p[1]<285 and p[2]>0 and p[2]<2480: saved_position = p
 # Locked clues may never leak from an inconsistent save.
 if not cabinet_open: found.erase("chemical")
 if not dispatch_open: found.erase("ledger")
 return true
