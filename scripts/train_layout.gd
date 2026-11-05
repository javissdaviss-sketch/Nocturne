extends Node3D
## Full-height compartments inside a 10.2 m megatrain. Original evidence stays in place.
const HALF_WIDTH := 510.0
const CORRIDOR_EDGE := 55.0
var rooms: Array[Dictionary] = []
var doorways: Array[Vector3] = []
const STEEL := Color("293d41")
const BRASS := Color("b6925e")
const WARM := Color("d9cbb0")
# Entrances are authored around the fixed investigation props, with a clear
# landing/flight apron beyond the wall. Widths are physical centimetres.
const ENTRIES = [
 [[55.0,740.0],[194.0,740.0]],
 [[889.0,1150.0,1580.0],[889.0,1240.0,1588.0]],
 [[1750.0,2110.0],[1750.0,2400.0]]
]

func build(w: Node3D) -> void:
 name = "CompartmentLayout"
 var divisions := [[0.0,360.0,800.0],[840.0,990.0,1390.0,1640.0],[1680.0,2045.0,2480.0]]
 var titles := [
  ["06 A / SLEEPER SUITE", "06 B / ENGINEERING QUARTERS"],
  ["07 A / RECEPTION", "07 B / PRIVATE DINING", "07 C / GALLEY & SERVICE"],
  ["08 A / PROPAGATION LAB", "08 B / SEED ARCHIVE"]]
 for car in range(3):
  var bounds: Array = divisions[car]
  for side in [-1,1]:
   for i in range(bounds.size()-1):
    var lo: float = bounds[i]
    var hi: float = bounds[i+1]
    var entry: float = ENTRIES[car][0 if side == -1 else 1][i]
    var width := 84.0 if (car == 0 and side == 1 and i == 0) or (car == 1 and i == 0) or (car == 1 and side == 1 and i == 2) else 92.0
    var parking_side := 1.0 if hi-entry-width*0.5 >= 56.0 else -1.0
    var parked := entry+parking_side*(width*0.5+30.0)
    rooms.append({"car":car,"side":side,"lo":lo,"hi":hi,"entry":entry,"width":width,"parked":parked})
    doorways.append(Vector3(side*CORRIDOR_EDGE,105,entry))
    compartment(w,car,side,lo,hi,entry,titles[car][i],width,parked)
   for i in range(1,bounds.size()-1):
    var z: float = bounds[i]
    w.box(Vector3(side*282.5,148,z),Vector3(455,296,5),STEEL,true,self)
    for x in [190,360,490]:
     w.box(Vector3(side*x,148,z-3),Vector3(3,290,2),BRASS,true,self,0.6)
  # Exposed overhead utility pipes reinforce the working megatrain structure.
  for x in [-38,38]:
   w.line(Vector3(x,278,car*840+14),Vector3(x,278,car*840+786),2.5,STEEL,self)
   for z in range(50,790,120):
    w.box(Vector3(x,278,car*840+z),Vector3(9,9,3),BRASS,true,self,0.7)

func compartment(w: Node3D, car: int, side: int, lo: float, hi: float, entry: float, title: String, width: float = 92.0, parked: float = 0.0) -> void:
 var x := side*CORRIDOR_EDGE
 var finish := Color("50372a") if car == 0 else Color("294b3e")
 if car == 1: finish = Color("4c3026")
 # Solid wall sections and lintel leave the authored width and 222 cm height.
 var half := width*0.5
 for span in [Vector2(lo,entry-half),Vector2(entry+half,hi)]:
  w.box(Vector3(x,148,(span.x+span.y)*0.5),Vector3(5,296,span.y-span.x),finish,true,self).material_override = w.cabin_finish(2,finish)
 w.box(Vector3(x,259,entry),Vector3(5,74,width),STEEL,true,self)
 for dz in [-half-1,half+1]:
  w.box(Vector3(x,112,entry+dz),Vector3(9,224,3),BRASS,true,self,0.65)
 w.box(Vector3(x,223,entry),Vector3(9,3,width+6),BRASS,true,self,0.65)
 # Parked sliding leaf, visibly retracted beside the open portal.
 w.box(Vector3(x+side*5,108,parked),Vector3(3,211,54),STEEL,true,self)
 for h in [18,194]:
  for span in [Vector2(lo,entry-half),Vector2(entry+half,hi)]:
   w.box(Vector3(x-side*3,h,(span.x+span.y)*0.5),Vector3(1,2,span.y-span.x),BRASS,true,self,0.6)
 var plaque: Label3D = w.sign_text(title,Vector3(x-side*5,251,entry),0.10,WARM,self)
 plaque.rotation.y = -side*PI/2
 w.box(Vector3(x-side*4,251,entry),Vector3(1,22,104),STEEL,true,self)
 w.light_at(Vector3(side*250,241,(lo+hi)*0.5),Color("ffd9a1") if car != 2 else Color("badfc8"),0.65,280)
 # Outer-room floor insets make the wider volume legible without scaling props.
 w.box(Vector3(side*332,0.8,(lo+hi)*0.5),Vector3(300,1,hi-lo-18),Color.WHITE,true,self).material_override = w.runner_finish(car)
 if car == 0:
  sleeper(w,side,lo,hi)
 elif car == 1:
  hospitality(w,side,lo,hi)
 else:
  nursery(w,side,lo,hi)

func sleeper(w: Node3D, side: int, lo: float, hi: float) -> void:
 var z := (lo+hi)*0.5
 preload("res://scripts/sleeping_assets.gd").build_bed(w,self,Vector3(side*415,0,z))
 preload("res://scripts/cabinet_assets.gd").wardrobe(w,self,Vector3(side*230,0,hi-30))
 w.table(Vector3(side*300,0,lo+75),75,65)
 w.seat(Vector3(side*300,0,lo+145),Color("204d49"))

func hospitality(w: Node3D, side: int, lo: float, hi: float) -> void:
 var length := hi-lo
 if length > 300:
  for z in [lo+100,hi-100]:
   w.table(Vector3(side*345,0,z),150,80)
   for dx in [-44,44]: w.seat(Vector3(side*345+dx,0,z+72),Color("623f45"))
 else:
  preload("res://scripts/cabinet_assets.gd").service_counter(w,self,Vector3(side*410,0,(lo+hi)*0.5),length-30,side)

func nursery(w: Node3D, side: int, lo: float, hi: float) -> void:
 for z in [lo+65,(lo+hi)*0.5,hi-65]:
  var planter := preload("res://scripts/garden_fixture_geometry.gd").new()
  add_child(planter)
  planter.build_planter(Vector3(side*377,0,z),Vector3(200,64,62))
 var collection := preload("res://scripts/botanical_collection.gd").new()
 add_child(collection)
 collection.populate(side,lo,hi)
 w.box(Vector3(side*270,246,(lo+hi)*0.5),Vector3(10,4,hi-lo-25),Color("233c35"),true,self,0.4)
 for dx in [-4,4]: w.box(Vector3(side*270+dx,243.5,(lo+hi)*0.5),Vector3(1.3,3,hi-lo-25),BRASS,true,self,0.6)
 w.box(Vector3(side*270,243.5,(lo+hi)*0.5),Vector3(5,1.6,hi-lo-31),Color("b7c9a3"),true,self,0,0.35)
