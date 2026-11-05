extends RefCounted
## Cabinetmaker's assets, centimetres. Frames, panels, mouldings and hardware are
## separate physical forms. No runtime downloads or texture-only handles.
const TIMBER := Color("583c2d")
const PANEL := Color("493327")
const END_GRAIN := Color("35271f")
const BRASS := Color("b99a62")
const DARK := Color("172e2c")
const CYAN := Color("65aca5")
const Finishes = preload("res://scripts/cabinet_finishes.gd")
const Profiles = preload("res://scripts/crafted_geometry.gd")

static func wardrobe(w: Node3D, parent: Node3D, p: Vector3, size: Vector3 = Vector3(95,224,48)) -> Node3D:
 var asset := Node3D.new()
 asset.name = "CabinetmakerWardrobe"
 parent.add_child(asset)
 asset.position = p
 asset.scale = size/Vector3(95,224,48)
 # Carcass is recessed behind the face frame, crown and panelled sides.
 _wood(w,asset,Vector3(0,113,1.5),Vector3(84,194,42),END_GRAIN,1.0)
 for x in [-38,38]:
  for z in [-17,17]: _turned_foot(w,asset,Vector3(x,0,z),12,4.5)
 for layer in [[13,95,5,48],[17,93,3,46],[20,89,3,44]]:
  _wood(w,asset,Vector3(0,layer[0],0),Vector3(layer[1],layer[2],layer[3]),TIMBER,0.7)
 for x in [-43,43]:
  _wood(w,asset,Vector3(x,112,0),Vector3(7,184,44),TIMBER,0.8)
  for z in [-13,13]:
   _rod(w,asset,Vector3(x+signf(x)*3.55,33,z),Vector3(x+signf(x)*3.55,190,z),0.45,BRASS)
  for y in [32,191]:
   _rod(w,asset,Vector3(x+signf(x)*3.55,y,-13),Vector3(x+signf(x)*3.55,y,13),0.45,BRASS)
 # Rear frame and recessed boards are built even where the train wall conceals
 # them, so the reusable asset remains credible from every authoring angle.
 for x in [-39,0,39]:
  _wood(w,asset,Vector3(x,111,22.6),Vector3(3.5,179,2.3),TIMBER,0.35)
 for y in [24,111,198]:
  _wood(w,asset,Vector3(0,y,22.6),Vector3(80,3.5,2.3),TIMBER,0.35)
 for x in [-19.5,19.5]:
  for y in [67.5,154.5]:
   _wood(w,asset,Vector3(x,y,22.4),Vector3(34.5,81.5,0.7),PANEL,0.2)
 # Recessed central door leaves with shaped, raised panels and open vent grilles.
 for side in [-1,1]:
  var dx := float(side)*20.5
  _wood(w,asset,Vector3(dx,112,-20.2),Vector3(39.5,179,3.2),TIMBER,0.65)
  var panel_points := _arch_outline(28,77,9)
  var raised: MeshInstance3D = w.mesh_obj(asset,_extrude(panel_points,1.1),Vector3(dx,73,-22.2),PANEL)
  raised.material_override = Finishes.timber(PANEL)
  _outline(w,asset,panel_points,Vector3(dx,73,-23),0.42,BRASS)
  # Fine inner moulding follows the arched shoulder instead of a rectangular decal.
  _outline(w,asset,_arch_outline(24,71,8),Vector3(dx,76,-23.2),0.28,TIMBER)
  _vent(w,asset,Vector3(dx,179,-22.2),Vector2(27,23))
  _wood(w,asset,Vector3(dx,47,-22.0),Vector3(28,30,0.9),PANEL,0.35)
  _rect_frame(w,asset,Vector3(dx,47,-22.7),Vector2(27,29),0.45,BRASS)
  _pull(w,asset,Vector3(side*5.7,109,-22.0),14,true)
  _escutcheon(w,asset,Vector3(side*5.7,94,-22.6))
  for y in [39,113,188]: _hinge(w,asset,Vector3(side*40.0,y,-22.2),side)
  for y in [26,198]:
   _wood(w,asset,Vector3(dx,y,-21.1),Vector3(39.5,3,4),TIMBER,0.5)
 _rod(w,asset,Vector3(0,24,-22),Vector3(0,200,-22),0.32,BRASS)
 # Bowed crown: a solid curved fascia with layered ogee-like trim.
 var crown := _arch_outline(95,9,15)
 var crown_mesh: MeshInstance3D = w.mesh_obj(asset,_extrude(crown,46),Vector3(0,200,0),TIMBER)
 crown_mesh.material_override = Finishes.timber(TIMBER)
 var cornice_band := PackedVector2Array()
 for i in range(41):
  var x := -46.5+float(i)*93/40
  cornice_band.append(Vector2(x,208.3+15*cos(x/47.5*PI*0.5)))
 for i in range(40,-1,-1):
  var x := -46.5+float(i)*93/40
  cornice_band.append(Vector2(x,205.4+15*cos(x/47.5*PI*0.5)))
 var cornice: MeshInstance3D = w.mesh_obj(asset,_extrude(cornice_band,1.5),Vector3(0,0,-23.1),TIMBER)
 cornice.material_override = Finishes.timber(TIMBER)
 for inset in [0.0,3.0,6.0]:
  var path: Array[Vector3] = []
  for i in range(41):
   var x := -46.5+float(i)*93/40
   var y: float = 208.3+15*cos(x/47.5*PI*0.5)-inset
   path.append(Vector3(x,y,-23.35+inset*0.16))
  _path(w,asset,path,0.62 if inset == 0 else 0.37,BRASS if inset == 3 else TIMBER)
 _wood(w,asset,Vector3(0,201,-21.4),Vector3(92,4,5),TIMBER,0.6)
 # A small carved fan in the crown and restrained environmental controls.
 for i in range(7):
  var angle := float(i)*PI/6
  _rod(w,asset,Vector3(0,207,-23.6),Vector3(cos(angle)*8,210+sin(angle)*7,-23.6),0.32,BRASS)
 _display(w,asset,Vector3(20.5,48,-23.1),Vector2(16,12))
 _path(w,asset,[Vector3(30,47,-22.9),Vector3(34,47,-22.9),Vector3(34,30,-22.9),Vector3(40,30,-22.9)],0.22,BRASS)
 return asset

static func service_counter(w: Node3D, parent: Node3D, p: Vector3, depth: float, side: int = 1) -> Node3D:
 var asset := Node3D.new()
 asset.name = "CabinetmakerServiceCounter"
 parent.add_child(asset)
 asset.position = p
 # Canonical front is -Z. Rotate it toward the central aisle while retaining
 # final X width 135 and Z length `depth` used by the compartment layout.
 asset.rotation.y = side*PI/2
 var width := maxf(depth,65)
 _wood(w,asset,Vector3(0,47,0),Vector3(width-5,82,130),END_GRAIN,1.2)
 for x in [-width*0.5+8,width*0.5-8]:
  for z in [-54,54]: _turned_foot(w,asset,Vector3(x,0,z),10,4.5)
 for layer in [[10,width,4,135],[13,width-2,3,133],[16,width-5,3,130]]:
  _wood(w,asset,Vector3(0,layer[0],0),Vector3(layer[1],layer[2],layer[3]),TIMBER,0.6)
 # Rounded bullnose worktop, warm stone inset and an inlaid brass perimeter.
 _wood(w,asset,Vector3(0,93,0),Vector3(width+6,5.8,140),TIMBER,1.2)
 var stone: MeshInstance3D = w.cushion(Vector3(0,95.85,0),Vector3(width-1,0.3,133),Color("b8b19e"),0.08,asset)
 stone.material_override = Finishes.stone()
 _rect_horizontal(w,asset,Vector3(0,95.7,0),Vector2(width-5,129),0.25,BRASS)
 var sections := maxi(1,int(width/54))
 var section_width := (width-10)/sections
 for i in range(sections):
  var x := -width*0.5+5+(i+0.5)*section_width
  var panel_width := section_width-4
  _wood(w,asset,Vector3(x,72,-64.5),Vector3(panel_width,22,3),TIMBER,0.7)
  _wood(w,asset,Vector3(x,72,-66.1),Vector3(panel_width-7,15,0.8),PANEL,0.3)
  _rect_frame(w,asset,Vector3(x,72,-66.7),Vector2(panel_width-7,15),0.38,BRASS)
  _pull(w,asset,Vector3(x,73,-66.0),minf(16,panel_width*0.45),false)
  _wood(w,asset,Vector3(x,38,-64.5),Vector3(panel_width,43,3),TIMBER,0.7)
  var arch := _arch_outline(panel_width-9,26,5)
  var raised: MeshInstance3D = w.mesh_obj(asset,_extrude(arch,0.8),Vector3(x,22,-66),PANEL)
  raised.material_override = Finishes.timber(PANEL)
  _outline(w,asset,arch,Vector3(x,22,-66.7),0.4,BRASS)
  _pull(w,asset,Vector3(x+panel_width*0.29,43,-66),9,true)
  for y in [25,53]: _hinge(w,asset,Vector3(x-panel_width*0.5+1.2,y,-66),-1)
  _wood(w,asset,Vector3(x+section_width*0.5,48,-64.6),Vector3(3,70,4),TIMBER,0.6)
  # The reverse is a constructed service face, with modest bevels, panel
  # reveals and rails. No upholstered/cushion profile on broad timber faces.
  _wood(w,asset,Vector3(x,49,65.3),Vector3(panel_width-3,59,0.8),PANEL,0.25)
  for y in [18,80]:
   _wood(w,asset,Vector3(x,y,65.5),Vector3(section_width,3.5,2.2),TIMBER,0.4)
  for sign_x in [-1,1]:
   _wood(w,asset,Vector3(x+sign_x*(section_width*0.5-1.5),49,65.5),Vector3(3,65,2.2),TIMBER,0.4)
 # End panels are framed joinery on both visible ends, with a soft applied bead.
 for sign_x in [-1,1]:
  var end := Node3D.new()
  asset.add_child(end)
  end.position = Vector3(sign_x*(width*0.5-1),48,0)
  end.rotation.y = -sign_x*PI/2
  _wood(w,end,Vector3.ZERO,Vector3(117,66,2),PANEL,0.6)
  _rect_frame(w,end,Vector3(0,0,-1.3),Vector2(109,58),0.65,TIMBER)
  _rect_frame(w,end,Vector3(0,0,-1.6),Vector2(104,53),0.3,BRASS)
 # A built-in upper hutch with shaped shelves and cast curved supports.
 for x in [-width*0.5+8,width*0.5-8]:
  _wood(w,asset,Vector3(x,143,60),Vector3(5,96,7),TIMBER,0.8)
  _rod(w,asset,Vector3(x,100,55.8),Vector3(x,188,55.8),0.45,BRASS)
 for y in [150,183]:
  _wood(w,asset,Vector3(0,y,45),Vector3(width-9,4.5,39),TIMBER,0.9)
  _rod(w,asset,Vector3(-width*0.5+6,y+2.5,26),Vector3(width*0.5-6,y+2.5,26),0.45,BRASS)
  for x in [-width*0.5+12,width*0.5-12]:
   var curve: Array[Vector3] = []
   for i in range(17):
    var t := float(i)/16
    curve.append(Vector3(x,y-3-21*(1-t)*(1-t),61-31*t))
   _path(w,asset,curve,1.1,BRASS)
   _rod(w,asset,Vector3(x,y-24,61),Vector3(x,y-1,61),1.1,BRASS)
  # Rear gallery rail and short turned balusters prevent a floating shelf look.
  _rod(w,asset,Vector3(-width*0.5+8,y+11,61),Vector3(width*0.5-8,y+11,61),0.75,BRASS)
  for i in range(maxi(2,int(width/24))):
   var x := -width*0.5+10+float(i)*(width-20)/maxi(1,int(width/24)-1)
   _rod(w,asset,Vector3(x,y+2.5,61),Vector3(x,y+11,61),0.5,BRASS)
 _display(w,asset,Vector3(width*0.5-18,85,-66.7),Vector2(18,7))
 return asset

static func framed_panel(w: Node3D, parent: Node3D, p: Vector3, size: Vector3) -> MeshInstance3D:
 # Dynamic puzzle leaves keep EVERY detail under their returned MeshInstance.
 # In particular, no trim extends below -height/2 into the service cable gap.
 var root: MeshInstance3D = _wood(w,parent,p,size,TIMBER,0.65)
 root.name = "FramedServiceDoor"
 var front := -size.z*0.5
 _wood(w,root,Vector3(0,0,front-0.25),Vector3(size.x-11,size.y-12,0.9),PANEL,0.35)
 _rect_frame(w,root,Vector3(0,0,front-0.9),Vector2(size.x-9,size.y-10),0.8,TIMBER)
 _rect_frame(w,root,Vector3(0,0,front-1.0),Vector2(size.x-14,size.y-15),0.35,BRASS)
 _pull(w,root,Vector3(size.x*0.31,1,front-0.6),minf(14,size.y*0.35),true)
 _escutcheon(w,root,Vector3(size.x*0.31,-11,front-1.0))
 for y in [-size.y*0.30,size.y*0.30]: _hinge(w,root,Vector3(-size.x*0.5+2.4,y,front-0.3),-1)
 _vent(w,root,Vector3(-size.x*0.13,size.y*0.20,front-0.7),Vector2(size.x*0.42,size.y*0.20))
 return root

static func _wood(w: Node3D, parent: Node3D, p: Vector3, size: Vector3, tint: Color, bevel: float) -> MeshInstance3D:
 var mesh: MeshInstance3D = w.mesh_obj(parent,Profiles.rounded_box(size,bevel),p,tint)
 mesh.material_override = Finishes.timber(tint)
 return mesh

static func _rod(w: Node3D, parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
 var node: MeshInstance3D = w.line(a,b,radius,color,parent)
 node.material_override = w.mat(color,0.8 if color == BRASS else 0.0)

static func _path(w: Node3D, parent: Node3D, points: Array[Vector3], radius: float, color: Color) -> void:
 var radii: Array[float] = []
 radii.resize(points.size())
 radii.fill(radius)
 var mesh: MeshInstance3D = w.mesh_obj(parent,Profiles.tube(points,radii,24),Vector3.ZERO,color)
 mesh.material_override = w.mat(color,0.8 if color == BRASS else 0.0)

static func _rect_frame(w: Node3D, parent: Node3D, p: Vector3, size: Vector2, radius: float, color: Color) -> void:
 var points: Array[Vector3] = [Vector3(-size.x*0.5,-size.y*0.5,0),Vector3(size.x*0.5,-size.y*0.5,0),Vector3(size.x*0.5,size.y*0.5,0),Vector3(-size.x*0.5,size.y*0.5,0)]
 for i in range(4): _rod(w,parent,p+points[i],p+points[(i+1)%4],radius,color)

static func _rect_horizontal(w: Node3D, parent: Node3D, p: Vector3, size: Vector2, radius: float, color: Color) -> void:
 var points: Array[Vector3] = [Vector3(-size.x*0.5,0,-size.y*0.5),Vector3(size.x*0.5,0,-size.y*0.5),Vector3(size.x*0.5,0,size.y*0.5),Vector3(-size.x*0.5,0,size.y*0.5)]
 for i in range(4): _rod(w,parent,p+points[i],p+points[(i+1)%4],radius,color)

static func _pull(w: Node3D, parent: Node3D, p: Vector3, span: float, vertical: bool) -> void:
 var axis := Vector3.UP if vertical else Vector3.RIGHT
 for side in [-1,1]:
  var base: Vector3 = p+axis*span*0.5*side
  var boss: MeshInstance3D = w.cyl(base,1.5,0.55,BRASS,false,parent,-1,0.8)
  boss.rotation.x = PI/2
  _rod(w,parent,base,base+Vector3(0,0,-1.4),0.6,BRASS)
 var points: Array[Vector3] = []
 for i in range(17):
  var t := float(i)/16
  points.append(p+axis*(t-0.5)*span+Vector3(0,0,-1.4-0.7*sin(t*PI)))
 _path(w,parent,points,0.6,BRASS)

static func _hinge(w: Node3D, parent: Node3D, p: Vector3, side: int) -> void:
 var plate: MeshInstance3D = w.cushion(p+Vector3(-side*1.2,0,0.2),Vector3(3.6,7,0.55),BRASS,0.15,parent)
 plate.material_override = w.mat(BRASS,0.8)
 w.cyl(p,0.85,7.6,BRASS,false,parent,-1,0.8)
 for y in [-2.3,0,2.3]: w.cyl(p+Vector3(0,y,0),0.97,0.35,BRASS,false,parent,-1,0.8)
 for y in [-2.2,2.2]:
  var screw: MeshInstance3D = w.cyl(p+Vector3(-side*1.8,y,-0.18),0.38,0.28,BRASS,false,parent,-1,0.8)
  screw.rotation.x = PI/2
  _rod(w,parent,p+Vector3(-side*1.8-0.22,y,-0.35),p+Vector3(-side*1.8+0.22,y,-0.35),0.05,END_GRAIN)

static func _escutcheon(w: Node3D, parent: Node3D, p: Vector3) -> void:
 var plate: MeshInstance3D = w.cushion(p,Vector3(3.7,6.4,0.45),BRASS,0.3,parent)
 plate.material_override = w.mat(BRASS,0.8)
 var hole: MeshInstance3D = w.cyl(p+Vector3(0,0.8,-0.32),0.58,0.08,DARK,false,parent)
 hole.rotation.x = PI/2
 _wood(w,parent,p+Vector3(0,-0.6,-0.32),Vector3(0.65,1.8,0.08),DARK,0.03)

static func _vent(w: Node3D, parent: Node3D, p: Vector3, size: Vector2) -> void:
 var cavity: MeshInstance3D = w.cushion(p,Vector3(size.x,size.y,0.6),DARK,0.2,parent)
 cavity.material_override = w.mat(DARK)
 _rect_frame(w,parent,p-Vector3(0,0,0.5),size,0.6,BRASS)
 var count := maxi(3,int(size.y/3))
 for i in range(count):
  var y := -size.y*0.5+1.8+i*(size.y-3.6)/maxi(1,count-1)
  var slat: MeshInstance3D = w.cushion(p+Vector3(0,y,-0.7),Vector3(size.x-2,0.65,1.2),BRASS,0.12,parent)
  slat.rotation.x = -0.35
  slat.material_override = w.mat(BRASS,0.85)

static func _display(w: Node3D, parent: Node3D, p: Vector3, size: Vector2) -> void:
 var bezel: MeshInstance3D = w.cushion(p,Vector3(size.x,size.y,0.8),BRASS,0.2,parent)
 bezel.material_override = w.mat(BRASS,0.8)
 var screen: MeshInstance3D = w.cushion(p-Vector3(0,0,0.5),Vector3(size.x-1.4,size.y-1.4,0.25),DARK,0.05,parent)
 screen.material_override = w.mat(DARK)
 for row in range(3):
  var line: MeshInstance3D = w.box(p+Vector3(-size.x*0.1,size.y*0.22-row*size.y*0.20,-0.68),Vector3(size.x*(0.52-row*0.07),0.25,0.1),CYAN,false,parent)
  line.material_override = w.mat(CYAN,0,0.4)

static func _turned_foot(w: Node3D, parent: Node3D, p: Vector3, height: float, radius: float) -> void:
 var profile: Array[Vector2] = [Vector2(radius*0.70,0),Vector2(radius*0.94,height*0.08),Vector2(radius,height*0.16),Vector2(radius*0.8,height*0.25),Vector2(radius*0.64,height*0.55),Vector2(radius*0.86,height*0.78),Vector2(radius,height*0.86),Vector2(radius,height)]
 var mesh: MeshInstance3D = w.mesh_obj(parent,preload("res://scripts/ceramic_profiles.gd").lathe(profile),p,TIMBER)
 mesh.material_override = Finishes.timber(TIMBER)
 w.cyl(p+Vector3(0,height*0.18,0),radius*0.98,height*0.06,BRASS,false,parent,-1,0.8)

static func _arch_outline(width: float, shoulder: float, rise: float) -> PackedVector2Array:
 var points := PackedVector2Array([Vector2(-width*0.5,0),Vector2(width*0.5,0),Vector2(width*0.5,shoulder)])
 for i in range(1,33):
  var x := width*0.5-float(i)*width/32
  points.append(Vector2(x,shoulder+rise*cos(x/(width*0.5)*PI*0.5)))
 return points

static func _outline(w: Node3D, parent: Node3D, outline: PackedVector2Array, p: Vector3, radius: float, color: Color) -> void:
 for i in range(outline.size()):
  var a := outline[i]
  var b := outline[(i+1)%outline.size()]
  _rod(w,parent,p+Vector3(a.x,a.y,0),p+Vector3(b.x,b.y,0),radius,color)

static func _extrude(outline: PackedVector2Array, depth: float) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var triangles := Geometry2D.triangulate_polygon(outline)
 for side in [-1,1]:
  for triangle in range(0,triangles.size(),3):
   var order := [0,1,2] if side < 0 else [0,2,1]
   for index in order:
    var point := outline[triangles[triangle+index]]
    surface.set_normal(Vector3(0,0,side))
    surface.set_uv(point*0.025)
    surface.add_vertex(Vector3(point.x,point.y,side*depth*0.5))
 for i in range(outline.size()):
  var a := outline[i]
  var b := outline[(i+1)%outline.size()]
  var normal := Vector3(b.y-a.y,a.x-b.x,0).normalized()
  var vertices := [Vector3(a.x,a.y,-depth*0.5),Vector3(b.x,b.y,-depth*0.5),Vector3(b.x,b.y,depth*0.5),Vector3(a.x,a.y,depth*0.5)]
  for index in [0,2,1,0,3,2]:
   surface.set_normal(normal)
   surface.set_uv(Vector2(vertices[index].x,vertices[index].y)*0.025)
   surface.add_vertex(vertices[index])
 return surface.commit()
