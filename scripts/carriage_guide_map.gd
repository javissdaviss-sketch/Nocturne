extends Control
## Draw the same opaque walls and doorway gaps as the procedural room layout.
const Guide = preload("res://scripts/carriage_guide.gd")
const FLOOR := Color("16342e")
const PIN_FLOOR := Color("3a3a2d")
const HALL := Color("34574c")
const FRAME := Color("708578")
const GOLD := Color("d9bc7e")
var rooms: Array = []
var player := Vector3.ZERO
var pin := -1

func point(x: float, z: float) -> Vector2:
 return Guide.map_point(Vector3(x,0,z),Rect2(Vector2(7,7),size-Vector2(14,14)))

func plane(x0: float, z0: float, x1: float, z1: float) -> Rect2:
 var a := point(x0,z0)
 var b := point(x1,z1)
 return Rect2(a.min(b),(a-b).abs())

func _draw() -> void:
 var edge := float(Guide.HALL_EDGE)
 var body := float(Guide.Layout.HALF_WIDTH)
 for car in range(3):
  var lo := INF
  var hi := -INF
  for room in rooms:
   if int(room.car)==car:
    lo = minf(lo,float(room.lo))
    hi = maxf(hi,float(room.hi))
  if lo>=hi: continue
  var outline := plane(-body,lo,body,hi)
  draw_rect(outline,PIN_FLOOR if pin==car else FLOOR)
  draw_rect(outline,GOLD if pin==car else FRAME,false,1.3)
 draw_rect(plane(-edge,0,edge,Guide.TRAIN_END),HALL)
 for room in rooms:
  var x := int(room.side)*edge
  var end_x := int(room.side)*body
  var hi := float(room.hi)
  draw_line(point(x,hi),point(end_x,hi),FRAME,1.4,true)
  for run in Guide.solid_runs(room):
   draw_line(point(x,run.x),point(x,run.y),FRAME,1.5,true)
 var location := point(player.x,player.z)
 draw_circle(location,6.0,Color("17201c"),true,-1.0,true)
 draw_circle(location,4.1,GOLD,true,-1.0,true)
