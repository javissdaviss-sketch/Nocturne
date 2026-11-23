extends Node3D
## Full-height compartments inside a 10.2 m megatrain. Original evidence stays in place.
const HALF_WIDTH := 510.0
const CORRIDOR_EDGE := 55.0
var rooms: Array[Dictionary] = []
var doorways: Array[Vector3] = []
const STEEL := Color("293d41")
const BRASS := Color("b6925e")
const CORRIDOR_INLAY := Color("c6a46c")
const WARM := Color("d9cbb0")
const DESK_TOP_Y := 77.4
const FittedVeneer = preload("res://scripts/fitted_veneer.gd")
const Ceilings:=preload("res://scripts/room_ceiling_joinery.gd")
const Floors := preload("res://scripts/room_floor_finish.gd")
const RoomIdentity = preload("res://scripts/room_identity.gd")
const PropMeshes = preload("res://scripts/prop_meshes.gd")

static func sleeper_desk_center(side: int, lo: float) -> Vector3:
 return Vector3(side*300,0,lo+75)

static func salon_table_rows(lo: float, hi: float) -> Array[float]:
 return [lo+100, hi-120]
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
  # Preserve the original side inlay beside the wall, not suspended across
  # the opening. Match its original clipped span within this carriage.
  var inlay_lo:=maxf(span.x,car*840.0+10.0)
  var inlay_hi:=minf(span.y,car*840.0+790.0)
  if inlay_hi-inlay_lo>0.001:
   w.box(Vector3(side*58,1.5,(inlay_lo+inlay_hi)*0.5),Vector3(1,0.4,inlay_hi-inlay_lo),CORRIDOR_INLAY,false,self)
 fit_room_threshold(w,car,side,entry,width)
 w.box(Vector3(x,259,entry),Vector3(5,74,width),STEEL,true,self)
 for dz in [-half-1,half+1]:
  portal_trim(w,car,Vector3(x,112,entry+dz),Vector3(9,224,3))
 portal_trim(w,car,Vector3(x,223,entry),Vector3(9,3,width+6))
 # Parked sliding leaf, visibly retracted beside the open portal.
 w.box(Vector3(x+side*5,108,parked),Vector3(3,211,54),STEEL,true,self)
 preload("res://scripts/door_purpose_plates.gd").attach(w,self,car,side,lo,parked)
 for h in [18,194]:
  for span in [Vector2(lo,entry-half),Vector2(entry+half,hi)]:
   w.box(Vector3(x-side*3,h,(span.x+span.y)*0.5),Vector3(1,2,span.y-span.x),BRASS,true,self,0.6)
 var plaque: Label3D = w.sign_text(title,Vector3(x-side*5,251,entry),0.10,WARM,self)
 plaque.rotation.y = -side*PI/2
 w.box(Vector3(x-side*4,251,entry),Vector3(1,22,104),STEEL,true,self)
 w.light_at(Vector3(side*250,241,(lo+hi)*0.5),Color("ffd9a1") if car != 2 else Color("badfc8"),0.65,280)
 # Outer-room floor insets make the wider volume legible without scaling props.
 var inset:MeshInstance3D=w.box(Vector3(side*332,0.8,(lo+hi)*0.5),Vector3(300,1,hi-lo-18),Color.WHITE,true,self)
 inset.name="FittedRoomFloor_%d_%d_%d"%[car,side,int(lo)]
 var finished:=Floors.get_floor(car,side,lo,hi)
 inset.material_override = finished if finished!=null else w.runner_finish(car)
 Ceilings.build(w,self,car,side,lo,hi)
 if car == 0:
  sleeper(w,side,lo,hi)
 elif car == 1:
  hospitality(w,side,lo,hi)
 else:
  nursery(w,side,lo,hi)

func fit_room_threshold(w:Node3D, car:int, side:int, entry:float, width:float)->void:
 # Only the existing open threshold: 1.4cm aisle runner to y=0 room
 # deck. Render and physical fit use one identical rotated solid box.
 const TREAD_DEPTH:=10.0
 const TREAD_RISE:=1.4
 const TREAD_SKIN:=0.25
 var bevel:float=-side*atan(TREAD_RISE/TREAD_DEPTH)
 var size:=Vector3(Vector2(TREAD_DEPTH,TREAD_RISE).length(),TREAD_SKIN,width)
 var center:=Vector3(side*(CORRIDOR_EDGE+TREAD_DEPTH*0.5),TREAD_RISE*0.5,entry)
 var inset:MeshInstance3D=w.box(center-Basis(Vector3.BACK,bevel)*Vector3.UP*(TREAD_SKIN*0.5),size,Color.WHITE,false,self)
 inset.name="RoomThreshold_%d_%d_%d"%[car+6,side,int(entry)]
 inset.rotation.z=bevel
 inset.material_override=w.runner_finish(car)
 inset.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var body:=StaticBody3D.new()
 body.collision_mask=0
 inset.add_child(body)
 var collision:=CollisionShape3D.new()
 var shape:=BoxShape3D.new()
 shape.size=size
 collision.shape=shape
 body.add_child(collision)

func portal_trim(w: Node3D,car: int,center: Vector3,size: Vector3) -> void:
 if car!=1:
  preload("res://scripts/coach_architraves.gd").add(w,self,car,center,size)
  return
 # Carriage 07 pilot: the true profile replaces the rectangular face but
 # remains behind the old aperture bounds and uses its actual contact mesh.
 var trim: MeshInstance3D = w.mesh_obj(self,PropMeshes.rounded(size,0.68),center,BRASS,true,0.65)
 trim.name = "RoundedMeridianArchitrave"

func sleeper(w: Node3D, side: int, lo: float, hi: float) -> void:
 var z := (lo+hi)*0.5
 preload("res://scripts/sleeping_assets.gd").build_bed(w,self,Vector3(side*415,0,z),RoomIdentity.sleeping(side,lo))
 preload("res://scripts/cabinet_assets.gd").wardrobe(w,self,Vector3(side*230,0,hi-30))
 var purpose := ("writing" if is_zero_approx(lo) else "coast") if side<0 else ("crew" if is_zero_approx(lo) else "engineering")
 w.table(sleeper_desk_center(side,lo),75,65,purpose)
 var fabric:Color={"writing":Color("62444f"),"crew":Color("615d46"),
  "coast":Color("6e7a7d"),"engineering":Color("4a5654")}[purpose]
 w.seat(Vector3(side*300,0,lo+148),fabric,"berth-"+purpose)

func hospitality(w: Node3D, side: int, lo: float, hi: float) -> void:
 var length := hi-lo
 if length > 300:
  for z in salon_table_rows(lo,hi):
   var guest_table: Node3D = w.table(Vector3(side*345,0,z),150,80)
   var table_top := guest_table.get_node("MouldedWalnutTop") as MeshInstance3D
   # The large occupied outer tables are distinct from the evidence table.
   # Still one grounded top, with differently fitted narrow-grained veneer.
   table_top.material_override = FittedVeneer.make("table",Color("514636") if side<0 else Color("405149"))
   for dx in [-44,44]:
    var upholstery := Color("623f45") if side<0 else Color("4b6256")
    var furniture := "meridian" if side<0 else "tea"
    w.face_seat(w.seat(Vector3(side*345+dx,0,z+76),upholstery,furniture),Vector3(side*345+dx,0,z))
 else:
  preload("res://scripts/cabinet_assets.gd").service_counter(w,self,Vector3(side*410,0,(lo+hi)*0.5),length-30,side,RoomIdentity.service(side,lo))

func nursery(w: Node3D, side: int, lo: float, hi: float) -> void:
 # These occupied-shape scans were measured on the whole physical train;
 # both complete footprints sit on the same flat deck well away from clues.
 if is_equal_approx(lo,1680.0):
  var station := Vector3(-157.0,0.0,1892.0) if side<0 else Vector3(151.0,0.0,1822.0)
  preload("res://scripts/garden_purpose_assets.gd").build(w,self,station,side<0)
 for z in [lo+65,(lo+hi)*0.5,hi-65]:
  var planter := preload("res://scripts/garden_fixture_geometry.gd").new()
  add_child(planter)
  planter.build_planter(Vector3(side*377,0,z),Vector3(200,64,62),RoomIdentity.garden(side,lo))
 var collection := preload("res://scripts/botanical_collection.gd").new()
 add_child(collection)
 collection.populate(side,lo,hi)
 w.box(Vector3(side*270,246,(lo+hi)*0.5),Vector3(10,4,hi-lo-25),Color("233c35"),true,self,0.4)
 for dx in [-4,4]: w.box(Vector3(side*270+dx,243.5,(lo+hi)*0.5),Vector3(1.3,3,hi-lo-25),BRASS,true,self,0.6)
 var diffuser: MeshInstance3D = w.box(Vector3(side*270,243.5,(lo+hi)*0.5),Vector3(5,1.6,hi-lo-31),Color("b7c9a3"),true,self,0,0.35)
 # Change the existing archive strip's own emissive surface, not room lighting.
 # Keep its material separate from the other three strips.
 if side == 1 and lo >= 2045.0:
  diffuser.material_override = diffuser.material_override.duplicate()
  w.night_task_diffuser = diffuser
  w.set_nursery_task_light(false)
