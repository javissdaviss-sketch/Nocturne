extends RefCounted
## Reusable manufactured edge profiles and curved continuous tubes, in cm.
static var cache: Dictionary = {}

static func rounded_box(size: Vector3, radius: float) -> ArrayMesh:
 var key := str(size)+":"+str(radius)
 if cache.has(key): return cache[key]
 var half := size*0.5
 var r := minf(radius,minf(half.x,minf(half.y,half.z))*0.95)
 var inner := half-Vector3.ONE*r
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for axis in range(3):
  var u := (axis+1)%3
  var v := (axis+2)%3
  var us := knots(half[u],r)
  var vs := knots(half[v],r)
  for side in [-1,1]:
   for row in range(vs.size()-1):
    for col in range(us.size()-1):
     for index in ([0,2,1,0,3,2] if side > 0 else [0,1,2,0,2,3]):
      var corner: Vector2i = [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)][index]
      var q := Vector3.ZERO
      q[axis] = half[axis]*side
      q[u] = us[col+corner.x]
      q[v] = vs[row+corner.y]
      var nearest := q.clamp(-inner,inner)
      var normal := (q-nearest).normalized()
      var point := nearest+normal*r
      surface.set_normal(normal)
      surface.set_uv(Vector2(point[u],point[v])/40.0)
      surface.add_vertex(point)
 var mesh := surface.commit()
 mesh.set_meta("solid_geometry_convex",true)
 cache[key] = mesh
 return mesh

static func knots(half: float, radius: float) -> PackedFloat32Array:
 var values := PackedFloat32Array()
 for i in range(7): values.append(-half+radius*float(i)/6.0)
 for i in range(7): values.append(half-radius+radius*float(i)/6.0)
 return values

static func tube(path: Array[Vector3], radii: Array[float], sides: int = 20) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var rings: Array[PackedVector3Array] = []
 var normals: Array[PackedVector3Array] = []
 for i in range(path.size()):
  var tangent := (path[mini(i+1,path.size()-1)]-path[maxi(0,i-1)]).normalized()
  var across := tangent.cross(Vector3.FORWARD).normalized()
  if across.length_squared() < 0.2: across = tangent.cross(Vector3.RIGHT).normalized()
  var other := tangent.cross(across).normalized()
  var ring := PackedVector3Array()
  var ns := PackedVector3Array()
  for j in range(sides+1):
   var a := float(j)*TAU/sides
   var normal := across*cos(a)+other*sin(a)
   ring.append(path[i]+normal*radii[i])
   ns.append(normal)
  rings.append(ring)
  normals.append(ns)
 for i in range(path.size()-1):
  for j in range(sides):
   for index in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var row: int = i+index.y
    var col: int = j+index.x
    surface.set_normal(normals[row][col])
    surface.set_uv(Vector2(float(col)/sides,float(row)/(path.size()-1)))
    surface.add_vertex(rings[row][col])
 return surface.commit()

static func arc_label(radius: float, height: float, width_angle: float) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for j in range(48):
  for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
   var u := float(j+corner.x)/48
   var a := -PI/2+(u-0.5)*width_angle
   surface.set_normal(Vector3(cos(a),0,sin(a)))
   surface.set_uv(Vector2(u,float(corner.y)))
   surface.add_vertex(Vector3(cos(a)*radius,(corner.y-0.5)*height,sin(a)*radius))
 return surface.commit()
