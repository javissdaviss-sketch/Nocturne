extends RefCounted
## Reusable, centimetre-scale modeled prop meshes. Hollow pieces stay hollow.

static func rounded(size: Vector3, radius: float) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var half := size*0.5
 radius = minf(radius,minf(half.x,minf(half.y,half.z))*0.98)
 var inner := half-Vector3.ONE*radius
 for axis in range(3):
  var u := (axis+1)%3
  var v := (axis+2)%3
  var us := rounded_knots(half[u],radius)
  var vs := rounded_knots(half[v],radius)
  for side in [-1,1]:
   for row in range(vs.size()-1):
    for column in range(us.size()-1):
     var points: Array[Vector3] = []
     var normals: Array[Vector3] = []
     for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
      var point := Vector3.ZERO
      point[axis] = half[axis]*side
      point[u] = us[column+corner.x]
      point[v] = vs[row+corner.y]
      var nearest := point.clamp(-inner,inner)
      var normal := (point-nearest).normalized()
      points.append(nearest+normal*radius)
      normals.append(normal)
     quad(surface,points,normals)
 var mesh := surface.commit()
 mesh.set_meta("solid_geometry_convex",true)
 return mesh

static func rounded_knots(half: float, radius: float) -> PackedFloat32Array:
 var values := PackedFloat32Array()
 for i in range(7): values.append(-half+radius*float(i)/6.0)
 values.append(half-radius)
 for i in range(1,7): values.append(half-radius+radius*float(i)/6.0)
 return values

static func quad(surface: SurfaceTool, points: Array[Vector3], normals: Array[Vector3]) -> void:
 var normal := normals[0]+normals[1]+normals[2]+normals[3]
 var order := [0,2,1,0,3,2] if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal) > 0 else [0,1,2,0,2,3]
 for i in order:
  surface.set_normal(normals[i])
  surface.set_uv(Vector2(points[i].x+points[i].z,points[i].y)*0.1)
  surface.add_vertex(points[i])

static func tube(path: Array[Vector3], radii: PackedFloat32Array, sides: int = 20, hollow: bool = false) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for layer in range(2 if hollow else 1):
  for row in range(path.size()-1):
   for column in range(sides):
    var points: Array[Vector3] = []
    var normals: Array[Vector3] = []
    for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
     var i: int = row+corner.y
     var tangent := (path[mini(i+1,path.size()-1)]-path[maxi(i-1,0)]).normalized()
     var reference := Vector3.FORWARD if absf(tangent.z)<0.9 else Vector3.RIGHT
     var u := tangent.cross(reference).normalized()
     var v := tangent.cross(u).normalized()
     var a := float(column+corner.x)*TAU/sides
     var normal := u*cos(a)+v*sin(a)
     var radius := radii[mini(i,radii.size()-1)]
     points.append(path[i]+normal*(radius-(minf(radius*0.25,0.25) if layer == 1 else 0.0)))
     normals.append(normal*(-1 if layer == 1 else 1))
    quad(surface,points,normals)
 # End annuli join the inside and outside at a genuine open mouth.
 if hollow:
  for end in [0,path.size()-1]:
   var tangent := (path[1]-path[0]).normalized() if end == 0 else (path[end]-path[end-1]).normalized()
   var reference := Vector3.FORWARD if absf(tangent.z)<0.9 else Vector3.RIGHT
   var u := tangent.cross(reference).normalized()
   var v := tangent.cross(u).normalized()
   var radius := radii[mini(end,radii.size()-1)]
   for j in range(sides):
    var points: Array[Vector3] = []
    for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
     var a := float(j+corner.x)*TAU/sides
     var r := radius-(minf(radius*0.25,0.25) if corner.y == 1 else 0.0)
     points.append(path[end]+(u*cos(a)+v*sin(a))*r)
    var n := tangent*(-1 if end == 0 else 1)
    quad(surface,points,[n,n,n,n])
 return surface.commit()

static func rounded_loop(width: float, depth: float, radius: float, tube_radius: float = 0.15) -> ArrayMesh:
 var path: Array[Vector3] = []
 for corner in range(4):
  var center := [Vector2(-width*0.5+radius,-depth*0.5+radius),Vector2(width*0.5-radius,-depth*0.5+radius),Vector2(width*0.5-radius,depth*0.5-radius),Vector2(-width*0.5+radius,depth*0.5-radius)][corner] as Vector2
  for j in range(13):
   var a: float = [-PI,-PI/2,0.0,PI/2][corner]+float(j)*PI/24
   path.append(Vector3(center.x+cos(a)*radius,0,center.y+sin(a)*radius))
 path.append(path[0])
 return tube(path,PackedFloat32Array([tube_radius]),12)

static func linen(width: float, depth: float, height: float = 1.2) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var nx := 24
 var nz := 30
 for layer in [0,1]:
  for x in range(nx):
   for z in range(nz):
    var points: Array[Vector3] = []
    var normals: Array[Vector3] = []
    for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
     var u := float(x+corner.x)/nx
     var v := float(z+corner.y)/nz
     var y := linen_height(u,v,height)
     var du := (linen_height(u+0.002,v,height)-linen_height(u-0.002,v,height))/(0.004*width)
     var dv := (linen_height(u,v+0.002,height)-linen_height(u,v-0.002,height))/(0.004*depth)
     points.append(Vector3((u-0.5)*width,y-float(layer)*0.12,(v-0.5)*depth))
     normals.append(Vector3(-du,1,-dv).normalized()*(1 if layer == 0 else -1))
    quad(surface,points,normals)
 return surface.commit()

static func linen_height(u: float, v: float, height: float) -> float:
 return 0.23+height*(0.40+0.30*sin(u*PI)+0.28*exp(-pow((u-0.70)*10.0,2)))*sin(v*PI*0.78+0.15)+0.09*sin(v*27+u*8)*pow(absf(u-0.5)*2,3)

static func lathe(profile: Array[Vector2], smooth_profile: bool = false) -> ArrayMesh:
 if not smooth_profile: return preload("res://scripts/ceramic_profiles.gd").lathe(profile)
 var smooth: Array[Vector2] = []
 for i in range(profile.size()-1):
  var a := profile[maxi(i-1,0)]
  var b := profile[i]
  var c := profile[i+1]
  var d := profile[mini(i+2,profile.size()-1)]
  for j in range(6):
   var t := float(j)/6
   var point := 0.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t)
   point.x = maxf(point.x,0.02)
   smooth.append(point)
 smooth.append(profile[-1])
 return preload("res://scripts/ceramic_profiles.gd").lathe(smooth)

static func triangle(surface: SurfaceTool, points: Array[Vector3], normals: Array[Vector3]) -> void:
 var order := [0,2,1] if (points[1]-points[0]).cross(points[2]-points[0]).dot(normals[0]+normals[1]+normals[2]) > 0 else [0,1,2]
 for i in order:
  surface.set_normal(normals[i])
  surface.set_uv(Vector2(points[i].x+points[i].z,points[i].y)*0.1)
  surface.add_vertex(points[i])

static func fitted_corner(radius: float, signs: Vector3) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var wing := radius*0.90
 var subdivisions := 20
 for axis in range(3):
  var u := (axis+1)%3
  var v := (axis+2)%3
  for i in range(subdivisions):
   for j in range(subdivisions-i):
    var cells := [[Vector2i(i,j),Vector2i(i+1,j),Vector2i(i,j+1)]]
    if i+j < subdivisions-1: cells.append([Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j+1)])
    for cell in cells:
     var points: Array[Vector3] = []
     var normals: Array[Vector3] = []
     for corner in cell:
      var uv := Vector2(-wing,radius)+Vector2(radius+wing,-wing-radius)*float(corner.x)/subdivisions+Vector2(radius+wing,0)*float(corner.y)/subdivisions
      var point := Vector3.ZERO
      point[axis] = radius
      point[u] = uv.x
      point[v] = uv.y
      var nearest := Vector3(minf(point.x,0),minf(point.y,0),minf(point.z,0))
      var normal := (point-nearest).normalized()
      points.append((nearest+normal*(radius+0.08))*signs)
      normals.append(normal*signs)
     triangle(surface,points,normals)
 return surface.commit()

static func bread() -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rows := 48
 var columns := 96
 for row in range(rows):
  for column in range(columns):
   for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var phi := float(row+corner.y)*PI/rows
    var theta := float(column+corner.x)*TAU/columns
    var irregular := 1.0+0.025*sin(theta*5+phi*3)+0.018*sin(theta*9-phi*4)
    var point := Vector3(sin(phi)*cos(theta)*4.5,cos(phi)*3.75,sin(phi)*sin(theta)*6.5)*irregular
    var cuts := 0.0
    for z in [-3.0,0.0,3.0]:
     cuts += exp(-pow((point.z-z+point.x*0.12)*3.2,2))*exp(-pow(point.x/2.9,6))
    cuts *= smoothstep(0.3,2.0,point.y)
    point.y -= cuts*0.62
    point.y = maxf(point.y,-3.0)
    surface.set_color(Color.WHITE.lerp(Color("e1bb83"),minf(cuts,1.0)))
    surface.set_uv(Vector2(float(column+corner.x)/columns,float(row+corner.y)/rows))
    surface.add_vertex(point)
 surface.generate_normals()
 return surface.commit()

static func arched_shade(length: float, depth: float, height: float) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for layer in [0,1]:
  var radius: float = depth*0.5-float(layer)*0.3
  var h: float = height-float(layer)*0.3
  for j in range(48):
   var points: Array[Vector3] = []
   var normals: Array[Vector3] = []
   for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var a := float(j+corner.y)*PI/48
    points.append(Vector3((corner.x-0.5)*length,sin(a)*h,cos(a)*radius))
    normals.append(Vector3(0,sin(a)/h,cos(a)/radius).normalized()*(1 if layer == 0 else -1))
   quad(surface,points,normals)
 for side in [-1,1]:
  for j in range(48):
   var points: Array[Vector3] = []
   for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var a := float(j+corner.x)*PI/48
    points.append(Vector3(side*length*0.5,sin(a)*(height-corner.y*0.3),cos(a)*(depth*0.5-corner.y*0.3)))
   var n := Vector3(side,0,0)
   quad(surface,points,[n,n,n,n])
 return surface.commit()
