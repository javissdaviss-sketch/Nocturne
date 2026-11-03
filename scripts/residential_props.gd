extends "res://scripts/lived_in_details.gd"
## Larger, non-interactive residential objects, kept against walls or on furniture.
const LEATHER := Color("6b493a")
const IVORY := Color("ded1ac")
const EBONY := Color("302b28")

func build() -> void:
 luggage_rack(1,334,Color("5d6655"))
 luggage_rack(-1,695,LEATHER)
 hat_and_umbrella_stand()
 travel_chess()
 reading_lamp()
 wireless_radio()
 finish_batches()

func luggage_rack(side: int, z: float, luggage_color: Color) -> void:
 # Wall brackets carry the rack immediately below the upper window rail.
 var wall_x: float = side*165.0
 var edge_x: float = side*121.0
 for dz in [-29.0,29.0]:
  rod(Vector3(wall_x,246,z+dz),Vector3(wall_x,222,z+dz),1.6,BRASS,true)
  rod(Vector3(wall_x,235,z+dz),Vector3(edge_x,235,z+dz),1.6,BRASS,true)
  rod(Vector3(wall_x,222,z+dz),Vector3(edge_x,235,z+dz),1.3,BRASS,true)
 rod(Vector3(edge_x,235,z-30),Vector3(edge_x,235,z+30),1.8,BRASS,true)
 rod(Vector3(wall_x,235,z-30),Vector3(wall_x,235,z+30),1.8,BRASS,true)
 for dz in [-23.0,-12.0,0.0,12.0,23.0]:
  rod(Vector3(side*124.0,235,z+dz),Vector3(side*163.0,235,z+dz),1.0,BRASS,true)
 # A shallow retaining lip makes the overhead luggage visibly secure.
 rod(Vector3(edge_x,241,z-30),Vector3(edge_x,241,z+30),1.0,BRASS,true)
 for dz in [-30.0,30.0]:
  rod(Vector3(edge_x,235,z+dz),Vector3(edge_x,241,z+dz),1.0,BRASS,true)
 suitcase(Vector3(side*143.0,235.5,z),Vector3(31,18,47),luggage_color)

func hat_and_umbrella_stand() -> void:
 var p := Vector3(139,0.4,737)
 cyl(p+Vector3(0,1.5,0),25,3.0,EBONY)
 cyl(p+Vector3(0,4.5,0),15,3.0,BRASS,true)
 rod(p+Vector3(0,5,0),p+Vector3(0,171,0),2.5,LEATHER)
 for side in [-1,1]:
  rod(p+Vector3(0,147,0),p+Vector3(side*10,160,0),1.7,BRASS,true)
  rod(p+Vector3(side*10,160,0),p+Vector3(side*10,166,0),1.7,BRASS,true)
 # A broad-brim travelling hat resting on the outer hook.
 cyl(p+Vector3(9,167.2,0),22,1.3,LEATHER)
 cyl(p+Vector3(9,173.1,0),12,10.5,LEATHER)
 cyl(p+Vector3(9,169.5,0),12.2,2.0,EBONY)
 # Umbrella's ferrule rests in a drip dish; folded canopy surrounds its shaft.
 cyl(p+Vector3(-6,8,0),12,0.8,BRASS,true)
 rod(p+Vector3(-6,9,0),p+Vector3(-6,118,0),0.75,BRASS,true)
 instance("sphere",p+Vector3(-6,57,0),Vector3(8,76,8),Color("52605a"))
 for j in range(6):
  var angle := float(j)*TAU/6.0
  var offset := Vector3(cos(angle)*3.1,0,sin(angle)*3.1)
  rod(p+Vector3(-6,24,0)+offset*0.25,p+Vector3(-6,91,0)+offset,0.27,EBONY)
 cyl(p+Vector3(-6,67,0),8.3,2.1,LEATHER)
 # Crook handle, made from a small faceted arc rather than a floating ring.
 for j in range(8):
  var a := float(j)*PI/8.0
  var b := float(j+1)*PI/8.0
  rod(p+Vector3(-9.6+cos(a)*3.6,118+sin(a)*3.6,0),p+Vector3(-9.6+cos(b)*3.6,118+sin(b)*3.6,0),1.05,LEATHER)
 rod(p+Vector3(-13.2,115,0),p+Vector3(-13.2,118,0),1.05,LEATHER)

func travel_chess() -> void:
 var p := Vector3(-102,77.45,140)
 box(p+Vector3(0,0.8,0),Vector3(38,1.6,38),LEATHER)
 # A pocket board on the unoccupied table, separate from all authored evidence.
 for x in range(8):
  for z in range(8):
   box(p+Vector3((x-3.5)*4.3,1.69,(z-3.5)*4.3),Vector3(4.29,0.18,4.29),IVORY if (x+z)%2 == 0 else EBONY)
 # A few pieces in a casual game, without a new puzzle or readable clue.
 for square in [Vector2i(0,0),Vector2i(4,0),Vector2i(6,1),Vector2i(2,2),Vector2i(5,2),Vector2i(0,3),Vector2i(3,3)]:
  chess_piece(p+Vector3((square.x-3.5)*4.3,1.8,(square.y-3.5)*4.3),IVORY,1 if square == Vector2i(4,0) else (2 if square == Vector2i(0,0) else 0))
 for square in [Vector2i(1,7),Vector2i(4,7),Vector2i(7,7),Vector2i(1,5),Vector2i(3,5),Vector2i(6,4),Vector2i(4,3)]:
  chess_piece(p+Vector3((square.x-3.5)*4.3,1.8,(square.y-3.5)*4.3),EBONY,1 if square == Vector2i(4,7) else (2 if square == Vector2i(7,7) else 0))

func chess_piece(p: Vector3, color: Color, kind: int) -> void:
 cyl(p+Vector3(0,0.35,0),2.8,0.7,color)
 cyl(p+Vector3(0,1.5,0),1.25,1.8,color)
 if kind == 0:
  instance("sphere",p+Vector3(0,2.8,0),Vector3(2.1,2.1,2.1),color)
 elif kind == 1:
  cyl(p+Vector3(0,3.0,0),2.1,0.6,color)
  box(p+Vector3(0,4.2,0),Vector3(0.65,2.1,0.65),color)
  box(p+Vector3(0,4.5,0),Vector3(2.1,0.6,0.65),color)
 else:
  cyl(p+Vector3(0,3.0,0),2.5,1.2,color)
  for side in [-1,1]:
   box(p+Vector3(side*0.85,3.9,0),Vector3(0.7,0.65,1.3),color)

func reading_lamp() -> void:
 var p := Vector3(-137,77.45,151)
 cyl(p+Vector3(0,0.8,0),12,1.6,BRASS,true)
 rod(p+Vector3(0,1.6,0),p+Vector3(0,28,0),1.15,BRASS,true)
 rod(p+Vector3(0,28,0),p+Vector3(6,33,0),1.15,BRASS,true)
 # Rounded green banker's shade with a cream diffuser along its underside.
 instance("sphere",p+Vector3(6,33,0),Vector3(19,7,9),TEAL)
 box(p+Vector3(6,30.1,0),Vector3(17,0.65,7.2),IVORY)
 for side in [-1,1]:
  rod(p+Vector3(6+side*9,32.7,0),p+Vector3(6+side*9,34.2,0),0.75,BRASS,true)
 rod(p+Vector3(13,30,1),p+Vector3(13,24,1),0.25,BRASS,true)
 instance("sphere",p+Vector3(13,23.5,1),Vector3(0.9,0.9,0.9),BRASS,true)

func wireless_radio() -> void:
 var p := Vector3(119,77.45,287)
 for dz in [-12.0,12.0]:
  box(p+Vector3(0,0.7,dz),Vector3(10,1.4,3),EBONY)
 box(p+Vector3(0,12,0),Vector3(15,21,32),LEATHER)
 box(p+Vector3(-7.6,12,0),Vector3(0.6,18,29),IVORY)
 # Grille and tuning window face inward toward the central aisle (-X).
 box(p+Vector3(-8.0,12,-6),Vector3(0.25,14,12),EBONY)
 for dz in [-10.0,-7.0,-4.0,-1.0]:
  box(p+Vector3(-8.2,12,dz),Vector3(0.2,13,0.6),BRASS,true)
 box(p+Vector3(-8.0,16,8.5),Vector3(0.3,4.5,9),EBONY)
 for dz in [5.5,7.5,9.5,11.5]:
  box(p+Vector3(-8.3,16,dz),Vector3(0.2,2.2,0.25),BRASS,true)
 for dz in [5.5,11.0]:
  instance("cylinder",p+Vector3(-8.8,7,dz),Vector3(3.6,1.6,3.6),EBONY,false,Vector3(0,0,PI*0.5))
 for dz in [-7.0,7.0]:
  rod(p+Vector3(0,22.5,dz),p+Vector3(0,26.5,dz),1.4,BRASS,true)
 rod(p+Vector3(0,26.5,-7),p+Vector3(0,26.5,7),1.8,EBONY)
 rod(p+Vector3(4,22.5,-12),p+Vector3(4,48,-4),0.55,BRASS,true)
