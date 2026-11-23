extends SceneTree

const Identity := preload("res://scripts/room_identity.gd")
const Luxe := preload("res://scripts/cyber_luxe.gd")
class Fixture extends "res://scripts/world.gd":
 func _ready() -> void: pass

func _initialize() -> void: call_deferred("run")

func run() -> void:
 var stage := Fixture.new()
 root.add_child(stage)
 var styled := Luxe.new()
 stage.add_child(styled)
 styled.world = stage
 var issues: Array[String] = []
 for x in [-1,1]:
  stage.box(Vector3(x*282,144,0),Vector3(456,290,10),Color.WHITE,true)
  stage.box(Vector3(x*282.5,148,360),Vector3(455,296,5),Color.WHITE,true)
  stage.box(Vector3(x*282,144,840),Vector3(456,290,10),Color.WHITE,true)
  for room: Dictionary in [{"car":0,"side":x,"lo":0,"hi":360},{"car":1,"side":x,"lo":840,"hi":990}]:
   styled.transverse_panels(room)
 styled.finish_batches()
 stage.solid_geometry.build(styled)
 await physics_frame
 await physics_frame
 var space := stage.get_world_3d().direct_space_state
 for x in [-1,1]:
  for coordinates: Vector3 in [Vector3(25,-5,5.53),Vector3(336,367,356.25),Vector3(864,835,845.53)]:
   var a := Vector3(x*340,160,coordinates.x)
   var b := Vector3(x*340,160,coordinates.y)
   var h := space.intersect_ray(PhysicsRayQueryParameters3D.create(a,b))
   if h.is_empty() or absf(h.position.z-coordinates.z)>0.04:
    issues.append("room-facing liner remains behind the wall: "+str(coordinates)+" "+str(h))
  for z in [847.0,847.35,848.0,851.2]:
   for y in [5.0,13.0,78.0,92.0,120.0,160.0,211.0,219.0]:
    if not space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(x*47,y,z),Vector3(x*177,y,z))).is_empty():
     issues.append("reception clear edge unexpectedly blocked "+str(Vector3(x,y,z)))
 if issues.is_empty():
  print("PASS: actual liner surfaces are in front of structural shell and inner partitions on both sides; 64 reception test rays remain clear.")
 else:
  for issue in issues: push_error(issue)
 stage.queue_free()
 quit(0 if issues.is_empty() else 1)
