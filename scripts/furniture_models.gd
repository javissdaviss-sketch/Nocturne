extends RefCounted
## Crafted furniture parts, shared across separately named table/chair model roots.
## Mesh profiles include their bevels and joinery; no box meshes form the furniture.
static var cache: Dictionary = {}
const TIMBER := Color("493328")

static func build_chaise(w: Node3D, parent: Node3D, p: Vector3) -> Node3D:
 var model := Node3D.new()
 model.name = "UpholsteredChaise"
 parent.add_child(model)
 model.position = p
 var velvet := Color("254c48")
 var leg_profile := PackedVector2Array([Vector2(0,2.4),Vector2(3,2.7),Vector2(5,2.2),Vector2(25,2.5),Vector2(29,3.4),Vector2(34,3.4)])
 for x in [-39,39]:
  for z in [-43,43]:
   w.mesh_obj(model,lathe(leg_profile),Vector3(x,0,z),TIMBER).material_override = w.cabin_finish(2,TIMBER)
   w.mesh_obj(model,lathe(PackedVector2Array([Vector2(0,2.6),Vector2(3,2.9),Vector2(5,2.5)])),Vector3(x,0,z),w.GOLD,false,0.7)
 for z in [-45,45]:
  w.mesh_obj(model,apron(86,12,4),Vector3(0,30,z),TIMBER).material_override = w.cabin_finish(2,TIMBER)
 for x in [-42,42]:
  var rail: MeshInstance3D = w.mesh_obj(model,apron(90,12,4),Vector3(x,30,0),TIMBER)
  rail.rotation.y = PI/2
  rail.material_override = w.cabin_finish(2,TIMBER)
 w.cushion(Vector3(0,43,-4),Vector3(98,18,98),velvet,5,model)
 timber_back(w,model,Vector3(0,73,47),Vector2(98,58))
 var pad: MeshInstance3D = w.cushion(Vector3(0,73,36),Vector3(88,49,13),velvet,4,model,true)
 pad.rotation.x = -0.08
 for x in [-43,43]:
  w.mesh_obj(model,arm(9,7,99),Vector3(x,53,0),TIMBER).material_override = w.cabin_finish(2,TIMBER)
  w.mesh_obj(model,arm(13,15,96),Vector3(x,61,-3.5),velvet).material_override = w.cabin_finish(1,velvet)
  w.mesh_obj(model,lathe(PackedVector2Array([Vector2(0,2.7),Vector2(20,2.2),Vector2(29,3.0)])),Vector3(x,32,-42),TIMBER).material_override = w.cabin_finish(2,TIMBER)
 var back_basis := Basis(Vector3.RIGHT,-0.08)
 for x in [-18,0,18]:
  for y in [-11,10]:
   w.ball(Vector3(0,73,36)+back_basis*Vector3(x,y,-5.4),Vector3(1.8,1.8,0.65),velvet.darkened(0.12),model)
 return model

static func timber_back(w: Node3D, parent: Node3D, p: Vector3, size: Vector2) -> Node3D:
 # Separate rails, stiles and a recessed panel describe real cabinet joinery.
 # Their small edge radius must not look like upholstered padding.
 var frame := Node3D.new()
 frame.name = "JoinedTimberBack"
 parent.add_child(frame)
 frame.position = p
 frame.rotation.x = -0.08
 var stile := 5.3
 var rail := 5.8
 for side in [-1,1]:
  var piece: MeshInstance3D = w.mesh_obj(frame,bevelled_timber(Vector3(stile,size.y,7),0.60),Vector3(side*(size.x-stile)*0.5,0,0),TIMBER)
  piece.name = "BackStile"
  piece.material_override = w.cabin_finish(2,TIMBER)
 for side in [-1,1]:
  var piece: MeshInstance3D = w.mesh_obj(frame,bevelled_timber(Vector3(size.x-stile*2,rail,7),0.60),Vector3(0,side*(size.y-rail)*0.5,0),TIMBER)
  piece.name = "BackRail"
  piece.material_override = w.cabin_finish(2,TIMBER)
 var panel: MeshInstance3D = w.mesh_obj(frame,bevelled_timber(Vector3(size.x-stile*2+0.3,size.y-rail*2+0.3,1.6),0.22),Vector3(0,0,1.55),TIMBER.lightened(0.025))
 panel.name = "RecessedVeneerPanel"
 panel.material_override = w.cabin_finish(2,TIMBER.lightened(0.025))
 # A fine raised bead borders the routed rear-panel recess.
 for side in [-1,1]:
  w.mesh_obj(frame,bevelled_timber(Vector3(0.7,size.y-rail*2,0.8),0.3),Vector3(side*(size.x*0.5-stile+0.15),0,2.65),TIMBER).material_override = w.cabin_finish(2,TIMBER)
  w.mesh_obj(frame,bevelled_timber(Vector3(size.x-stile*2,0.7,0.8),0.3),Vector3(0,side*(size.y*0.5-rail+0.15),2.65),TIMBER).material_override = w.cabin_finish(2,TIMBER)
 return frame

static func bevelled_timber(size: Vector3, radius: float) -> ArrayMesh:
 var key := "timber"+str(size)+str(radius)
 if not cache.has(key): cache[key] = preload("res://scripts/upholstery_geometry.gd").build(size,radius,false,radius)
 return cache[key]

static func table(w: Node3D, parent: Node3D, width: float, depth: float) -> void:
 var top: MeshInstance3D = w.mesh_obj(parent,tabletop(width,depth),Vector3.ZERO,Color.WHITE)
 top.name = "MouldedWalnutTop"
 top.material_override = w.table_material()
 for inset in [4.2,5.0]:
  var inlay: MeshInstance3D = w.mesh_obj(parent,inlay_ring(width,depth,inset,0.30),Vector3(0,77.43,0),w.GOLD,false,0.7)
  inlay.name = "FlushBrassInlay"
 var profile := PackedVector2Array([Vector2(0,1.7),Vector2(0.8,2.1),Vector2(3.5,2.1),Vector2(4.3,1.65),Vector2(9,1.6),Vector2(10.5,2.3),Vector2(12,2.6),Vector2(13.5,2.3),Vector2(15,1.7),Vector2(19,1.75),Vector2(46,1.65),Vector2(51,2.0),Vector2(54,2.7),Vector2(56,3.2),Vector2(58,3.1),Vector2(61,2.4),Vector2(64,2.1),Vector2(69,2.65),Vector2(71.5,2.65)])
 for x in [-1,1]:
  for z in [-1,1]:
   var p := Vector3(x*(width*0.5-8),0,z*(depth*0.5-8))
   var leg: MeshInstance3D = w.mesh_obj(parent,lathe(profile),p,TIMBER)
   leg.name = "TurnedLeg"
   leg.material_override = w.cabin_finish(2,TIMBER)
   w.mesh_obj(parent,lathe(PackedVector2Array([Vector2(0,1.8),Vector2(0.7,2.2),Vector2(3.7,2.2),Vector2(4.1,1.8)])),p,w.GOLD,false,0.7)
 for side in [-1,1]:
  var rail: MeshInstance3D = w.mesh_obj(parent,apron(width-16,10,2.6),Vector3(0,66.5,side*(depth*0.5-8)),TIMBER)
  rail.name = "ScallopedApron"
  rail.material_override = w.cabin_finish(2,TIMBER)
  var side_rail: MeshInstance3D = w.mesh_obj(parent,apron(depth-16,10,2.6),Vector3(side*(width*0.5-8),66.5,0),TIMBER)
  side_rail.material_override = w.cabin_finish(2,TIMBER)
  side_rail.rotation.y = PI/2

static func tabletop(width: float, depth: float) -> ArrayMesh:
 var key := "top"+str(Vector2(width,depth))
 if cache.has(key): return cache[key]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var radius := minf(width,depth)*0.075
 var profile := PackedVector2Array([Vector2(71.5,2.0),Vector2(72.0,0.7),Vector2(72.8,0.1),Vector2(74.9,0.0),Vector2(75.8,0.3),Vector2(76.7,0.8),Vector2(77.4,1.5)])
 for row in range(profile.size()-1):
  var lower := outline(width-profile[row].y*2,depth-profile[row].y*2,maxf(1,radius-profile[row].y))
  var upper := outline(width-profile[row+1].y*2,depth-profile[row+1].y*2,maxf(1,radius-profile[row+1].y))
  for i in range(lower.size()):
   var j := (i+1)%lower.size()
   var a := Vector3(lower[i].x,profile[row].x,lower[i].y)
   var b := Vector3(lower[j].x,profile[row].x,lower[j].y)
   var c := Vector3(upper[j].x,profile[row+1].x,upper[j].y)
   var d := Vector3(upper[i].x,profile[row+1].x,upper[i].y)
   var n1 := outline_normal(lower,i)
   var n2 := outline_normal(lower,j)
   var slope := (profile[row+1].y-profile[row].y)/(profile[row+1].x-profile[row].x)
   n1 = (n1+Vector3.UP*slope).normalized()
   n2 = (n2+Vector3.UP*slope).normalized()
   quad(surface,[a,b,c,d],[n1,n2,n2,n1])
 for row in [0,profile.size()-1]:
  var ring := outline(width-profile[row].y*2,depth-profile[row].y*2,maxf(1,radius-profile[row].y))
  var n := Vector3.UP if row>0 else Vector3.DOWN
  for i in range(ring.size()):
   var j := (i+1)%ring.size()
   triangle(surface,[Vector3(0,profile[row].x,0),Vector3(ring[i].x,profile[row].x,ring[i].y),Vector3(ring[j].x,profile[row].x,ring[j].y)],[n,n,n])
 cache[key] = surface.commit()
 return cache[key]

static func inlay_ring(width: float, depth: float, inset: float, thickness: float) -> ArrayMesh:
 var key := "inlay"+str(Vector3(width,depth,inset))+str(thickness)
 if cache.has(key): return cache[key]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var radius := minf(width,depth)*0.075
 var outer := outline(width-inset*2,depth-inset*2,maxf(1,radius-inset))
 var inner := outline(width-(inset+thickness)*2,depth-(inset+thickness)*2,maxf(0.8,radius-inset-thickness))
 for i in range(outer.size()):
  var j := (i+1)%outer.size()
  quad(surface,[Vector3(outer[i].x,0,outer[i].y),Vector3(outer[j].x,0,outer[j].y),Vector3(inner[j].x,0,inner[j].y),Vector3(inner[i].x,0,inner[i].y)],[Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP])
 cache[key] = surface.commit()
 return cache[key]

static func lathe(profile: PackedVector2Array) -> ArrayMesh:
 var key := "lathe"+str(profile)
 if cache.has(key): return cache[key]
 profile = smooth_profile(profile)
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 const SEGMENTS := 64
 for row in range(profile.size()-1):
  var before := maxi(0,row-1)
  var after := mini(profile.size()-1,row+2)
  var slope1 := (profile[row+1].y-profile[before].y)/(profile[row+1].x-profile[before].x)
  var slope2 := (profile[after].y-profile[row].y)/(profile[after].x-profile[row].x)
  for i in range(SEGMENTS):
   var a := i*TAU/SEGMENTS
   var b := (i+1)*TAU/SEGMENTS
   var r1 := profile[row].y
   var r2 := profile[row+1].y
   var n1 := Vector3(cos(a),-slope1,sin(a)).normalized()
   var n2 := Vector3(cos(b),-slope1,sin(b)).normalized()
   var n3 := Vector3(cos(b),-slope2,sin(b)).normalized()
   var n4 := Vector3(cos(a),-slope2,sin(a)).normalized()
   quad(surface,[Vector3(cos(a)*r1,profile[row].x,sin(a)*r1),Vector3(cos(b)*r1,profile[row].x,sin(b)*r1),Vector3(cos(b)*r2,profile[row+1].x,sin(b)*r2),Vector3(cos(a)*r2,profile[row+1].x,sin(a)*r2)],[n1,n2,n3,n4])
 for row in [0,profile.size()-1]:
  var n := Vector3.DOWN if row==0 else Vector3.UP
  for i in range(SEGMENTS):
   var a := i*TAU/SEGMENTS
   var b := (i+1)*TAU/SEGMENTS
   triangle(surface,[Vector3(0,profile[row].x,0),Vector3(cos(a)*profile[row].y,profile[row].x,sin(a)*profile[row].y),Vector3(cos(b)*profile[row].y,profile[row].x,sin(b)*profile[row].y)],[n,n,n])
 cache[key] = surface.commit()
 return cache[key]

static func smooth_profile(profile: PackedVector2Array) -> PackedVector2Array:
 var result := PackedVector2Array()
 for i in range(profile.size()-1):
  var a := profile[i]
  var b := profile[i+1]
  var slope := (b.y-a.y)/(b.x-a.x)
  var ma := slope
  var mb := slope
  if i>0:
   var prior := (a.y-profile[i-1].y)/(a.x-profile[i-1].x)
   ma = 2*prior*slope/(prior+slope) if prior*slope>0 else 0.0
  if i+2<profile.size():
   var next := (profile[i+2].y-b.y)/(profile[i+2].x-b.x)
   mb = 2*next*slope/(next+slope) if next*slope>0 else 0.0
  for j in range(4):
   var t := float(j)/4
   var r := (2*t*t*t-3*t*t+1)*a.y+(t*t*t-2*t*t+t)*ma*(b.x-a.x)+(-2*t*t*t+3*t*t)*b.y+(t*t*t-t*t)*mb*(b.x-a.x)
   result.append(Vector2(lerpf(a.x,b.x,t),r))
 result.append(profile[-1])
 return result

static func outline_normal(ring: PackedVector2Array, i: int) -> Vector3:
 var tangent := ring[(i+1)%ring.size()]-ring[(i+ring.size()-1)%ring.size()]
 return Vector3(tangent.y,0,-tangent.x).normalized()

static func apron(width: float, height: float, depth: float) -> ArrayMesh:
 var key := "apron"+str(Vector3(width,height,depth))
 if cache.has(key): return cache[key]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 const STEPS := 32
 for segment in range(STEPS):
  var sections: Array = []
  for end in [segment,segment+1]:
   var t := float(end)/STEPS*2-1
   var bottom := -height*0.5+height*0.35*(1-t*t)
   var top := height*0.5
   sections.append(outline(top-bottom,depth,0.55,5))
  for i in range(sections[0].size()):
   var points: Array[Vector3] = []
   var normals: Array[Vector3] = []
   var j: int = (i+1)%sections[0].size()
   for corner in [Vector2i(0,i),Vector2i(0,j),Vector2i(1,j),Vector2i(1,i)]:
    var t := float(segment+corner.x)/STEPS*2-1
    var bottom := -height*0.5+height*0.35*(1-t*t)
    var top := height*0.5
    var q: Vector2 = sections[corner.x][corner.y]
    var point := Vector3(t*width*0.5,(top+bottom)*0.5+q.x,q.y)
    var inner := Vector2((top-bottom)*0.5-0.55,depth*0.5-0.55)
    var normal2 := (q-q.clamp(-inner,inner)).normalized()
    var slope := -height*0.7*t/(width*0.5)*(top-point.y)/(top-bottom)
    points.append(point)
    normals.append(Vector3(-slope*normal2.x,normal2.x,normal2.y).normalized())
   quad(surface,points,normals)
 for side in [-1,1]:
  var ring := outline(height,depth,0.55,5)
  var n := Vector3(side,0,0)
  for i in range(ring.size()):
   var j := (i+1)%ring.size()
   triangle(surface,[Vector3(side*width*0.5,0,0),Vector3(side*width*0.5,ring[i].x,ring[i].y),Vector3(side*width*0.5,ring[j].x,ring[j].y)],[n,n,n])
 cache[key] = surface.commit()
 return cache[key]

static func arm(width: float, height: float, length: float) -> ArrayMesh:
 var key := "arm"+str(Vector3(width,height,length))
 if cache.has(key): return cache[key]
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 const ROWS := 84
 const SIDES := 48
 for row in range(ROWS):
  for side in range(SIDES):
   var points: Array[Vector3] = []
   var normals: Array[Vector3] = []
   for corner in [Vector2i(row,side),Vector2i(row,side+1),Vector2i(row+1,side+1),Vector2i(row+1,side)]:
    var t := float(corner.x)/ROWS
    var a: float = corner.y*TAU/SIDES
    var point := arm_point(t,a,width,height,length)
    var n := Vector3(0,0,-1 if t<0.5 else 1)
    if t>0 and t<1:
     var across := arm_point(t,a+0.01,width,height,length)-arm_point(t,a-0.01,width,height,length)
     var along := arm_point(t+0.001,a,width,height,length)-arm_point(t-0.001,a,width,height,length)
     n = across.cross(along).normalized()
    points.append(point)
    normals.append(n)
   quad(surface,points,normals)
 cache[key] = surface.commit()
 return cache[key]

static func arm_point(t: float, a: float, width: float, height: float, length: float) -> Vector3:
 var envelope := 1.0
 if t<0.12: envelope = sqrt(maxf(0,1-pow(1-t/0.12,2)))
 elif t>0.88: envelope = sqrt(maxf(0,1-pow((t-0.88)/0.12,2)))
 return Vector3(cos(a)*width*0.5*envelope,4*t+sin(t*PI)*1.8+sin(a)*height*0.5*envelope,(t-0.5)*length)

static func outline(width: float, depth: float, radius: float, steps: int = 16) -> PackedVector2Array:
 var result := PackedVector2Array()
 var hx := width*0.5-radius
 var hz := depth*0.5-radius
 var centres := [Vector2(hx,-hz),Vector2(hx,hz),Vector2(-hx,hz),Vector2(-hx,-hz)]
 for corner in range(4):
  for step in range(steps+1):
   var angle := -PI/2+corner*PI/2+float(step)*PI/(steps*2)
   result.append(centres[corner]+Vector2(cos(angle),sin(angle))*radius)
 return result

static func quad(surface: SurfaceTool, points: Array[Vector3], normals: Array[Vector3]) -> void:
 triangle(surface,[points[0],points[1],points[2]],[normals[0],normals[1],normals[2]])
 triangle(surface,[points[0],points[2],points[3]],[normals[0],normals[2],normals[3]])

static func triangle(surface: SurfaceTool, points: Array[Vector3], normals: Array[Vector3]) -> void:
 var cross_product := (points[1]-points[0]).cross(points[2]-points[0])
 if cross_product.length_squared()<0.00000001: return
 var order := [0,2,1] if cross_product.dot(normals[0]+normals[1]+normals[2])>0 else [0,1,2]
 for i in order:
  surface.set_normal(normals[i])
  surface.set_uv(Vector2(points[i].z,points[i].x)/80.0)
  surface.add_vertex(points[i])
