extends "res://scripts/lived_in_details.gd"
## Recognizable hospitality equipment kept outside the central flight aisle.
const SILVER := Color("aebbb9")
const WICKER := Color("9d7950")
const BREAD := Color("b8874d")
const GLASS := Color("48695b")

func build() -> void:
 service_trolley(Vector3(125,0.4,1010))
 service_station(Vector3(135,86.3,1320))
 unused_place(Vector3(-101,78.0,1450))
 finish_batches()

func service_trolley(p: Vector3) -> void:
 # Four actual caster wheels, two shelves and a tubular push handle give this
 # a readable silhouette even at a distance, rather than another plain cupboard.
 for x in [-19,19]:
  for z in [-25,25]:
   var wheel := p+Vector3(x,4.8,z)
   instance("cylinder",wheel,Vector3(9,3.2,9),DARK,false,Vector3(0,0,PI*0.5))
   instance("cylinder",wheel+Vector3(sign(float(x))*1.7,0,0),Vector3(3.4,0.5,3.4),BRASS,true,Vector3(0,0,PI*0.5))
   rod(p+Vector3(x,7,z),p+Vector3(x,15,z),1.4,BRASS,true)
   rod(p+Vector3(x,11,z),p+Vector3(x,83,z),1.3,BRASS,true)
 for level in [25.0,78.0]:
  box(p+Vector3(0,level,0),Vector3(44,1.8,62),BRASS,true)
  box(p+Vector3(0,level+1.0,0),Vector3(41,0.4,59),TEAL)
  for x in [-21,21]:
   rod(p+Vector3(x,level+3.8,-30),p+Vector3(x,level+3.8,30),0.8,BRASS,true)
  for z in [-30,30]:
   rod(p+Vector3(-21,level+3.8,z),p+Vector3(21,level+3.8,z),0.8,BRASS,true)
 for x in [-19,19]:
  rod(p+Vector3(x,78,28),p+Vector3(x,94,35),1.5,BRASS,true)
 rod(p+Vector3(-19,94,35),p+Vector3(19,94,35),1.8,BRASS,true)
 # The top tray is laid for tea; no duplicate full place settings elsewhere.
 teapot(p+Vector3(-7,80.0,-11))
 sugar_bowl(p+Vector3(10,80.0,-13))
 for z in [8,19]:
  cyl(p+Vector3(-9,80.7,z),9.5,0.65,CREAM)
  cyl(p+Vector3(-9,81.5,z),8,0.6,CREAM)
  instance("fine_ring",p+Vector3(-9,81.9,z),Vector3(8,0.15,8),BRASS,true)
 # Water bottles are deliberately tall and unlabelled, unlike the clue bottle.
 bottle(p+Vector3(-12,26.6,-18),GLASS)
 bottle(p+Vector3(0,26.6,-18),Color("836546"))
 bread_basket(p+Vector3(4,26.6,12))

func teapot(p: Vector3) -> void:
 cyl(p+Vector3(0,1.1,0),10,1.7,BRASS,true)
 instance("sphere",p+Vector3(0,8.5,0),Vector3(14,14,14),CREAM)
 cyl(p+Vector3(0,14.7,0),9,1.1,CREAM)
 instance("fine_ring",p+Vector3(0,15.2,0),Vector3(9,0.2,9),BRASS,true)
 cyl(p+Vector3(0,16.3,0),2.5,2,BRASS,true)
 # A rising spout and separate loop handle make the pot recognizable.
 rod(p+Vector3(5,8,0),p+Vector3(10,10.5,0),3.0,CREAM)
 rod(p+Vector3(10,10.5,0),p+Vector3(12.5,15,0),2.3,CREAM)
 instance("cylinder",p+Vector3(12.7,15.5,0),Vector3(2.4,0.5,2.4),BRASS,true,Vector3(0,0,-0.5))
 instance("ring",p+Vector3(-8.0,9,0),Vector3(9.5,1.1,10.5),BRASS,true,Vector3(PI*0.5,0,0))

func sugar_bowl(p: Vector3) -> void:
 cyl(p+Vector3(0,0.6,0),7.5,1.0,BRASS,true)
 instance("sphere",p+Vector3(0,3.4,0),Vector3(8,6,8),CREAM)
 cyl(p+Vector3(0,6.2,0),7,0.6,CREAM)
 cyl(p+Vector3(0,7.1,0),1.7,1.1,BRASS,true)
 for side in [-1,1]:
  instance("ring",p+Vector3(side*4.0,3.5,0),Vector3(3.4,0.55,3.4),BRASS,true,Vector3(PI*0.5,0,0))

func bottle(p: Vector3, color: Color) -> void:
 cyl(p+Vector3(0,0.6,0),7.0,1.0,color)
 cyl(p+Vector3(0,9,0),7,16,color)
 instance("sphere",p+Vector3(0,17.5,0),Vector3(7,6,7),color)
 cyl(p+Vector3(0,22.0,0),3.1,7,color)
 cyl(p+Vector3(0,26.2,0),3.5,1.5,BRASS,true)
 instance("fine_ring",p+Vector3(0,24.7,0),Vector3(3.2,0.2,3.2),BRASS,true)

func bread_basket(p: Vector3) -> void:
 # A shallow woven basket with rolled rim and a loose linen liner.
 box(p+Vector3(0,1,0),Vector3(25,2,20),WICKER)
 box(p+Vector3(0,2.2,0),Vector3(22,0.5,17),LINEN)
 for z in [-9,9]:
  box(p+Vector3(0,4.2,z),Vector3(25,5.5,1.5),WICKER)
  rod(p+Vector3(-12,7.0,z),p+Vector3(12,7.0,z),1.2,WICKER)
 for x in [-12,12]:
  box(p+Vector3(x,4.2,0),Vector3(1.5,5.5,20),WICKER)
  rod(p+Vector3(x,7.0,-9),p+Vector3(x,7.0,9),1.2,WICKER)
 for z in [-9.9,9.9]:
  for x in [-9,-5,-1,3,7,11]:
   box(p+Vector3(x,4.5,z),Vector3(0.55,4.8,0.3),Color("b49367"))
 for x in [-6,5]:
  instance("sphere",p+Vector3(x,6,-1),Vector3(9,7.5,13),BREAD,false,Vector3(0,x*0.035,0))
  for score in [-3,0,3]:
   box(p+Vector3(x,9.7,float(score)-1),Vector3(5.1,0.3,0.8),LINEN,false,0.1)
 box(p+Vector3(9,6.6,8),Vector3(8,0.4,5),LINEN,false,0.18)

func service_station(p: Vector3) -> void:
 # Existing tray/plates occupy x128,z-4 and folded linen x146,z+4.
 # A tall ceramic utensil crock and spoons sit at its unused outer back corner.
 cyl(p+Vector3(10,4,-10),6.4,7.6,TEAL)
 cyl(p+Vector3(10,7.9,-10),5.6,0.25,DARK)
 instance("fine_ring",p+Vector3(10,8.0,-10),Vector3(6.4,0.2,6.4),BRASS,true)
 for j in range(3):
  var start := p+Vector3(9+float(j)*0.7,5.5,-10)
  var finish := p+Vector3(7+float(j)*2,18+float(j%2),-10)
  rod(start,finish,0.45,SILVER,true)
  instance("sphere",finish+Vector3(0,1.1,0),Vector3(1.7,3,0.6),SILVER,true,Vector3(0,0,-0.1+float(j)*0.12))

func unused_place(p: Vector3) -> void:
 # Only the unused 1450 table, never Vale's cup/body region.
 # Slim polished silver cutlery beside the existing gold rails, not a second set.
 var knife := p+Vector3(-30,0.65,-3)
 box(knife,Vector3(1.8,0.5,20),SILVER,true)
 box(knife+Vector3(0,0.15,13),Vector3(1.2,0.75,8),DARK)
 var fork_base := p+Vector3(29,0.7,-2)
 rod(fork_base+Vector3(0,0,11),fork_base+Vector3(0,0,-5),0.65,SILVER,true)
 box(fork_base+Vector3(0,0,-6.5),Vector3(2.8,0.5,4),SILVER,true)
 for tooth in [-1,0,1]:
  rod(fork_base+Vector3(tooth*0.9,0,-7),fork_base+Vector3(tooth*0.9,0,-11),0.35,SILVER,true)
