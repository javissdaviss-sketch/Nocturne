extends RefCounted
## Read-only navigation through physical doorways, not an evidence hint system.
const Layout = preload("res://scripts/train_layout.gd")
const DoorSigns = preload("res://scripts/door_purpose_plates.gd")
const NUMBERS := ["06","07","08"]
const NAMES := ["Residences","Dining lounge","Winter garden"]
const CAR_STRIDE := 840.0
const TRAIN_END := 2480.0
const HALL_EDGE := Layout.CORRIDOR_EDGE
const WALL_THICKNESS := 5.0

static func carriage(position: Vector3) -> int:
 return clampi(floori(position.z/CAR_STRIDE),0,2)

static func valid_pin(pin: int) -> bool:
 return pin >= 0 and pin < NUMBERS.size()

static func map_point(position: Vector3, bounds: Rect2) -> Vector2:
 return bounds.position+Vector2(
  clampf(position.z/TRAIN_END,0.0,1.0)*bounds.size.x,
  clampf((position.x+Layout.HALF_WIDTH)/(2.0*Layout.HALF_WIDTH),0.0,1.0)*bounds.size.y)

static func room_at(position: Vector3, rooms: Array) -> Dictionary:
 if absf(position.x) < HALL_EDGE+WALL_THICKNESS*0.5: return {}
 var side := int(signf(position.x))
 for room in rooms:
  if int(room.side)==side and position.z>=float(room.lo) and position.z<=float(room.hi):
   return room
 return {}

static func room_name(room: Dictionary) -> String:
 if room.is_empty(): return ""
 return DoorSigns.PURPOSE.get(DoorSigns.key(int(room.car),int(room.side),float(room.lo)),"")

static func location_detail(position: Vector3, yaw: float, pitch: float, rooms: Array, space: PhysicsDirectSpaceState3D = null) -> Dictionary:
 # This readout only describes a physical room or a presently faced aperture.
 # It never searches for evidence, and ordinary flight uses no such query.
 if absf(position.x)>=Layout.HALF_WIDTH or position.y<=0.0 or position.y>=294.0:
  return {}
 var region:=room_at(position,rooms)
 if not region.is_empty() and position.z>float(region.lo)+2.5 and position.z<float(region.hi)-2.5:
  return {"kind":"room","name":room_name(region)}
 if absf(position.x)>=HALL_EDGE-WALL_THICKNESS*0.5 or not is_instance_valid(space):
  return {}
 var aim:=Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
 if absf(aim.x)<0.72: return {}
 var side:=signf(aim.x)
 # Check both faces of the real doorway trim; an oblique ray can cross the
 # open centerline but still point into the far jamb or over the lintel.
 var inner:=position+aim*((side*(HALL_EDGE-4.5)-position.x)/aim.x)
 var outer:=position+aim*((side*(HALL_EDGE+4.5)-position.x)/aim.x)
 if inner.y<2.0 or outer.y<2.0 or inner.y>220.0 or outer.y>220.0: return {}
 for room in rooms:
  if room.side!=int(side) or room.car!=carriage(position): continue
  var half:=float(room.width)*0.5-2.0
  if absf(inner.z-float(room.entry))>=half or absf(outer.z-float(room.entry))>=half: continue
  var probe:=PhysicsRayQueryParameters3D.create(position,outer,1)
  probe.hit_from_inside=true
  if not space.intersect_ray(probe).is_empty(): return {}
  return {"kind":"door","name":room_name(room)}
 return {}

static func solid_runs(room: Dictionary) -> Array[Vector2]:
 var entry := float(room.entry)
 var half := float(room.width)*0.5
 return [Vector2(float(room.lo),entry-half),Vector2(entry+half,float(room.hi))]

static func guidance(position: Vector3, yaw: float, pin: int, rooms: Array) -> Dictionary:
 if not valid_pin(pin): return {}
 var present := carriage(position)
 var caption: String = NUMBERS[pin] + " · "
 if present == pin: return {"kind":"arrived","text":caption+"You’re in this carriage"}
 var room := room_at(position,rooms)
 if not room.is_empty():
  var door := Vector3(float(room.side)*HALL_EDGE,position.y,float(room.entry))
  return {"kind":"door","door":door,"text":caption+"Use this room’s doorway to the corridor"}
 if absf(position.x) > HALL_EDGE+WALL_THICKNESS*0.5:
  return {"kind":"hall","text":caption+"Return to the central corridor"}
 # Godot local forward is -Z. Map directions are train-relative; the cue speaks
 # player-relative directions and ignores vertical camera pitch.
 var corridor_direction := Vector2(0.0,1.0 if pin>present else -1.0)
 var heading := Vector2(-sin(yaw),-cos(yaw))
 var right := Vector2(-heading.y,heading.x)
 var along := heading.dot(corridor_direction)
 if along >= 0.62: return {"kind":"ahead","text":caption+"Follow the corridor ahead"}
 if along <= -0.62: return {"kind":"behind","text":caption+"Turn around, then follow the corridor"}
 if right.dot(corridor_direction)>0.0: return {"kind":"right","text":caption+"Turn right to follow the corridor"}
 return {"kind":"left","text":caption+"Turn left to follow the corridor"}
