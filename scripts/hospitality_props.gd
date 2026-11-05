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
 # Its flat underside is Y-3; the plate's well is Y78.4.
 if not meshes.has("scored_bread"): meshes["scored_bread"] = PropMeshes.bread()
 instance("scored_bread",Vector3(-95,81.4,1050),Vector3.ONE,BREAD,false,Vector3(0,PI/2,0),4)
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
  rounded_box(p+Vector3(0,level,0),Vector3(44,1.8,62),BRASS,0.65,true)
  rounded_box(p+Vector3(0,level+1.0,0),Vector3(41,0.4,59),TEAL,0.19)
  welt(p+Vector3(0,level+1.3,0),42.5,60.5,2.0,0.18,BRASS,Vector3.ZERO,true)
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
  saucer(p+Vector3(-9,80.2,z),9.5)
  saucer(p+Vector3(-9,80.8,z),8)
  instance("fine_ring",p+Vector3(-9,81.9,z),Vector3(8,0.15,8),BRASS,true)
 # Water bottles are deliberately tall and unlabelled, unlike the clue bottle.
 bottle(p+Vector3(-12,26.6,-18),GLASS)
 bottle(p+Vector3(0,26.6,-18),Color("836546"))
 bread_basket(p+Vector3(4,26.6,12))

func teapot(p: Vector3) -> void:
 lathed("tea_foot",[Vector2(0.02,0),Vector2(4.5,0),Vector2(5.0,0.4),Vector2(5.1,1.1),Vector2(4.6,1.7),Vector2(3.8,2),Vector2(0.02,2)],p,BRASS,true)
 lathed("tea_body",[Vector2(0.02,1.5),Vector2(3.5,1.5),Vector2(4.8,2.2),Vector2(6,4),Vector2(6.8,6),Vector2(7,8.4),Vector2(6.8,10.5),Vector2(5.8,12.8),Vector2(4.5,14.3),Vector2(4.35,14.8),Vector2(4.1,14.9),Vector2(3.95,14.5),Vector2(4.2,13.9),Vector2(5.4,12.5),Vector2(6.4,10.4),Vector2(6.6,8.4),Vector2(6.3,6),Vector2(5.6,4),Vector2(4.4,2.6),Vector2(0.02,2.1)],p,CREAM)
 lathed("tea_lid",[Vector2(0.02,0),Vector2(4.45,0),Vector2(4.65,0.3),Vector2(4.4,0.65),Vector2(3.4,1.3),Vector2(1.6,1.8),Vector2(0.02,1.9)],p+Vector3(0,14.6,0),CREAM)
 instance("fine_ring",p+Vector3(0,14.95,0),Vector3(9.2,0.24,9.2),BRASS,true)
 lathed("tea_finial",[Vector2(0.02,0),Vector2(0.8,0),Vector2(0.55,0.8),Vector2(1.1,1.3),Vector2(1.2,1.8),Vector2(0.6,2.2),Vector2(0.02,2.2)],p+Vector3(0,16.2,0),BRASS,true)
 var spout: Array[Vector3] = []
 var radii := PackedFloat32Array()
 for j in range(33):
  var t := float(j)/32
  spout.append(Vector3(5.2+7.5*t,6.6+2.8*t+6.1*t*t,0))
  radii.append(lerpf(2.1,0.96,t))
 curved_tube("tea_spout",spout,radii,p,CREAM,false,true)
 var handle: Array[Vector3] = []
 for j in range(65):
  var a := float(j)*TAU/64
  handle.append(Vector3(-8.0+cos(a)*4.2,9+sin(a)*4.7,0))
 curved_tube("tea_handle",handle,PackedFloat32Array([0.5]),p,BRASS,true)
 for y in [5.2,12.8]:
  instance("sphere",p+Vector3(-5.0,y,0),Vector3(2.1,1.3,1.5),BRASS,true)

func sugar_bowl(p: Vector3) -> void:
 lathed("sugar_bowl",[Vector2(0.02,0),Vector2(2.7,0),Vector2(3.7,0.4),Vector2(3.7,0.8),Vector2(3.2,1.1),Vector2(3.8,2.2),Vector2(4.1,3.6),Vector2(3.6,5.6),Vector2(3.4,6),Vector2(0.02,6)],p,CREAM)
 lathed("sugar_lid",[Vector2(0.02,0),Vector2(3.6,0),Vector2(3.65,0.35),Vector2(2.6,0.9),Vector2(0.6,1.1),Vector2(0.02,1.1)],p+Vector3(0,6,0),CREAM)
 instance("sphere",p+Vector3(0,7.5,0),Vector3(1.8,1.3,1.8),BRASS,true)
 for side in [-1,1]:
  instance("ring",p+Vector3(side*4.0,3.5,0),Vector3(3.4,0.55,3.4),BRASS,true,Vector3(PI*0.5,0,0))

func bottle(p: Vector3, color: Color) -> void:
 lathed("water_bottle",[Vector2(0.02,0.15),Vector2(2.7,0.15),Vector2(3.3,0.4),Vector2(3.5,1),Vector2(3.5,15.8),Vector2(3.4,17),Vector2(2.9,18.4),Vector2(1.8,19.8),Vector2(1.55,20.6),Vector2(1.55,24.7),Vector2(1.75,25),Vector2(1.75,25.5),Vector2(1.3,25.5),Vector2(1.2,20.7),Vector2(2.6,18),Vector2(3.1,16),Vector2(3.1,0.9),Vector2(0.02,0.9)],p,color)
 lathed("bottle_stopper",[Vector2(0.02,0),Vector2(1.65,0),Vector2(1.8,0.2),Vector2(1.8,1.2),Vector2(1.6,1.5),Vector2(0.02,1.5)],p+Vector3(0,25.5,0),BRASS,true)
 instance("fine_ring",p+Vector3(0,24.7,0),Vector3(3.2,0.2,3.2),BRASS,true)

func bread_basket(p: Vector3) -> void:
 # Open woven basket, flared toward a rolled rim, with separate curved reeds.
 for row in range(8):
  var t := float(row)/7
  var ring_path: Array[Vector3] = []
  for j in range(65):
   var a := float(j)*TAU/64
   ring_path.append(Vector3(cos(a)*lerpf(10.5,12.5,t),1+6*t,sin(a)*lerpf(8,10,t)))
  curved_tube("basket_ring"+str(row),ring_path,PackedFloat32Array([0.28]),p,WICKER.lightened(0.035*float(row%2)))
 for j in range(36):
  var a := float(j)*TAU/36
  var path: Array[Vector3] = []
  for row in range(17):
   var t := float(row)/16
   var ripple := 0.16*sin(t*PI*8+j*PI)
   path.append(Vector3(cos(a)*(10.5+2*t+ripple),1+6*t,sin(a)*(8+2*t+ripple)))
  curved_tube("basket_reed"+str(j),path,PackedFloat32Array([0.19]),p,Color("b49367"))
 var rim: Array[Vector3] = []
 for j in range(65):
  var a := float(j)*TAU/64
  rim.append(Vector3(cos(a)*12.5,7.1,sin(a)*10))
 curved_tube("basket_rim",rim,PackedFloat32Array([0.52]),p,WICKER)
 linen(p+Vector3(0,1.9,0),22,17,0.6,LINEN)
 linen(p+Vector3(7,5.1,7.9),9,6,0.5,LINEN,Vector3(0.65,0.18,0))
 for x in [-6,5]:
  if not meshes.has("scored_bread"): meshes["scored_bread"] = PropMeshes.bread()
  instance("scored_bread",p+Vector3(x,6,-1),Vector3.ONE,BREAD,false,Vector3(0,x*0.035,0),4)

func service_station(p: Vector3) -> void:
 # Existing tray/plates occupy x128,z-4 and folded linen x146,z+4.
 # A tall ceramic utensil crock and spoons sit at its unused outer back corner.
 lathed("utensil_crock",[Vector2(0.02,0),Vector2(2.8,0),Vector2(3.1,0.3),Vector2(3.2,1.3),Vector2(3.25,7.5),Vector2(3.1,8),Vector2(2.7,8),Vector2(2.55,7.5),Vector2(2.5,0.7),Vector2(0.02,0.7)],p+Vector3(10,0,-10),TEAL)
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
 rounded_box(knife,Vector3(1.8,0.5,20),SILVER,0.24,true)
 rounded_box(knife+Vector3(0,0.15,13),Vector3(1.2,0.75,8),DARK,0.36)
 var fork_base := p+Vector3(29,0.7,-2)
 rod(fork_base+Vector3(0,0,11),fork_base+Vector3(0,0,-5),0.65,SILVER,true)
 rounded_box(fork_base+Vector3(0,0,-6.5),Vector3(2.8,0.5,4),SILVER,0.24,true)
 for tooth in [-1,0,1]:
  rod(fork_base+Vector3(tooth*0.9,0,-7),fork_base+Vector3(tooth*0.9,0,-11),0.35,SILVER,true)
