extends Node3D
## Drawn mouldings use the same actual surfaces for contact. Bevels remain
## within each original structural footprint; old broad backings stay solid.
const Veneer = preload("res://scripts/fitted_veneer.gd")
const Finishes = preload("res://scripts/material_library.gd")
const WALNUT := Color("514236")
const BRASS := Color("9e825e")
var banks: Dictionary = {}
var anchors: Array[Dictionary] = []
var collision_count := 0
var triangles := 0

func bank(kind: String) -> SurfaceTool:
 if not banks.has(kind):
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  banks[kind] = surface
 return banks[kind]

func keep_contact(center: Vector3,size: Vector3) -> void:
 var body := StaticBody3D.new()
 body.position = center
 add_child(body)
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collision.shape = shape
 body.add_child(collision)
 collision_count += 1

func contour(y: float,z: float,h: float,w: float,r: float) -> PackedVector2Array:
 var points := PackedVector2Array()
 r = clampf(r,0.12,minf(h,w)*0.22)
 for corner in range(4):
  var sy := 1.0 if corner in [0,1] else -1.0
  var sz := 1.0 if corner in [0,3] else -1.0
  var hub := Vector2(y+sy*(h*0.5-r),z+sz*(w*0.5-r))
  for step in range(4):
   var phase := float(corner)*PI/2+float(step)*PI/6
   points.append(hub+Vector2(sin(phase),cos(phase))*r)
 return points

func emit_quad(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,d: Vector3,wanted: Vector3) -> void:
 var normal := (b-a).cross(c-a).normalized()
 if normal.is_zero_approx(): normal = (c-a).cross(d-a).normalized()
 if normal.is_zero_approx(): return
 var clockwise := normal.dot(wanted)>0
 if not clockwise: normal = -normal
 var order := [a,c,b,a,d,c] if clockwise else [a,b,c,a,c,d]
 for point in order:
  surface.set_normal(normal)
  surface.add_vertex(point)
 triangles += 2

func rectangle_moulding(side: int,y: float,z: float,height: float,width: float,radius: float,profile: Array,role: String, prefix: String = "") -> void:
 var previous := PackedVector2Array()
 var previous_x := 0.0
 var front := Vector3(-side,0,0)
 for i in range(profile.size()):
  var step: Array = profile[i]
  var inset: float = step[0]
  var x: float = float(step[1])*side
  var border := contour(y,z,height-2*inset,width-2*inset,maxf(0.18,radius-inset*0.55))
  if not previous.is_empty():
   var surface := bank(prefix+str(step[2]))
   for j in range(border.size()):
    var k := (j+1)%border.size()
    emit_quad(surface,Vector3(previous_x,previous[j].x,previous[j].y),Vector3(previous_x,previous[k].x,previous[k].y),Vector3(x,border[k].x,border[k].y),Vector3(x,border[j].x,border[j].y),front)
  previous = border
  previous_x = x
 anchors.append({"role":role,"side":side,"y":y,"z":z,"height":height,"width":width})

func backing(side: int, x: float, z: float, length: float, car: int = 1) -> void:
 # This is the full lower wall run, not another strip. Close off and replace
 # the formerly flat orange-brown face; the primary partition stays behind it.
 assert(is_equal_approx(x,float(side)*52.0))
 var face := side*51.55
 var depth := side*52.4
 var to_player := Vector3(-side,0,0)
 var prefix := coach_bank(car)
 var b := bank(prefix+"backing")
 var c0 := z-length*0.5
 var c1 := z+length*0.5
 emit_quad(b,Vector3(face,1,c0),Vector3(face,1,c1),Vector3(face,89,c1),Vector3(face,89,c0),to_player)
 for ends in [Vector2(c0,-1),Vector2(c1,1)]:
  emit_quad(b,Vector3(face,1,ends.x),Vector3(depth,1,ends.x),Vector3(depth,89,ends.x),Vector3(face,89,ends.x),Vector3(0,0,ends.y))
 for h in [1,89]:
  emit_quad(b,Vector3(face,h,c0),Vector3(depth,h,c0),Vector3(depth,h,c1),Vector3(face,h,c1),Vector3(0,-1 if h==1 else 1,0))

func dado(side: int,x: float,y: float,z: float,width: float, car: int = 1) -> void:
 assert(is_equal_approx(x,float(side)*52.0))
 # Low coach panels share a carriage-building language, not one repeated
 # moulding profile: berth routes are restrained and warm, garden is a
 # narrow rolled frame. All remain inside the existing aisle pilasters.
 var prefix := coach_bank(car)
 var h := 68.4 if car==1 else (63.0 if car==0 else 66.0)
 var w := width+1.6 if car!=2 else width+1.0
 var lip := 5.30 if car==1 else (4.1 if car==0 else 4.4)
 var pupil := 50.93 if car!=2 else 51.22
 var cross := [
  [0.0,51.50,"timber"],[0.90,51.09,"timber"],[1.70,49.81,"timber"],[2.50,49.57,"timber"],
  [2.95,49.65,"brass"],[3.32,49.92,"brass"],[3.82,50.10,"timber"],[4.55,50.72,"field"],[5.30,50.93,"field"]
 ]
 if car==0:
  cross = [[0.0,51.51,"timber"],[0.72,50.61,"timber"],[1.52,50.12,"timber"],
   [2.12,50.10,"brass"],[2.47,50.36,"brass"],[2.94,50.55,"timber"],[3.52,50.72,"field"],[lip,pupil,"field"]]
 elif car==2:
  cross = [[0.0,51.52,"timber"],[0.62,50.87,"timber"],[1.16,50.53,"brass"],[1.75,50.48,"brass"],
   [2.52,50.53,"timber"],[3.42,50.89,"field"],[lip,pupil,"field"]]
 var role := "dado" if car==1 else prefix+"dado"
 rectangle_moulding(side,y,z,h,w,3.3 if car==1 else (2.2 if car==0 else 4.8),cross,role,prefix)
 var border := contour(y,z,h-2*lip,w-2*lip,0.44)
 var plane := pupil*side
 var center := Vector3(plane,y,z)
 var panel := bank(prefix+"field")
 for i in range(border.size()):
  var j := (i+1)%border.size()
  emit_tri(panel,center,Vector3(plane,border[i].x,border[i].y),Vector3(plane,border[j].x,border[j].y),Vector3(-side,0,0))

func coach_bank(car: int) -> String:
 return "Sleeper:" if car==0 else ("Garden:" if car==2 else "")

func bank_finish(kind: String) -> Material:
 if kind.begins_with("Sleeper:"):
  var room_role := kind.trim_prefix("Sleeper:")
  if room_role=="brass": return Finishes.make(Finishes.Finish.BRASS,Color("96836a"))
  var shade := Color("68513b") if room_role=="field" else Color("574332")
  return Veneer.make("field" if room_role=="field" else "edge",shade)
 if kind.begins_with("Garden:"):
  var room_role := kind.trim_prefix("Garden:")
  if room_role=="brass": return Finishes.make(Finishes.Finish.BRASS,Color("8c8766"))
  if room_role=="field": return Finishes.make(Finishes.Finish.STEEL,Color("40594e"),false,false,true)
  return Finishes.make(Finishes.Finish.STEEL,Color("303f3a"),false,false,true)
 return Finishes.make(Finishes.Finish.BRASS,BRASS) if kind=="brass" else Veneer.make("edge" if kind=="timber" else kind)

func parked_leaf(side: int,z: float) -> void:
 keep_contact(Vector3(side*49,111,z),Vector3(0.7,172,41))
 # A true shallow, profiled border. Keep the centre as a single recessed
 # walnut face so the broad slab no longer dominates at a fly's eye height.
 var surface := bank("leaf")
 var x := side*48.60
 emit_quad(surface,Vector3(x,25,z-20.5),Vector3(x,25,z+20.5),Vector3(x,197,z+20.5),Vector3(x,197,z-20.5),Vector3(-side,0,0))
 rectangle_moulding(side,111,z,161.5,36.6,3.2,[
  [0.0,48.59,"timber"],[0.35,48.20,"timber"],[0.85,47.76,"timber"],
  [1.16,47.88,"brass"],[1.72,48.18,"timber"],[2.2,48.57,"timber"]
 ],"parked")
 # A smaller nested geometric applique gives doors a recognisable rail-car
 # construction; the physical closing leaf and portal remain unchanged.
 rectangle_moulding(side,116,z,91.0,26.0,2.8,[
  [0.0,48.59,"leaf"],[0.42,48.37,"leaf"],[0.72,48.14,"timber"],[1.30,48.58,"leaf"]
 ],"panel insert")

func pilaster(side: int,z: float) -> void:
 # Put the long rounded bevels where the previous square timber pillar sat.
 var y0 := 1.2
 var y1 := 276.8
 var section := [
  Vector2(51.9,-1.12),Vector2(51.52,-1.48),Vector2(49.49,-1.48),Vector2(49.04,-1.03),Vector2(49.04,1.03),Vector2(49.49,1.48),Vector2(51.52,1.48),Vector2(51.9,1.12)
 ]
 var surface := bank("timber")
 for i in range(section.size()):
  var a: Vector2 = section[i]
  var b: Vector2 = section[(i+1)%section.size()]
  var from := Vector3(side*a.x,y0,z+a.y)
  var to := Vector3(side*b.x,y0,z+b.y)
  var n := Vector3(-side,0,0) if absf(a.x-b.x)<0.01 else Vector3(-side*(1.0 if minf(a.x,b.x)<50.0 else -1.0),0,signf((a.y+b.y)*0.5))
  emit_quad(surface,from,to,to+Vector3(0,y1-y0,0),from+Vector3(0,y1-y0,0),n)
  for y in [y0,y1]:
   var face := Vector3(side*50.45,y,z)
   emit_tri(surface,face,Vector3(side*a.x,y,z+a.y),Vector3(side*b.x,y,z+b.y),Vector3.DOWN if y==y0 else Vector3.UP)
 var bright_x := side*48.18
 var bronze := bank("brass")
 emit_quad(bronze,Vector3(bright_x,8,z-0.28),Vector3(bright_x,8,z+0.28),Vector3(bright_x,270,z+0.28),Vector3(bright_x,270,z-0.28),Vector3(-side,0,0))
 for lip in [-0.28,0.28]:
  emit_quad(bronze,Vector3(bright_x,8,z+lip),Vector3(side*49.12,8,z+lip),Vector3(side*49.12,270,z+lip),Vector3(bright_x,270,z+lip),Vector3(0,0,signf(lip)))
 anchors.append({"role":"pilaster","side":side,"y":139.0,"z":z,"height":276.0,"width":3.0})

func emit_tri(surface: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,wanted: Vector3) -> void:
 var aligned := (b-a).cross(c-a).dot(wanted)>0
 for point in ([a,c,b] if aligned else [a,b,c]):
  surface.set_normal(wanted)
  surface.add_vertex(point)
 triangles += 1

func finish() -> void:
 for kind in banks:
  var surface: SurfaceTool = banks[kind]
  var mesh := MeshInstance3D.new()
  mesh.name = "Profile_" + str(kind)
  mesh.mesh = surface.commit()
  mesh.material_override = bank_finish(kind)
  mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  mesh.set_meta("solid_geometry_exclude",true)
  add_child(mesh)
  mesh.create_trimesh_collision()
  var solid := mesh.get_child(0).get_child(0) as CollisionShape3D
  var exact := solid.shape as ConcavePolygonShape3D
  exact.backface_collision = true
 set_meta("profile_budget",{"triangles":triangles,"surfaces":banks.size(),"old_contact_boxes":collision_count})
