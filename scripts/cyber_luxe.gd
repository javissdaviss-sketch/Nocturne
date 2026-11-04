extends "res://scripts/lived_in_details.gd"
## Agatha cyber-luxe: original geometry inspired by the supplied design boards.
## Repeated trim shares render batches and keeps CPU transforms for fly physics.
const MAHOGANY := Color("583729")
const VELVET := Color("194b45")
const CYAN := Color("52bcb8")
var world: Node3D

func build_interior(w: Node3D, layout: Node3D) -> void:
 name = "CyberLuxeInterior"
 world = w
 for room in layout.rooms:
  wall_panels(room)
  transverse_panels(room)
  if room.car == 0: suite_details(room)
  elif room.car == 1: lounge_details(room)
  else: garden_details_luxe(room)
 for car in range(3):
  corridor_ceiling(car)
  curtains(car)
 finish_batches()
 # Use the same close-range surface language on repeated trim and furniture.
 for key in materials:
  if key == MAHOGANY.to_html()+str(false):
   materials[key] = w.cabin_finish(2,MAHOGANY)
  elif key == VELVET.to_html()+str(false):
   materials[key] = w.cabin_finish(1,VELVET)
  elif key == CYAN.to_html()+str(false):
   var m := materials[key] as StandardMaterial3D
   m.emission_enabled = true
   m.emission = CYAN
   m.emission_energy_multiplier = 0.7
  elif key == Color("ead3a1").to_html()+str(false):
   var m := materials[key] as StandardMaterial3D
   m.emission_enabled = true
   m.emission = Color("ead3a1")
   m.emission_energy_multiplier = 0.65
 for child in get_children():
  if child is MultiMeshInstance3D:
   var key := str(child.name).trim_prefix("Details_")
   child.material_override = materials[batches[key].material]

func wall_panels(room: Dictionary) -> void:
 var side: int = room.side
 var lo: float = room.lo
 var hi: float = room.hi
 var entry: float = room.entry
 var wallpaper := Color("273f3b") if room.car != 1 else Color("344850")
 # Work only within the solid wall spans; the 92 cm physical portal stays open.
 for span in [Vector2(lo+5,entry-50),Vector2(entry+50,hi-5)]:
  if span.y-span.x < 12: continue
  var length: float = span.y-span.x
  var middle: float = (span.x+span.y)*0.5
  for face in [-1,1]:
   var x: float = side*55+face*3.0
   wainscot(x,middle,length)
   var wall: MeshInstance3D = world.box(Vector3(x,153,middle),Vector3(0.5,114,length),Color.WHITE,false,self)
   wall.material_override = world.cabin_finish(3,wallpaper)
   for y in [92,96,211,216,278]:
    box(Vector3(x+face*0.8,y,middle),Vector3(1.0,1.2,length),BRASS,true)
   var count := maxi(1,int(length/68))
   for j in range(count+1):
    var z: float = span.x+length*float(j)/count
    box(Vector3(x+face*0.6,150,z),Vector3(1,119,1.1),BRASS,true)
  # Brass pilasters frame each wallpaper bay on the corridor side.
  for z in [span.x,span.y]:
   box(Vector3(side*50.5,139,z),Vector3(3,276,3),MAHOGANY)
   box(Vector3(side*48.5,139,z),Vector3(0.7,263,0.7),BRASS,true)
 # A warm fluted wall lamp at each entrance, with cyan access-control inset.
 var lamp_z: float = entry-61
 box(Vector3(side*48,230,lamp_z),Vector3(5,37,13),MAHOGANY)
 box(Vector3(side*44,230,lamp_z),Vector3(4,26,9),Color("ead3a1"))
 for dz in [-4.6,0,4.6]:
  box(Vector3(side*41.5,230,lamp_z+dz),Vector3(0.8,28,0.5),BRASS,true)
 for y in [215,245]: box(Vector3(side*44,y,lamp_z),Vector3(7,2,13),BRASS,true)
 box(Vector3(side*48,121,entry-49),Vector3(1.5,13,6),MAHOGANY)
 box(Vector3(side*46.8,123,entry-49),Vector3(0.5,7,3.8),CYAN)
 # Enriched parked door leaf, never across the open entrance.
 box(Vector3(side*49,111,entry+79),Vector3(0.7,172,41),MAHOGANY)
 for z in [entry+61,entry+97]:
  box(Vector3(side*48,111,z),Vector3(0.5,163,0.7),BRASS,true)
 for y in [30,191]:
  box(Vector3(side*48,y,entry+79),Vector3(0.5,0.7,37),BRASS,true)
 # Broad exterior window sill and upholstered wall panels below the glass.
 box(Vector3(side*499,92,(lo+hi)*0.5),Vector3(16,4,hi-lo-14),MAHOGANY)
 for y in [12,83]:
  box(Vector3(side*506,y,(lo+hi)*0.5),Vector3(1,2,hi-lo-14),BRASS,true)
 for z in range(int(lo+24),int(hi-12),72):
  box(Vector3(side*506,47,z),Vector3(1,58,58),VELVET)
  box(Vector3(side*504.8,47,z),Vector3(0.7,2,9),BRASS,true)

func wainscot(x: float, z: float, length: float) -> void:
 box(Vector3(x,45,z),Vector3(0.8,88,length),MAHOGANY)
 var count := maxi(1,int(length/58))
 for j in range(count):
  var pz := z-length*0.5+(j+0.5)*length/count
  var width := length/count-10
  for y in [15,75]: box(Vector3(x-signf(x),y,pz),Vector3(0.8,1.0,width),BRASS,true)
  for dz in [-width*0.5,width*0.5]:
   box(Vector3(x-signf(x),45,pz+dz),Vector3(0.8,60,1),BRASS,true)

func transverse_panels(room: Dictionary) -> void:
 var side: int = room.side
 var x: float = side*285
 for end in [Vector2(room.lo,1),Vector2(room.hi,-1)]:
  var z: float = end.x+end.y*3.5
  box(Vector3(x,44,z),Vector3(438,86,1),MAHOGANY)
  var finish: MeshInstance3D = world.box(Vector3(x,164,z),Vector3(438,139,0.5),Color.WHITE,false,self)
  finish.material_override = world.cabin_finish(3,Color("293e39") if room.car != 1 else Color("30434a"))
  for y in [13,78,91,235,278]:
   box(Vector3(x,y,z+end.y*0.8),Vector3(438,1.1,1),BRASS,true)
  for dx in [-204,-136,-68,0,68,136,204]:
   box(Vector3(x+dx,45,z+end.y*0.8),Vector3(1,59,1),BRASS,true)
   box(Vector3(x+dx,164,z+end.y*0.8),Vector3(0.7,138,0.7),BRASS,true)

func corridor_ceiling(car: int) -> void:
 var start := float(car)*840
 box(Vector3(0,292,start+400),Vector3(90,2,786),Color("c6b494"))
 for x in [-44,44]:
  box(Vector3(x,285,start+400),Vector3(3,8,786),MAHOGANY)
  box(Vector3(x,280,start+400),Vector3(1,1,786),BRASS,true)
 for z in range(int(start+60),int(start+790),140):
  box(Vector3(0,287,z),Vector3(90,6,6),MAHOGANY)
  cyl(Vector3(0,280,z+50),16,3,BRASS,true)
  instance("sphere",Vector3(0,277,z+50),Vector3(13,6,13),Color("ecd7ac"))
 for z in [start+190,start+610]:
  world.light_at(Vector3(0,242,z),Color("ffd5a1"),0.65,230)
 # A small in-universe address at the carriage threshold.
 var names := ["THE NIGHT RESIDENCES","THE MERIDIAN SALON","THE LIVING ARCHIVE"]
 var panel_z := start+12
 box(Vector3(0,252,panel_z),Vector3(103,31,2),MAHOGANY)
 for y in [238,266]: box(Vector3(0,y,panel_z-1.2),Vector3(99,0.8,0.7),BRASS,true)
 world.sign_text(names[car],Vector3(0,256,panel_z-1.5),0.075,CREAM,self)
 world.sign_text("NOCTURNE  /  %02d OF 12" % (car+6),Vector3(0,245,panel_z-1.5),0.052,BRASS,self)

func suite_details(room: Dictionary) -> void:
 var side: int = room.side
 var z: float = (room.lo+room.hi)*0.5
 var bx: float = side*415
 # Carved headboard, velvet insert, buttoning, turned posts and brass bed rails.
 box(Vector3(bx,88,z-100.8),Vector3(119,48,2),VELVET)
 for dx in [-69,69]:
  cyl(Vector3(bx+dx,62,z-105),5,122,MAHOGANY)
  instance("sphere",Vector3(bx+dx,128,z-105),Vector3(11,11,11),BRASS,true)
 for y in [65,112]: box(Vector3(bx,y,z-99),Vector3(121,1.2,1),BRASS,true)
 for dx in [-42,-21,0,21,42]:
  for y in [77,98]:
   instance("sphere",Vector3(bx+dx,y,z-99),Vector3(2.4,2.4,1.2),BRASS,true)
 for dx in [-65,65]:
  box(Vector3(bx+dx,27,z+1),Vector3(2,2,197),BRASS,true)
 for offset in [-45,0,45]:
  box(Vector3(bx+offset,68.1,z+22),Vector3(0.6,0.4,146),BRASS,true)
 box(Vector3(bx,68.3,z+71),Vector3(132,0.5,25),Color("9b8665"))
 # Bedside control pedestal and small dome reading lamp.
 var px := bx-side*96
 box(Vector3(px,31,z-70),Vector3(36,62,40),MAHOGANY)
 box(Vector3(px,63,z-70),Vector3(38,2,42),BRASS,true)
 cyl(Vector3(px,72,z-70),2,18,BRASS,true)
 instance("sphere",Vector3(px,84,z-70),Vector3(22,14,22),VELVET)
 box(Vector3(px,49,z-91),Vector3(22,10,1),CYAN)
 for dx in [-22,22]:
  box(Vector3(side*230+dx,117,room.hi-54.7),Vector3(39,178,1),MAHOGANY)
  for y in [32,205]: box(Vector3(side*230+dx,y,room.hi-55.5),Vector3(36,1,1),BRASS,true)
 # Travel trunk and subtle perimeter wiring, pulled away from original clues.
 suitcase(Vector3(side*420,1,z+125),Vector3(96,42,45),MAHOGANY)
 box(Vector3(side*420,29,z+101.8),Vector3(87,0.7,0.6),CYAN)
 data_slate(Vector3(side*242,78,room.lo+75))
 desk_lamp(Vector3(side*242-side*24,78,room.lo+57))
 pocket_watch(Vector3(side*242+side*25,79,room.lo+78))

func curtains(car: int) -> void:
 for side in [-1,1]:
  for z in range(car*840+40,car*840+790,170):
   # Folded velvet at the mullions keeps the rain-streaked view open.
   for dz in [-7,0,7]:
    cyl(Vector3(side*489,183,z+dz),8,159,VELVET)
   box(Vector3(side*481,155,z),Vector3(2,5,25),BRASS,true)
   box(Vector3(side*493,266,z+73),Vector3(8,16,155),VELVET)
   box(Vector3(side*488,256,z+73),Vector3(1,1,155),BRASS,true)

func data_slate(p: Vector3) -> void:
 box(p,Vector3(17,1.5,23),MAHOGANY,false,0.08)
 box(p+Vector3(0,0.9,0),Vector3(13,0.25,18),Color("244744"),false,0.08)
 for j in range(4):
  box(p+Vector3(0,1.1,-5+j*2.5),Vector3(9-j,0.15,0.25),CYAN,false,0.08)

func desk_lamp(p: Vector3) -> void:
 cyl(p+Vector3(0,1,0),13,2,BRASS,true)
 cyl(p+Vector3(0,13,0),1.8,24,BRASS,true)
 # A linen shade over quiet cyan wiring echoes the reference's glass-table lamp.
 instance("sphere",p+Vector3(0,15,0),Vector3(3.5,18,3.5),CYAN)
 cyl(p+Vector3(0,28,0),20,17,Color("ead3a1"))
 for j in range(10):
  var angle := j*TAU/10
  rod(p+Vector3(cos(angle)*10,20,sin(angle)*10),p+Vector3(cos(angle)*10,36,sin(angle)*10),0.25,BRASS,true)
 for y in [20,36]: instance("fine_ring",p+Vector3(0,y,0),Vector3(20.5,0.7,20.5),BRASS,true)

func pocket_watch(p: Vector3) -> void:
 cyl(p,9,1.5,BRASS,true)
 cyl(p+Vector3(0,0.9,0),7.4,0.3,Color("21433f"))
 instance("fine_ring",p+Vector3(0,1.2,0),Vector3(6.6,0.2,6.6),CYAN)
 rod(p+Vector3(0,1.2,0),p+Vector3(2.2,1.2,1.5),0.3,BRASS,true)
 rod(p+Vector3(0,1.3,0),p+Vector3(-1,1.3,2.5),0.2,CYAN)
 for j in range(10):
  instance("ring",p+Vector3(5+j*1.5,0.2,sin(j*0.55)*2),Vector3(2.1,0.35,2.1),BRASS,true)

func lounge_details(room: Dictionary) -> void:
 var side: int = room.side
 if room.hi-room.lo > 300:
  for z in [room.lo+100,room.hi-100]:
   var x: float = side*345
   for dx in [-55,55]:
    napkin(Vector3(x+dx,78.2,z-21))
    service_cup(Vector3(x+dx,78.2,z+17))
   # An illuminated botanical vitrine at the table's centre.
   cyl(Vector3(x,81,z),10,5,BRASS,true)
   cyl(Vector3(x,88,z),6,10,Color("345c55"))
   for j in range(3): flower_sprig(Vector3(x,94,z),Vector3(j*2-2,12,j*2-2),Color("bfac90"))
  world.plant(Vector3(side*465,1,room.lo+35),154,34)
  # Small wall medallion gives each room an identifiable focal point.
  var medallion := Vector3(side*290,175,room.hi-4)
  instance("fine_ring",medallion,Vector3(76,3,76),BRASS,true,Vector3(PI/2,0,0))
  for ray in range(9):
   var angle := -PI*0.5+ray*PI/8
   rod(medallion+Vector3(0,-22,-1),medallion+Vector3(cos(angle)*32,sin(angle)*32,-1),0.7,BRASS,true)
 else:
  for z in range(int(room.lo+35),int(room.hi-20),46):
   box(Vector3(side*339,47,z),Vector3(1,65,37),MAHOGANY)
   box(Vector3(side*337.8,49,z),Vector3(1,1,12),BRASS,true)
   cyl(Vector3(side*401,103,z),6,14,Color("466864"))
   cyl(Vector3(side*401,111,z),6.2,2,BRASS,true)
  data_slate(Vector3(side*393,97,(room.lo+room.hi)*0.5))

func garden_details_luxe(room: Dictionary) -> void:
 var side: int = room.side
 for z in [room.lo+65,(room.lo+room.hi)*0.5,room.hi-65]:
  for y in [12,56]:
   box(Vector3(side*377,y,z-32),Vector3(192,1.3,1),BRASS,true)
  for dx in [-82,-41,0,41,82]:
   box(Vector3(side*377+dx,35,z-32),Vector3(1.5,44,1),MAHOGANY)
  # Visible sensors keep the conservatory's technology subordinate to plants.
  box(Vector3(side*377,48,z-33),Vector3(24,12,1),MAHOGANY)
  box(Vector3(side*377,49,z-33.7),Vector3(18,6,0.5),CYAN)
 var text := "NOCTURNE BOTANICAL TRUST\nLIVING COLLECTION  /  ORCHIDACEAE" if room.lo < 2045 else "SEED RESERVE  /  HERITAGE CULTIVARS\nPRESERVE  ·  PROPAGATE  ·  RETURN"
 var label: Label3D = world.sign_text(text,Vector3(side*285,188,room.lo+5),0.085,CREAM,self)
 label.rotation.y = PI
 box(Vector3(side*285,188,room.lo+3),Vector3(184,36,2),MAHOGANY)
