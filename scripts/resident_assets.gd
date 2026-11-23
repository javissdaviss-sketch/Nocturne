extends RefCounted
## Sculpted residents, in centimetres: continuous tailored clothing and facial anatomy.
## Original positions and conversation metadata are owned by world.gd.
const Crafted = preload("res://scripts/crafted_geometry.gd")
const SKIN := Color("b99377")
const BRASS := Color("b5a077")
const HEAD_PROFILE := [Vector4(139,0.02,0.02,-1),Vector4(140,4.2,5.7,-1.7),Vector4(142,7.2,7.3,-1),Vector4(146,9.5,8.8,-0.6),Vector4(151,10.8,9.8,-0.7),Vector4(156,10.6,9.6,-0.3),Vector4(161,10.2,9.4,0),Vector4(166,8.3,7.7,0.2),Vector4(169,4.6,4.5,0.2),Vector4(170,0.02,0.02,0.2)]
static var materials: Dictionary = {}
static var mesh_cache: Dictionary = {}
const PORTRAIT:Dictionary={
 "engineer":Vector3(0.90,0.865,0.885),
 "steward":Vector3(0.81,0.898,0.855),
 "botanist":Vector3(0.895,0.86,0.893),
}

static func material(color: Color, roughness: float = 0.75, metal: float = 0.0) -> StandardMaterial3D:
 var key := str(color)+str(roughness)+str(metal)
 if not materials.has(key):
  var m := StandardMaterial3D.new()
  m.albedo_color = color
  m.roughness = roughness
  m.metallic = metal
  materials[key] = m
 return materials[key]

static func add(parent: Node3D, mesh: Mesh, p: Vector3, color: Color, roughness: float = 0.75, metal: float = 0.0) -> MeshInstance3D:
 var node := MeshInstance3D.new()
 node.mesh = mesh
 node.material_override = material(color,roughness,metal)
 parent.add_child(node)
 node.position = p
 return node

static func build(_w: Node3D, parent: Node3D, p: Vector3, coat: Color, hair: Color, role: String = "") -> Node3D:
 var resident := Node3D.new()
 resident.name = "TailoredResident"
 parent.add_child(resident)
 resident.position = p
 resident.set_meta("resident_tailoring",role)
 var trousers := Color("283036")
 var shoes := Color("292522")
 # Pants follow a shaped calf/knee/thigh profile, with subtle cloth folds.
 for side in [-1,1]:
  var leg: MeshInstance3D = add(resident,loft([
   Vector4(7,4.2,4.4,0),Vector4(10,4.8,5,0),Vector4(14,5.2,5.2,0),
   Vector4(23,5.4,5.6,0),Vector4(37,6,5.9,-0.4),Vector4(44,6.2,6.8,-0.8),
   Vector4(53,7,7,0),Vector4(66,8,8,0.3),Vector4(78,8.2,8.6,0.5),Vector4(81,0.02,0.02,0)
  ],0.18),Vector3(side*9,0,0),trousers)
  leg.rotation.z = side*0.018
  add(resident,loft([Vector4(0.4,0.02,0.02,-5),Vector4(0.6,6.4,11.7,-5),Vector4(1.1,7.3,13,-5),Vector4(2.7,7.4,13.2,-5),Vector4(3.6,7.1,12.7,-5),Vector4(3.8,0.02,0.02,-5)]),Vector3(side*9,0,0),Color("171d1e"),0.58)
  add(resident,loft([Vector4(3.5,6.8,12.5,-5),Vector4(5.4,6.9,12.8,-5),Vector4(7.3,6.5,11.8,-4.8),Vector4(9.6,5.7,9.5,-3),Vector4(12,4.8,6,-0.4),Vector4(14.1,4.3,4.6,0),Vector4(14.6,0.02,0.02,0)]),Vector3(side*9,0,0),shoes,0.35)
  for row in range(4):
   var y := 8.9+row*0.9
   var z := -9.8+row*1.2
   add(resident,Crafted.tube([Vector3(side*9-3,y,z),Vector3(side*9,y+0.3,z-0.5),Vector3(side*9+3,y,z)], [0.16,0.16,0.16],12),Vector3.ZERO,Color("756b58"))
 # The coat has a tailored waist, shaped shoulder and flared hem, not a cylinder.
 var drape:=add(resident,loft(tailored_cut(role),0.24),Vector3.ZERO,coat)
 drape.name="FittedOuterCoat"
 add(resident,loft([Vector4(131,4.5,4.7,-0.8),Vector4(142,4.5,4.6,-0.8),Vector4(148,4,4.1,-0.8)]),Vector3.ZERO,SKIN)
 # Shirt, rolled collar and lapels sit on the tailored chest surface.
 var shirt_rows := [Vector3(133,6.5,-10.1),Vector3(130,6,-12.5),Vector3(126,5.4,-14.3),Vector3(122,4.5,-15.2),Vector3(117,3.6,-15.5)]
 for i in range(shirt_rows.size()-1):
  var a: Vector3 = shirt_rows[i]
  var b: Vector3 = shirt_rows[i+1]
  panel(resident,[Vector3(-a.y,a.x,a.z),Vector3(a.y,a.x,a.z),Vector3(b.y,b.x,b.z),Vector3(-b.y,b.x,b.z)],Color("d7d0b9"),0.2)
 for side in [-1,1]:
  panel(resident,[Vector3(side*1,135,-7.5),Vector3(side*8.5,132,-10),Vector3(side*4.9,125,-13.5)],Color("e3dbc5"),0.6)
  var fold:float={"engineer":0.32,"steward":0.90,"botanist":0.55}.get(role,0.72)
  var lower:float={"engineer":119.0,"steward":112.5,"botanist":116.0}.get(role,115.0)
  var width:float={"engineer":12.7,"steward":16.8,"botanist":14.5}.get(role,15.0)
  panel(resident,[Vector3(side*8.8,132,-10),Vector3(side*width,126,-11.3),
   Vector3(side*(3.8+fold*2.5),lower,-16),Vector3(side*2.8,lower+4.0,-16)],coat.lightened(0.065),0.8)
  # Inset pocket flap with stitched upper seam, following the curved torso.
  panel(resident,[Vector3(side*6.5,103,-14),Vector3(side*14.3,103,-10),Vector3(side*14,98,-10.4),Vector3(side*7,98,-14.4)],coat.darkened(0.09),0.45)
  add(resident,Crafted.tube([Vector3(side*6.8,102.7,-14.5),Vector3(side*10.4,102.7,-13),Vector3(side*14,102.7,-10.6)],[0.11,0.11,0.11],10),Vector3.ZERO,coat.lightened(0.17))
  sleeve(resident,side,coat)
  hand(resident,side)
 wardrobe_hardware(resident,role,coat)
 panel(resident,[Vector3(-14,118,-11.8),Vector3(-7,118,-14.5),Vector3(-7,116.3,-14.8),Vector3(-14,116.3,-12)],coat.darkened(0.15),0.5)
 var head := Node3D.new()
 head.name = "SculptedHead"
 resident.add_child(head)
 head.scale = PORTRAIT.get(role,Vector3.ONE*0.9)
 # Root the neck at the original lower contact. All of the ears, eyelids,
 # jaw and hair follow this one real optical/physical portrait transform.
 head.position.y = 142.6-139.0*head.scale.y
 face(head,hair,role)
 cloth_materials(resident,coat)
 return resident

static func tailored_cut(role:String)->Array[Vector4]:
 var profile:Array[Vector4]=[
  Vector4(65,0.02,0.02,0),Vector4(66,20.2,16.3,0),Vector4(69,20.5,16.5,0),
  Vector4(80,20,16.2,0),Vector4(96,18.8,14.8,0),Vector4(105,18.4,14,0),
  Vector4(116,21,15,0),Vector4(124,22.6,14.2,0),Vector4(130,22.8,11.8,0),
  Vector4(133,18,9.4,0),Vector4(136,7.5,6.5,-0.1),Vector4(137,0.02,0.02,0)]
 for i in range(profile.size()):
  var line:=profile[i]
  var skirt:=1.0-smoothstep(70.0,104.0,line.x)
  var mid:=1.0-smoothstep(7.0,23.0,absf(line.x-94.0))
  match role:
   "engineer":
    line.x+=8.0*skirt
    line.y*=1.0-0.15*skirt
   "steward":
    line.y*=1.0-0.13*mid-0.08*skirt
    line.x+=3.0*skirt
   "botanist":
    line.y*=1.0-0.055*mid
    line.x+=1.0*skirt
  profile[i]=line
 return profile

static func wardrobe_hardware(resident:Node3D,role:String,coat:Color)->void:
 if role=="engineer":
  # Matte centre closure on the shorter work jacket; no gold watch chain.
  var zip:Array[Vector3]=[Vector3(0,79.5,-16.1),Vector3(0,89,-15.6),
   Vector3(0,100,-14.8),Vector3(0,110,-14.7),Vector3(0,116,-15.2)]
  var closure:=add(resident,Crafted.tube(zip,[0.37,0.34,0.32,0.35,0.32],12),
   Vector3.ZERO,coat.darkened(0.28),0.84)
  closure.name="MatteWorkJacketClosure"
  add(resident,Crafted.rounded_box(Vector3(1.0,2.8,0.35),0.14),Vector3(0,111,-15.1),Color("6b7977"),0.42,0.4)
  return
 var row:Array[Vector2]=[Vector2(88,-15.9),Vector2(99,-14.8),Vector2(110,-14.9),Vector2(120,-15.0)]
 var hue:=BRASS
 if role=="botanist":
  row=[Vector2(92,-15.4),Vector2(112,-15.1)]
  hue=Color("79644e")
 for placement in row:
  var button := add(resident,ellipsoid(Vector3(1.65,1.65,0.65)),Vector3(2.5,placement.x,placement.y),hue,
   0.60 if role=="botanist" else 0.32,0.24 if role=="botanist" else 0.72)
  button.rotation.x = 0.12
 if role!="botanist":
  # The formal service uniform keeps the original fine watch chain.
  add(resident,Crafted.tube([Vector3(5.5,107,-15.5),Vector3(8,102,-15.2),Vector3(13,102,-12),Vector3(14.5,108,-11)],[0.18,0.18,0.18,0.18],12),Vector3.ZERO,BRASS,0.35,0.65)

static func cloth_materials(parent: Node, coat: Color) -> void:
 var cloth_colors := [coat,coat.lightened(0.065),coat.darkened(0.09),coat.darkened(0.14),coat.darkened(0.15),coat.lightened(0.17),Color("283036"),Color("d7d0b9"),Color("e3dbc5")]
 for node in parent.get_children():
  if node is MeshInstance3D and node.material_override is StandardMaterial3D:
   var color: Color = node.material_override.albedo_color
   if color in cloth_colors:
    var key := "cloth"+str(color)
    if not materials.has(key):
     materials[key] = preload("res://scripts/material_library.gd").make(6,color)
    node.material_override = materials[key]
  cloth_materials(node,coat)

static func sleeve(parent: Node3D, side: int, coat: Color) -> void:
 var path: Array[Vector3] = []
 var radii: Array[float] = []
 var a := Vector3(side*15,123,0)
 var b := Vector3(side*28,124,-1)
 var c := Vector3(side*28,91,-5)
 var d := Vector3(side*18,80,-15)
 for i in range(29):
  var t := float(i)/28
  path.append(pow(1-t,3)*a+3*pow(1-t,2)*t*b+3*(1-t)*t*t*c+t*t*t*d)
  radii.append(lerpf(5.9,4.3,t)+sin(t*62)*0.35*exp(-pow((t-0.65)/0.20,2))+sin(t*115)*0.12*t*t)
 add(parent,Crafted.tube(path,radii,40),Vector3.ZERO,coat)
 var cuff_start := d+(c-d).normalized()*2.3
 add(parent,Crafted.tube([cuff_start,d,d+(d-c).normalized()*0.7],[4.45,4.5,4.35],40),Vector3.ZERO,coat.darkened(0.14))
 add(parent,ellipsoid(Vector3(1.4,1.4,0.6)),d+Vector3(0,0,-4.7),BRASS,0.3,0.65)

static func hand(parent: Node3D, side: int) -> void:
 var origin := Vector3(side*18,69,-15)
 add(parent,loft([Vector4(0,2.9,1.9,-0.6),Vector4(2,3.3,2.2,-0.8),Vector4(6,3.2,2.3,-0.4),Vector4(9,2.6,2,0),Vector4(12,2.3,1.9,0)]),origin,SKIN)
 for finger in range(4):
  var x := (finger-1.5)*1.6
  var length := 7.8-absf(finger-1.3)*1.3
  var path: Array[Vector3] = []
  var radii: Array[float] = []
  for i in range(9):
   var t := float(i)/8
   path.append(origin+Vector3(x,-t*length,-0.5+sin(t*PI)*0.9))
   radii.append(lerpf(0.85,0.62,t) if i<8 else 0.10)
  add(parent,Crafted.tube(path,radii,20),Vector3.ZERO,SKIN)
  add(parent,ellipsoid(Vector3(1.0,1.6,0.18)),origin+Vector3(x,-length+1.1,-0.7),Color("c4a58e"),0.5)
 add(parent,Crafted.tube([origin+Vector3(side*2.4,7,-0.3),origin+Vector3(side*4.5,4,-1.3),origin+Vector3(side*4.2,0,-1.4)],[1.2,1,0.3],24),Vector3.ZERO,SKIN)

static func face(parent: Node3D, hair: Color, role:String="") -> void:
 add(parent,sculpted_head(),Vector3.ZERO,SKIN,0.61)
 # Nose and brow are sculpted directly into the head surface, without a seam.
 for side in [-1,1]:
  add(parent,ellipsoid(Vector3(0.55,0.25,0.22)),Vector3(side*0.95,151.2,-12.08),Color("765643"))
  add(parent,ellipsoid(Vector3(2.4,5.4,2.9)),Vector3(side*10.5,152.5,0),SKIN)
  add(parent,ellipsoid(Vector3(0.75,3.4,1.8)),Vector3(side*11.7,152.7,-0.2),Color("97735e"))
  var x: float = side*4.2
  var eye := Node3D.new()
  eye.name = "EyeOptics"
  parent.add_child(eye)
  eye.position = Vector3(x,155.8,-8.8)
  eye.rotation.y = -side*0.35
  add(eye,ellipsoid(Vector3(4.2,1.6,1.05)),Vector3.ZERO,Color("cfcec3"),0.34)
  add(eye,ellipsoid(Vector3(1.35,1.35,0.3)),Vector3(0,0,-0.56),Color("394c45"),0.24)
  add(eye,ellipsoid(Vector3(0.5,0.58,0.18)),Vector3(0,0,-0.74),Color("152322"),0.2)
  add(eye,ellipsoid(Vector3(0.18,0.18,0.12)),Vector3(-0.22,0.25,-0.85),Color("ece8db"),0.12)
  var upper: Array[Vector3] = []
  var lower: Array[Vector3] = []
  var lid_radii: Array[float] = []
  for i in range(17):
   var t := float(i)/16
   var px := lerpf(-2.15,2.15,t)
   upper.append(Vector3(px,sin(t*PI)*0.88,-sin(t*PI)*0.55))
   lower.append(Vector3(px,-sin(t*PI)*0.75,-sin(t*PI)*0.49))
   lid_radii.append(0.17+sin(t*PI)*0.10)
  add(eye,Crafted.tube(upper,lid_radii,16),Vector3.ZERO,SKIN.darkened(0.035),0.67)
  add(eye,Crafted.tube(lower,lid_radii,16),Vector3.ZERO,SKIN,0.67)
  add(parent,Crafted.tube([Vector3(x-2.6,158.2,-8.9),Vector3(x-0.3,159,-9.3),Vector3(x+2.4,158.5,-8.7)],[0.35,0.48,0.22],18),Vector3.ZERO,hair)
 # Upper and lower lips are curved forms with a narrow mouth line.
 var upper_lip: Array[Vector3] = []
 var lower_lip: Array[Vector3] = []
 var lip_radii: Array[float] = []
 for i in range(25):
  var t := float(i)/24
  var x := lerpf(-2.8,2.8,t)
  var curve := sin(t*PI)
  upper_lip.append(Vector3(x,147.7+curve*0.38-0.15*exp(-x*x/0.3),-9.1-curve*0.95))
  lower_lip.append(Vector3(x,147.5-curve*0.32,-9.1-curve*1.0))
  lip_radii.append(0.025+curve*0.21)
 add(parent,Crafted.tube(upper_lip,lip_radii,18),Vector3.ZERO,Color("9e7864"),0.65)
 add(parent,Crafted.tube(lower_lip,lip_radii,18),Vector3.ZERO,Color("b28a72"),0.65)
 var cap:=add(parent,hair_cap(role),Vector3.ZERO,hair,0.86)
 cap.name="ShapedHairCap"
 if role=="botanist": reading_frames(parent)
 # Combed locks follow the scalp surface and converge toward an offset crown.
 for lock in range(15):
  var path: Array[Vector3] = []
  var radii: Array[float] = []
  for i in range(14):
   var t := float(i)/14*0.94
   var sweep:float={"engineer":0.055,"steward":0.51,"botanist":0.28}.get(role,0.22)
   var a := PI+(lock-7)*0.19+sin(t*PI)*sweep
   var point: Vector3 = hair_point(t,a,role)
   var normal := Vector3(point.x,(point.y-156)*1.1,point.z-0.6).normalized()
   path.append(point+normal*0.10)
   radii.append(0.025+sin(float(i)*PI/14)*0.075)
  add(parent,Crafted.tube(path,radii,12),Vector3.ZERO,hair.lightened(0.045),0.8)

static func reading_frames(head:Node3D)->void:
 # Thin rolled frames only, with a clear sight of the actual eyes. The
 # bent arms meet the original ears rather than floating before the face.
 var outfit:=Node3D.new()
 outfit.name="FittedReadingFrames"
 head.add_child(outfit)
 for side in [-1.,1.]:
  var rim:Array[Vector3]=[]
  var radius:Array[float]=[]
  for i in range(37):
   var a:=float(i)*TAU/36.0
   var x:float=side*4.2+cos(a)*2.94
   rim.append(Vector3(x,155.8+sin(a)*2.16,-10.24+0.045*absf(x)))
   radius.append(0.17+0.015*sin(a))
  add(outfit,Crafted.tube(rim,radius,9),Vector3.ZERO,Color("7a6f57"),0.42,0.68)
  var arm:Array[Vector3]=[Vector3(side*7.05,155.93,-9.93),Vector3(side*8.65,155.9,-8.2),
   Vector3(side*9.78,155.74,-5.6),Vector3(side*10.82,154.62,-0.65)]
  add(outfit,Crafted.tube(arm,[0.21,0.18,0.18,0.17],9),Vector3.ZERO,Color("5d5649"),0.5,0.42)
 add(outfit,Crafted.tube([Vector3(-1.35,156.05,-10.18),Vector3(0,156.40,-10.55),
  Vector3(1.35,156.05,-10.18)],[0.16,0.18,0.16],9),Vector3.ZERO,Color("7a6f57"),0.42,0.68)

static func panel(parent: Node3D, points: Array[Vector3], color: Color, depth: float) -> void:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 # Panels have thickness, with front-oriented faces independent of side mirroring.
 var front := points.duplicate()
 if (front[1]-front[0]).cross(front[2]-front[0]).z < 0: front.reverse()
 for i in range(1,front.size()-1):
  for index in [0,i,i+1]:
   surface.set_normal(Vector3.FORWARD)
   surface.add_vertex(front[index]+Vector3(0,0,-depth))
 for i in range(front.size()):
  var a: Vector3 = front[i]
  var b: Vector3 = front[(i+1)%front.size()]
  var offset := Vector3(0,0,-depth)
  var normal := (b-a).cross(offset).normalized()
  for point in [a,b,a+offset,b,b+offset,a+offset]:
   surface.set_normal(normal)
   surface.add_vertex(point)
 add(parent,surface.commit(),Vector3.ZERO,color)

static func loft(profile: Array[Vector4], wrinkle: float = 0.0, sides: int = 48) -> ArrayMesh:
 var key := str(profile)+str(wrinkle)+str(sides)
 if mesh_cache.has(key): return mesh_cache[key]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(profile.size()-1):
  for j in range(sides):
   for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var i: int = row+corner.y
    var a := float(j+corner.x)*TAU/sides
    var ring := profile[i]
    var previous := profile[maxi(0,i-1)]
    var next := profile[mini(profile.size()-1,i+1)]
    var slope := ((next.y+next.z)-(previous.y+previous.z))*0.5/maxf(0.01,next.x-previous.x)
    var fold := sin(a*9+ring.x*0.23)*wrinkle
    surface.set_normal(Vector3(sin(a)/maxf(ring.y,1)*12,-slope,cos(a)/maxf(ring.z,1)*12).normalized())
    surface.set_uv(Vector2(float(j+corner.x)/sides,ring.x/30))
    surface.add_vertex(Vector3(sin(a)*(ring.y+fold),ring.x,cos(a)*(ring.z+fold)+ring.w))
 var mesh := surface.commit()
 mesh_cache[key] = mesh
 return mesh

static func ellipsoid(size: Vector3) -> ArrayMesh:
 var profile: Array[Vector4] = []
 for i in range(25):
  var angle := PI*float(i)/24
  profile.append(Vector4(-cos(angle)*size.y*0.5,maxf(0.001,sin(angle))*size.x*0.5,maxf(0.001,sin(angle))*size.z*0.5,0))
 var mesh := loft(profile,0,40)
 mesh.set_meta("solid_geometry_convex",true)
 return mesh

static func hair_cap(role:String="") -> ArrayMesh:
 var key:="hair_cap_"+role
 if mesh_cache.has(key): return mesh_cache[key]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(16):
  for j in range(64):
   for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var t := float(row+corner.y)/16
    var a := float(j+corner.x)*TAU/64
    var point: Vector3 = hair_point(t,a,role)
    surface.set_normal(Vector3(point.x,(point.y-156)*1.1,point.z-0.6).normalized())
    surface.set_uv(Vector2(float(j+corner.x)/64,t))
    surface.add_vertex(point)
 var mesh := surface.commit()
 mesh_cache[key] = mesh
 return mesh

static func hair_point(t: float, a: float, role:String="") -> Vector3:
 var front:=maxf(0.0,-cos(a))
 var hairline := 155.0+8.0*front
 match role:
  "engineer": hairline+=3.8*(1.0-front)+0.22*front
  "steward": hairline-=2.5*maxf(0.0,sin(a))*smoothstep(0.05,0.7,front)+0.7*sin(a)
  "botanist": hairline+=1.4+0.7*cos(a*2.0)
 var y := lerpf(hairline,170.0,t)
 var scalp := head_point(y,a)
 var wave := sin(a*19+t*8)*0.08*(1-t)
 return Vector3(scalp.x*1.025+sin(a)*wave,y+0.22,(scalp.z-0.2)*1.025+0.2+cos(a)*wave)

static func head_point(y: float, a: float) -> Vector3:
 var ring: Vector4 = HEAD_PROFILE[0]
 for i in range(HEAD_PROFILE.size()-1):
  var left: Vector4 = HEAD_PROFILE[i]
  var right: Vector4 = HEAD_PROFILE[i+1]
  if y >= left.x and y <= right.x:
   var t := (y-left.x)/(right.x-left.x)
   var before: Vector4 = HEAD_PROFILE[maxi(0,i-1)]
   var after: Vector4 = HEAD_PROFILE[mini(HEAD_PROFILE.size()-1,i+2)]
   ring = 0.5*((2.0*left)+(-before+right)*t+(2.0*before-5.0*left+4.0*right-after)*t*t+(-before+3.0*left-3.0*right+after)*t*t*t)
   ring.y = maxf(0.02,ring.y)
   ring.z = maxf(0.02,ring.z)
   break
 var x := sin(a)*ring.y
 var z := cos(a)*ring.z+ring.w
 var front := smoothstep(0.2,0.8,-cos(a))
 var nose := exp(-x*x/0.9-pow(y-155.7,2)/10)*0.85+exp(-x*x/2.6-pow(y-152.1,2)/1.8)*2.0
 nose += exp(-pow(absf(x)-1.2,2)/0.4-pow(y-151.3,2)/0.6)*0.45
 var socket := exp(-pow(absf(x)-4.2,2)/5.5-pow(y-155.8,2)/2.8)*0.72
 var cheek := exp(-pow(absf(x)-5.7,2)/5-pow(y-151.2,2)/6)*0.42
 var brow := exp(-pow(absf(x)-4.2,2)/5-pow(y-158.5,2)/1.4)*0.36
 z += front*(socket-nose-cheek-brow)
 return Vector3(x,y,z)

static func sculpted_head() -> ArrayMesh:
 if mesh_cache.has("sculpted_head"): return mesh_cache.sculpted_head
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(62):
  for column in range(128):
   for index in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var y := 139+float(row+index.y)*0.5
    var a := float(column+index.x)*TAU/128
    var point := head_point(y,a)
    var vertical := head_point(minf(170,y+0.05),a)-head_point(maxf(139,y-0.05),a)
    var around := head_point(y,a+0.002)-head_point(y,a-0.002)
    surface.set_normal(around.cross(vertical).normalized())
    surface.set_uv(Vector2(float(column+index.x)/128,(y-139)/31))
    surface.add_vertex(point)
 var mesh := surface.commit()
 mesh_cache.sculpted_head = mesh
 return mesh
