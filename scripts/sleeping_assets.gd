extends RefCounted
## Reusable, centimetre-scale sleeping-car furniture. All visible surfaces are
## modeled: framed joinery, turned feet, shaped padding and continuous cloth.
const Finishes:=preload("res://scripts/material_library.gd")
const WindowHead := preload("res://scripts/window_head_finish.gd")
const Veneer = preload("res://scripts/fitted_veneer.gd")
const Upholstery = preload("res://scripts/upholstery_geometry.gd")
const WALNUT := Color("493126")
const DARK := Color("2d211c")
const BRASS := Color("bda374")
const TEAL := Color("214b47")
const IVORY := Color("ded4bf")
static var cache: Dictionary = {}

static func cloth_material(color: Color) -> ShaderMaterial:
 var finishes = preload("res://scripts/material_library.gd")
 return finishes.make(finishes.Finish.LINEN if color.get_luminance()>0.40 else finishes.Finish.VELVET,color)

static func rounded(size: Vector3, radius: float) -> ArrayMesh:
 var key := str(size)+str(radius)
 if not cache.has(key): cache[key] = Upholstery.build(size,radius/1.8)
 return cache[key]

static func part(w: Node3D, parent: Node3D, p: Vector3, size: Vector3, color: Color, radius: float = 0.6, finish: int = 2) -> MeshInstance3D:
 var node: MeshInstance3D = w.mesh_obj(parent,rounded(size,radius),p,color)
 node.material_override = cloth_material(color) if finish == 1 else w.cabin_finish(finish,color)
 return node

static func metal(w: Node3D, parent: Node3D, p: Vector3, size: Vector3, radius: float = 0.2) -> MeshInstance3D:
 return w.mesh_obj(parent,rounded(size,radius),p,BRASS,false,0.8)

static func lathe(profile: Array[Vector2], segments: int = 64) -> ArrayMesh:
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(profile.size()-1):
  for j in range(segments):
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var i: int = row+c.y
    var a: float = float(j+c.x)*TAU/segments
    var t: Vector2 = profile[mini(i+1,profile.size()-1)]-profile[maxi(i-1,0)]
    s.set_normal(Vector3(t.y*cos(a),-t.x,t.y*sin(a)).normalized())
    s.set_uv(Vector2(float(j+c.x)/segments,float(i)/(profile.size()-1)))
    s.add_vertex(Vector3(cos(a)*profile[i].x,profile[i].y,sin(a)*profile[i].x))
 return s.commit()

static func turned_foot() -> ArrayMesh:
 if not cache.has("foot"):
  cache.foot = lathe([Vector2(0,0),Vector2(2.7,0),Vector2(3.0,1),Vector2(2.8,3),Vector2(2.3,4),Vector2(2.0,6),Vector2(3.1,10),Vector2(3.6,12),Vector2(3.4,14),Vector2(2.8,15),Vector2(2.7,18),Vector2(4.0,19),Vector2(4.0,22),Vector2(0,22)])
 return cache.foot

static func add_path(w: Node3D, parent: Node3D, points: Array[Vector3], radius: float, color: Color) -> void:
 for i in range(points.size()-1): w.line(points[i],points[i+1],radius,color,parent)

static func build_bed(w: Node3D, parent: Node3D, p: Vector3, style: Dictionary = {}) -> Node3D:
 var bed := Node3D.new()
 bed.name = "MeridianCraftedSleeperBed"
 parent.add_child(bed)
 bed.position = p
 var frame: Color = style.get("frame",WALNUT)
 var cover: Color = style.get("cover",TEAL)
 var linen: Color = style.get("linen",IVORY)
 var binding: Color = style.get("binding",Color("9c8767"))
 var silhouette: String = style.get("outline","classic")
 bed.set_meta("joinery",silhouette)
 # A raised frame has actual open space underneath, with mortised rail ends.
 for x in [-59.0,59.0]:
  for z in [-91.0,91.0]:
   var leg: MeshInstance3D = w.mesh_obj(bed,turned_foot(),Vector3(x,0,z),frame)
   leg.material_override = w.cabin_finish(2,frame)
   w.cyl(Vector3(x,1.3,z),2.8,2.6,BRASS,false,bed,-1,0.75)
 for x in [-64.5,64.5]:
  part(w,bed,Vector3(x,32,0),Vector3(6,29,197),frame,1.4)
  part(w,bed,Vector3(x,44,0),Vector3(7.5,4.5,201),frame,1.3)
  metal(w,bed,Vector3(x+signf(x)*3.1,36,0),Vector3(0.45,0.65,185))
  for z in [-63.0,0.0,63.0]:
   part(w,bed,Vector3(x+signf(x)*3.1,29,z),Vector3(0.8,15,55),DARK,0.6)
   for dz in [-27.0,27.0]: part(w,bed,Vector3(x+signf(x)*3.6,29,z+dz),Vector3(0.6,17,1.5),frame,0.3)
 for z in [-98.0,98.0]:
  part(w,bed,Vector3(0,31,z),Vector3(130,28,6),frame,1.4)
  part(w,bed,Vector3(0,44,z),Vector3(132,4,7.5),frame,1.1)
  part(w,bed,Vector3(0,29,z+signf(z)*3.2),Vector3(116,15,1),DARK,0.5)
  for x in [-56.0,56.0]: part(w,bed,Vector3(x,29,z+signf(z)*4),Vector3(1.5,17,0.9),frame,0.4)
  metal(w,bed,Vector3(0,38,z+signf(z)*3.5),Vector3(114,0.6,0.5))
 # Laminated support slats are visible beneath the mattress from fly height.
 for z in range(-84,85,14):
  part(w,bed,Vector3(0,43.3,z),Vector3(124,2.5,8),Color("70513a"),0.8)
 # Upholstered mattress with continuous rounded edges and stitched welt.
 part(w,bed,Vector3(0,53,0),Vector3(130,16,199),linen,5.5,1)
 for y in [48.5,58.5]:
  var seam: Array[Vector3] = []
  for i in range(129):
   var a: float = TAU*i/128.0
   seam.append(Vector3(signed_power(cos(a),0.20)*64.5,y,signed_power(sin(a),0.20)*99.0))
  add_path(w,bed,seam,0.15,Color("c8bea7"))
 # Swept curved headboard silhouette: wood shell and quilted velvet insert.
 var head: MeshInstance3D = w.mesh_obj(bed,headboard_mesh(132,67,7,false,silhouette),Vector3(0,69,-101),frame)
 head.name = "ShapedHeadboard"
 head.material_override = w.cabin_finish(2,frame) if silhouette=="classic" else Veneer.make("bed",frame)
 var inset: MeshInstance3D = w.mesh_obj(bed,headboard_mesh(116,54,4,true,silhouette),Vector3(0,75,-96.9),cover)
 inset.name = "RecessedUpholsteredField"
 inset.material_override = cloth_material(cover)
 # The reverse is finished too: inset walnut, curved moulding and joinery remain
 # visible when a fly circles behind the freestanding headboard.
 var reverse_panel: MeshInstance3D = w.mesh_obj(bed,headboard_mesh(116,53,1.1,false,silhouette),Vector3(0,75,-105.0),Color("5a3b2c"))
 reverse_panel.material_override = w.cabin_finish(2,Color("5a3b2c"))
 for x in [-37.0,37.0]: part(w,bed,Vector3(x,96,-105.7),Vector3(1.2,39,0.8),frame,0.3)
 metal(w,bed,Vector3(0,79,-105.9),Vector3(105,0.5,0.4))
 var outline: Array[Vector3] = []
 for i in range(65):
  var x: float = -63.0+i*126.0/64
  outline.append(Vector3(x,69+head_height(x/66,silhouette)*67,-96.9))
 add_path(w,bed,outline,0.55,BRASS)
 for x in [-65.0,65.0]:
  var post: MeshInstance3D = w.mesh_obj(bed,post_mesh(),Vector3(x,0,-102),frame)
  post.material_override = w.cabin_finish(2,frame)
  w.ball(Vector3(x,128,-102),Vector3(7,9,7),BRASS,bed)
 for x in [-38.0,-19.0,0.0,19.0,38.0]:
  for y in [90.0,111.0]:
   if y > 75+53*head_height(x/58,silhouette): continue
   w.ball(Vector3(x,y,-93.7),Vector3(1.9,1.9,0.8),cover.darkened(0.2),bed)
 # These are garments fitted to the same mattress: an ample formal
 # coverlet, a crew bunk tuck, a slanted coastal throw or a plain service bed.
 var blanket: MeshInstance3D = w.mesh_obj(bed,blanket_mesh(silhouette),Vector3.ZERO,cover)
 blanket.material_override = bedding_finish(silhouette,cover)
 blanket.name = "FittedBlanket"
 blanket.set_meta("bedding_role",silhouette)
 var fold: MeshInstance3D = w.mesh_obj(bed,fold_mesh(silhouette),Vector3.ZERO,linen)
 fold.material_override = cloth_material(linen) if silhouette=="classic" else bedding_finish("bolster",linen)
 fold.name = "FoldedTopSheet"
 if has_runner(silhouette):
  var runner: MeshInstance3D = w.mesh_obj(bed,runner_mesh(silhouette),Vector3.ZERO,binding)
  runner.material_override = bedding_finish("round" if silhouette=="round" else "fan",binding)
  runner.name = "LooseBedThrow"
 var hem: Array[Vector3] = []
 var c:=96 if silhouette=="classic" else 60
 for i in range(c+1): hem.append(fitted_blanket_point(-1.0+2.0*i/c,1.0,silhouette)+Vector3(0,0.2,0))
 add_path(w,bed,hem,0.18,Color("b49d72") if has_runner(silhouette) else binding)
 for layout in pillow_fit(silhouette):
  var pillow: MeshInstance3D = w.mesh_obj(bed,pillow_mesh(),Vector3(layout.x,66,layout.y),linen)
  pillow.name = "PlacedSleeperPillow"
  pillow.rotation.y = layout.z
  pillow.material_override = cloth_material(linen)
  var seam := Node3D.new()
  bed.add_child(seam)
  seam.position = pillow.position
  seam.rotation = pillow.rotation
  var points: Array[Vector3] = []
  for j in range(97):
   var a: float = TAU*j/96.0
   points.append(Vector3(signed_power(cos(a),0.35)*25.6,0,signed_power(sin(a),0.35)*17))
  add_path(w,seam,points,0.13,Color("b8ad94"))
 return bed

static func signed_power(v: float, power: float) -> float:
 return signf(v)*pow(absf(v),power)

static func head_height(x: float, silhouette: String = "classic") -> float:
 var u := absf(x)
 match silhouette:
  "fan": return 0.68+0.32*pow(maxf(0,1-u*u),1.4)+0.023*sin(u*PI*3)*u*(1-u)
  "bolster": return 0.86+0.11*sqrt(maxf(0,1-pow(u,6)))
  "round": return 0.55+0.45*sqrt(maxf(0,1-u*u))
  "stepped": return 0.79+0.18*(1.0-smoothstep(0.47,0.60,u))+0.03*(1.0-smoothstep(0.84,1.0,u))
 return 0.74+0.26*pow(maxf(0,1-x*x),0.65)

static func headboard_mesh(width: float, height: float, depth: float, padded: bool, silhouette: String = "classic") -> ArrayMesh:
 var key := "head%s%s%s%s%s" % [width,height,depth,padded,silhouette]
 if cache.has(key): return cache[key]
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 var nx := 64
 var ny := 28
 for side in [-1.0,1.0]:
  for row in range(ny):
   for col in range(nx):
    var points: Array[Vector3] = []
    for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
     var u: float = float(col+c.x)/nx
     var v: float = float(row+c.y)/ny
     var x: float = (u*2-1)*width*0.5
     var y: float = v*height*head_height(u*2-1,silhouette)
     var z: float = side*depth*0.5
     if padded and side > 0:
      z += 2.2*sin(u*PI)*sin(v*PI)
      for bx in [-38.0,-19.0,0.0,19.0,38.0]:
       for by in [15.0,36.0]: z -= 1.6*exp(-Vector2(x-bx,y-by).length_squared()/13)
     points.append(Vector3(x,y,z))
    quad(s,points,side < 0)
 # Four edges close the shell and keep its contact collision physical.
 for col in range(nx):
  var xa := (-1.0+2.0*col/nx)*width*0.5
  var xb := (-1.0+2.0*(col+1)/nx)*width*0.5
  var ya := height*head_height(xa/(width*0.5),silhouette)
  var yb := height*head_height(xb/(width*0.5),silhouette)
  quad(s,[Vector3(xa,ya,-depth/2),Vector3(xb,yb,-depth/2),Vector3(xb,yb,depth/2),Vector3(xa,ya,depth/2)],true)
  quad(s,[Vector3(xa,0,-depth/2),Vector3(xb,0,-depth/2),Vector3(xb,0,depth/2),Vector3(xa,0,depth/2)],false)
 for x in [-width/2,width/2]:
  quad(s,[Vector3(x,0,-depth/2),Vector3(x,height*head_height(1,silhouette),-depth/2),Vector3(x,height*head_height(1,silhouette),depth/2),Vector3(x,0,depth/2)],x < 0)
 s.generate_normals()
 cache[key] = s.commit()
 return cache[key]

static func post_mesh() -> ArrayMesh:
 if not cache.has("post"):
  cache.post = lathe([Vector2(0,0),Vector2(3.3,0),Vector2(3.5,4),Vector2(2.5,7),Vector2(2.7,26),Vector2(3.5,28),Vector2(3.6,32),Vector2(2.8,34),Vector2(2.8,111),Vector2(4.2,114),Vector2(4.1,118),Vector2(2.6,121),Vector2(2.6,124),Vector2(0,124)])
 return cache.post

static func quad(s: SurfaceTool, points: Array[Vector3], reverse: bool = false) -> void:
 var order := [0,1,2,0,2,3] if reverse else [0,2,1,0,3,2]
 for index in order:
  s.set_uv(Vector2(points[index].x,points[index].z)*0.04)
  s.add_vertex(points[index])

static func blanket_point(u: float, v: float) -> Vector3:
 var x: float = u*77.0
 var z: float = lerpf(-52,114,v)
 var side_drop := smoothstep(60,77,absf(x))
 var foot_drop := smoothstep(95,114,z)
 var height := 64.2-25*maxf(side_drop,foot_drop)
 # Heavy cloth makes a few broad, unequal folds; the hem does not form a
 # repeated decorative scallop. The sides turn downward close to the mattress.
 var fold := sin(x*0.075+sin(z*0.028)*0.65)+0.28*sin(x*0.11+0.8)
 height += fold*(0.30+0.7*side_drop+0.9*foot_drop)
 height += sin(z*0.095+x*0.018)*1.4*side_drop
 height += sin(z*0.065+x*0.022)*0.42*(1-side_drop)
 height += 1.8*exp(-pow((x-52)/21,2))*foot_drop
 x = signf(x)*(minf(absf(x),64)+9*side_drop)
 z = minf(z,99)+8*foot_drop
 x += sin(z*0.045)*side_drop*0.45
 z += sin(x*0.065)*foot_drop*0.55
 return Vector3(x,height,z)

static func has_runner(style:String)->bool:
 return style not in ["bolster","stepped"]

static func pillow_fit(style:String)->Array[Vector3]:
 match style:
  "fan": return [Vector3(-28,-74,-0.12),Vector3(28,-75,0.055)]
  "bolster": return [Vector3(-14,-76,-0.072)]
  "round": return [Vector3(-29,-75,-0.12),Vector3(29,-72,0.12)]
  "stepped": return [Vector3(0,-75,-0.038)]
 return [Vector3(-28,-75,-0.065),Vector3(28,-75,0.045)]

static func bedding_finish(style:String,tint:Color)->ShaderMaterial:
 return Finishes.make(Finishes.Finish.LINEN,tint) if style in ["bolster","stepped"] else cloth_material(tint)

static func fitted_blanket_point(u:float,v:float,style:String)->Vector3:
 var p:=blanket_point(u,v)
 var edge:=smoothstep(0.72,1.0,absf(u))
 var foot:=smoothstep(0.83,1.0,v)
 var crown:=(1.0-edge)*(1.0-foot)
 match style:
  "fan":
   p.y+=sin(v*14.5)*0.46*crown
  "bolster":
   p.x*=0.945
   p.z-=2.6*foot
   p.y+=maxf(4.5*foot,6.8*edge)-0.48*crown
  "round":
   p.x*=lerpf(0.946,0.991,(u+1.0)*0.5)
   p.z-=foot*(2.0-1.6*u)
   p.y+=(0.75+u*0.5)*edge+sin(v*8.6+u*4.0)*0.38*crown
  "stepped":
   p.x*=0.928
   p.z-=3.5*foot
   p.y+=maxf(6.0*foot,8.8*edge)-0.65*crown
 if style!="classic":
  # The narrower shell must wrap the actual rounded mattress and never
  # disappear through its face where a side or foot corner is tucked.
  p.y=clampf(p.y,mattress_top_at(p.x,p.z)+0.32,65.15)
 return p

static func mattress_top_at(x:float,z:float)->float:
 var r:=5.6
 var outside:=Vector2(maxf(absf(x)-(65.0-r),0),maxf(absf(z)-(99.5-r),0))
 if outside.length_squared()>r*r:return 0.0
 return 61.0-r+sqrt(maxf(0.0,r*r-outside.length_squared()))

static func blanket_mesh(style:String="classic") -> ArrayMesh:
 var key:="blanket_"+style
 if cache.has(key): return cache[key]
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rows:=96 if style=="classic" else 72
 var columns:=80 if style=="classic" else 64
 for row in range(rows):
  for col in range(columns):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    points.append(fitted_blanket_point(-1+2.0*(col+c.x)/columns,float(row+c.y)/rows,style))
   quad(s,points,true)
 s.generate_normals()
 cache[key] = s.commit()
 return cache[key]

static func fold_mesh(style:String="classic") -> ArrayMesh:
 var key:="fold_"+style
 if cache.has(key): return cache[key]
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(16):
  for col in range(80):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var u: float = -1+2.0*(col+c.x)/80
    var v: float = float(row+c.y)/16
    var fold_depth:float = {"bolster":0.085,"round":0.15,"stepped":0.07}.get(style,0.13)
    var angle:=0.025*(u+1) if style=="round" else 0.0
    var p := fitted_blanket_point(u,v*fold_depth+angle,style)
    p.y += 0.55+sin(v*PI)*(1.0 if not has_runner(style) else 1.5)
    points.append(p)
   quad(s,points,true)
 s.generate_normals()
 cache[key] = s.commit()
 return cache[key]

static func runner_mesh(style:String="classic") -> ArrayMesh:
 var key:="runner_"+style
 if cache.has(key): return cache[key]
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(12):
  for col in range(80):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var u: float = -1+2.0*(col+c.x)/80
    var fraction:float=float(row+c.y)/12
    var v:=lerpf(0.67,0.81,fraction)
    if style=="fan": v=lerpf(0.63,0.80,fraction)
    if style=="round": v=lerpf(0.69,0.88,fraction)+u*0.054
    var width:=u*(0.96 if style=="round" else 1.0)
    var height:=0.30 if style=="classic" else (0.37+(0.55*sin(fraction*PI) if style=="round" else 0.0))
    points.append(fitted_blanket_point(width,v,style)+Vector3(0,height,0))
   quad(s,points,true)
 s.generate_normals()
 cache[key] = s.commit()
 return cache[key]

static func pillow_mesh() -> ArrayMesh:
 if cache.has("pillow"): return cache.pillow
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(32):
  for col in range(96):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var a: float = TAU*(col+c.x)/96.0
    var b: float = PI*(row+c.y)/32.0-PI/2
    # A full central loft contracts into a pinched sewn perimeter. Unequal
    # corner compression breaks the mathematical symmetry of an inflated box.
    var breadth := pow(cos(b),0.38)*(1.0-0.022*exp(-pow(b*9,2)))
    var x: float = signed_power(cos(a),0.35)*25.6*breadth
    var z: float = signed_power(sin(a),0.35)*17*breadth
    var y: float = signed_power(sin(b),0.85)*9.2
    y -= signf(y)*1.8*exp(-Vector2(x+18,z-11).length_squared()/70)*pow(absf(cos(b)),2)
    y -= signf(y)*0.8*exp(-Vector2(x-19,z+12).length_squared()/50)*pow(absf(cos(b)),2)
    y += sin(a*7+b*2)*0.38*pow(cos(b),5)*sin(b)
    points.append(Vector3(x,y,z))
   quad(s,points,true)
 s.generate_normals()
 cache.pillow = s.commit()
 return cache.pillow

static func build_bedside(w: Node3D, parent: Node3D, p: Vector3) -> Node3D:
 var unit := Node3D.new()
 unit.name = "BedsideMarquetryCabinet"
 parent.add_child(unit)
 unit.position = p
 for x in [-13.0,13.0]:
  for z in [-15.0,15.0]:
   var leg: MeshInstance3D = w.mesh_obj(unit,turned_foot(),Vector3(x,0,z),WALNUT)
   leg.scale = Vector3(0.62,0.65,0.62)
   leg.material_override = w.cabin_finish(2,WALNUT)
 part(w,unit,Vector3(0,17,0),Vector3(35,5,39),WALNUT,1.0)
 for x in [-16.0,16.0]:
  part(w,unit,Vector3(x,39,0),Vector3(3,41,36),WALNUT,0.7)
  part(w,unit,Vector3(x+signf(x)*1.6,39,0),Vector3(0.6,30,26),DARK,0.3)
 part(w,unit,Vector3(0,39,17),Vector3(31,41,3),WALNUT,0.5)
 part(w,unit,Vector3(0,60,0),Vector3(37,4,41),WALNUT,1.0)
 part(w,unit,Vector3(0,63,0),Vector3(39,2,43),WALNUT,0.9)
 metal(w,unit,Vector3(0,61.8,0),Vector3(37.5,0.6,41.5))
 for y in [29.0,47.0]:
  part(w,unit,Vector3(0,y,-18),Vector3(30,16,3),WALNUT,0.9)
  part(w,unit,Vector3(0,y,-19.6),Vector3(25,11,0.6),Color("5c4030"),0.8)
  for x in [-9.0,9.0]:
   w.cyl(Vector3(x,y,-20),0.9,0.8,BRASS,false,unit,-1,0.8).rotation.x = PI/2
  var pull: Array[Vector3] = []
  for i in range(21):
   var a: float = PI*i/20
   pull.append(Vector3(-9+18.0*i/20,y-sin(a)*2.1,-20.8-sin(a)*1.4))
  add_path(w,unit,pull,0.42,BRASS)
 # Recessed cabin controls, with physical bezel and small tactile switches.
 metal(w,unit,Vector3(0,56.8,-19.8),Vector3(20,4.5,0.7),0.4)
 var screen: MeshInstance3D = w.mesh_obj(unit,rounded(Vector3(13,2.6,0.3),0.2),Vector3(-2,56.8,-20.3),Color("244540"))
 screen.material_override = w.mat(Color("244540"),0,0.18)
 for x in [5.7,7.5]: w.ball(Vector3(x,56.8,-20.3),Vector3(0.9,0.9,0.6),BRASS,unit)
 build_reading_lamp(w,unit,Vector3(0,64,0))
 return unit

static func build_reading_lamp(w: Node3D, parent: Node3D, p: Vector3) -> void:
 if not cache.has("lampbase"):
  cache.lampbase = lathe([Vector2(0,0),Vector2(7,0),Vector2(7.4,0.6),Vector2(7.1,1.4),Vector2(5.6,2),Vector2(4.5,2.3),Vector2(3.2,3.2),Vector2(1.2,4.1),Vector2(0.8,15),Vector2(2.4,16),Vector2(0,16)])
 w.mesh_obj(parent,cache.lampbase,p,BRASS,false,0.8)
 var shade := SurfaceTool.new()
 shade.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(8):
  for j in range(128):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var t: float = float(row+c.y)/8
    var a: float = TAU*(j+c.x)/128
    var radius: float = lerpf(10.5,5.9,t)+0.25*cos(a*32)
    points.append(Vector3(cos(a)*radius,16+t*11,sin(a)*radius))
   quad(shade,points,true)
 shade.generate_normals()
 var cover: MeshInstance3D = w.mesh_obj(parent,shade.commit(),p,IVORY)
 var fabric := StandardMaterial3D.new()
 fabric.albedo_color = IVORY
 fabric.roughness = 0.85
 fabric.cull_mode = BaseMaterial3D.CULL_DISABLED
 fabric.emission_enabled = true
 fabric.emission = Color("bda77c")
 fabric.emission_energy_multiplier = 0.16
 cover.material_override = fabric
 for spec in [Vector2(10.5,16),Vector2(5.9,27)]:
  var ring: Array[Vector3] = []
  for j in range(97):
   var a: float = TAU*j/96.0
   ring.append(p+Vector3(cos(a)*spec.x,spec.y,sin(a)*spec.x))
  add_path(w,parent,ring,0.22,BRASS)
 w.ball(p+Vector3(0,19,0),Vector3(3,5,3),Color("efd6a5"),parent,0.45)

const CURTAIN_COLORS:Dictionary={
 "0:-1:0":Color("5c3d40"),"0:1:0":Color("4a5946"),"0:-1:1":Color("4d5e66"),"0:1:1":Color("414d52"),
 "1:-1:0":Color("3a564d"),"1:1:0":Color("3c4757"),"1:-1:1":Color("573341"),
 "1:1:1":Color("3d594c"),"1:-1:2":Color("645d4a"),"1:1:2":Color("3f4c56"),
 "2:-1:0":Color("536b58"),"2:1:0":Color("665b4c"),"2:-1:1":Color("3d4f46"),"2:1:1":Color("4b6860")
}

static func curtain_plan(car:int,z:float)->Array[Dictionary]:
 var output:Array[Dictionary]=[]
 if car<0 or car>=WindowHead.COACH_WALLS.size():return output
 var bounds:Array=WindowHead.COACH_WALLS[car]
 for room in range(bounds.size()-1):
  var first:=maxf(z-15.5,float(bounds[room])+5.7)
  var last:=minf(z+15.5,float(bounds[room+1])-5.7)
  if last-first<8.0:continue
  output.append({"center":(first+last)*0.5,"scale":(last-first)/31.0,"room":room,"first":first,"last":last})
 return output

static func build_curtains(w: Node3D, parent: Node3D, car: int) -> Node3D:
 var group:=Node3D.new()
 group.name="TailoredVelvetCurtains_%d"%car
 parent.add_child(group)
 for side in [-1,1]:
  for z in range(car*840+40,car*840+790,170):
   for cut in curtain_plan(car,z):
    var finish_id:="%d:%d:%d"%[car,side,cut.room]
    var dye:Color=CURTAIN_COLORS.get(finish_id,TEAL)
    fitted_drop(w,group,side,cut.center,cut.scale,dye,finish_id)
   WindowHead.install(w,group,car,side,z)
 return group

static func fitted_drop(w:Node3D,parent:Node3D,side:int,center:float,span:float,dye:Color,role:String)->void:
 var drop:=Node3D.new()
 drop.name="FittedWindowCurtain_%d_%d"%[side,int(center*10)]
 drop.position=Vector3(0,0,center)
 drop.scale=Vector3(1.0,1.0,span)
 drop.set_meta("curtain_role",role)
 drop.set_meta("physical_drop_half_cm",15.5*span)
 parent.add_child(drop)
 var cloth:MeshInstance3D=w.mesh_obj(drop,curtain_mesh(clampi(ceili(48*span),18,48)),Vector3(side*489,103,0),dye)
 cloth.scale.x=-side
 cloth.material_override=cloth_material(dye)
 var rope:Array[Vector3]=[]
 for i in range(33):
  var u:float=-1+2.0*i/32
  rope.append(Vector3(side*(483-2.5*sin((u+1)*PI/2)),155-1.0*cos(u*PI/2),u*9))
 add_path(w,drop,rope,0.36,BRASS)
 w.line(Vector3(side*482,154,9),Vector3(side*481,144,11),0.32,BRASS,drop)
 for j in range(7):
  var a:float=TAU*j/7.0
  w.line(Vector3(side*481,144,11),Vector3(side*481+cos(a)*1.3,138,11+sin(a)*1.3),0.19,BRASS,drop)

static func curtain_mesh(columns:int=48) -> ArrayMesh:
 var id:="curtain/%d"%columns
 if cache.has(id):return cache[id]
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(80):
  for col in range(columns):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var u: float = -1+2.0*(col+c.x)/48
    var v: float = float(row+c.y)/80
    var gather := exp(-pow((v-0.33)*6,2))
    var width := 15.5-7*gather
    var depth := 3+sin(u*PI*3+v*0.6)*(2.1-0.9*gather)+0.8*cos(v*PI)
    var y: float = v*159+cos(u*PI*3)*0.65*(1-v)
    points.append(Vector3(depth,y,u*width))
   quad(s,points,true)
 s.generate_normals()
 cache[id]=s.commit()
 return cache[id]

static func valance_mesh() -> ArrayMesh:
 if cache.has("valance"): return cache.valance
 var s := SurfaceTool.new()
 s.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(12):
  for col in range(96):
   var points: Array[Vector3] = []
   for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var u: float = float(col+c.x)/96
    var v: float = float(row+c.y)/12
    var bottom := 251-4*sin(u*PI)
    points.append(Vector3(4+sin(u*TAU*4)*2,lerpf(bottom,274,v),-77+u*154))
   quad(s,points,true)
 s.generate_normals()
 cache.valance = s.commit()
 return cache.valance
