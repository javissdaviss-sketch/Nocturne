extends "res://scripts/lived_in_details.gd"
## Recognizable working-garden props, kept on the outer benches and floor margins.

func build() -> void:
 watering_can(Vector3(134,50.2,2177))
 nursery_tray(Vector3(-134,50.2,1905))
 propagation_rack(Vector3(143,50.2,2268))
 slatted_crate(Vector3(-133,0.3,2421))
 # Coiled hose and brass tap stay on the lower outer panel, not in the aisle.
 for turn in range(4):
  instance("ring",Vector3(-165,62,2120),Vector3(29-turn*4.4,1.3,29-turn*4.4),Color("43534a"),false,Vector3(0,0,PI*0.5))
 cyl(Vector3(-164,77,2120),3.0,5.0,BRASS,true)
 rod(Vector3(-164,75,2120),Vector3(-158,75,2120),1.8,BRASS,true)
 box(Vector3(-162,68,2120),Vector3(1,1,30),BRASS,true)
 finish_batches()

func watering_can(p: Vector3) -> void:
 cyl(p+Vector3(0,9,0),17,18,TEAL)
 cyl(p+Vector3(0,18.2,0),17.7,1.0,BRASS,true)
 cyl(p+Vector3(0,18.8,0),9,0.5,DARK)
 # A tall arched carrying handle above the broad can, and a rising spout.
 instance("ring",p+Vector3(1,19,0),Vector3(18,1.8,18),BRASS,true,Vector3(PI*0.5,0,0))
 rod(p+Vector3(-7,5,0),p+Vector3(-22,16,0),2.6,TEAL)
 instance("sphere",p+Vector3(-23,17,0),Vector3(5.0,3.0,5.0),BRASS,true)
 for j in range(5):
  var a := float(j)*TAU/5
  instance("sphere",p+Vector3(-24.3,17+sin(a)*1.4,cos(a)*1.4),Vector3(0.4,0.6,0.6),DARK)

func nursery_tray(p: Vector3) -> void:
 box(p+Vector3(0,1,0),Vector3(28,2,35),Color("70523c"))
 for side in [-1,1]:
  box(p+Vector3(side*14,3,0),Vector3(1.2,5,36),Color("917251"))
  box(p+Vector3(0,3,side*17.5),Vector3(28,5,1.2),Color("917251"))
 for row in range(3):
  for column in range(2):
   var pot := p+Vector3(-6+column*12,2,-11+row*11)
   cyl(pot+Vector3(0,3,0),8,6,Color("a17252"))
   cyl(pot+Vector3(0,6.1,0),7,0.6,Color("34382b"))
   var stem := pot+Vector3(0,7,0)
   rod(stem,stem+Vector3(0,8+row,0),0.22,Color("5c7950"))
   for side in [-1,1]:
    instance("sphere",stem+Vector3(side*2.0,5.0,0),Vector3(5,0.5,2.3),Color("6a8c55"),false,Vector3(0,0,side*0.3))

func propagation_rack(p: Vector3) -> void:
 # A two-tier wire rack standing on the broad planter, away from the ledger.
 for x in [-11,11]:
  for z in [-19,19]: rod(p+Vector3(x,0,z),p+Vector3(x,52,z),1.0,BRASS,true)
 for height in [5,30]:
  for x in [-11,11]: rod(p+Vector3(x,height,-19),p+Vector3(x,height,19),0.8,BRASS,true)
  for z in [-19,19]: rod(p+Vector3(-11,height,z),p+Vector3(11,height,z),0.8,BRASS,true)
  for z in range(-16,17,8): rod(p+Vector3(-11,height,z),p+Vector3(11,height,z),0.45,BRASS,true)
  for z in [-11,9]:
   var pot := p+Vector3(0,height+0.5,z)
   cyl(pot+Vector3(0,4,0),12,8,Color("8f6951"))
   cyl(pot+Vector3(0,8.1,0),10.8,0.4,Color("303b2b"))
   rod(pot+Vector3(0,8,0),pot+Vector3(0,19,0),0.25,Color("5b8058"))
   for side in [-1,1]: instance("sphere",pot+Vector3(side*2,14,0),Vector3(5.5,0.5,2.0),Color("5f8655"),false,Vector3(0,0,side*0.35))

func slatted_crate(p: Vector3) -> void:
 var wood := Color("937453")
 box(p+Vector3(0,1.2,0),Vector3(32,2.4,36),wood)
 for x in [-15,15]:
  for z in [-17,17]:
   box(p+Vector3(x,13,z),Vector3(2.0,26,2.0),Color("604934"))
 for height in [6,14,22]:
  for side in [-1,1]:
   box(p+Vector3(side*15.5,height,0),Vector3(1.4,5.0,35),wood)
   box(p+Vector3(0,height,side*17.5),Vector3(32,5.0,1.4),wood)
 for x in [-7,7]:
  cyl(p+Vector3(x,9,0),11,15,Color("a57e5f"))
  cyl(p+Vector3(x,16.8,0),9.8,0.4,Color("403d2e"))
 # World compiles each visible slat, preserving gaps and the perchable rim.
