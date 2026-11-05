extends RefCounted
## Rounded padding with shared mesh resources and actual shallow button recesses.
## Dimensions are centimetres; continuous bevel normals avoid faceted highlights.

static func build(size: Vector3, bevel: float, tufted: bool = false, exact_radius: float = -1.0) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var half := size*0.5
 var smallest := minf(size.x,minf(size.y,size.z))
 var radius := minf(maxf(bevel*1.8,smallest*0.35),smallest*0.48)
 if exact_radius >= 0.0: radius = minf(exact_radius,smallest*0.48)
 for axis in range(3):
  var u := (axis+1)%3
  var v := (axis+2)%3
  var segments := 12 if tufted and axis == 2 else 4
  var us := knots(half[u],radius,segments)
  var vs := knots(half[v],radius,segments)
  for side in [-1,1]:
   for row in range(vs.size()-1):
    for column in range(us.size()-1):
     var points: Array[Vector3] = []
     var normals: Array[Vector3] = []
     for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
      var box_point := Vector3.ZERO
      box_point[axis] = half[axis]*side
      box_point[u] = us[column+corner.x]
      box_point[v] = vs[row+corner.y]
      var inner := half-Vector3.ONE*radius
      var nearest := box_point.clamp(-inner,inner)
      var normal := (box_point-nearest).normalized()
      var point := nearest+normal*radius
      if tufted and normal.z < -0.5:
       # Real depressions give the cloth a tensioned, padded profile.
       var depth := 0.0
       var gradient := Vector2.ZERO
       for x in [-18.0,0.0,18.0]:
        for y in [-11.0,10.0]:
         var delta := Vector2(point.x-x,point.y-y)
         var dent := 1.25*exp(-delta.length_squared()/15.0)
         depth += dent
         gradient += delta*(-2.0/15.0)*dent
       point.z += depth
       normal = (normal+Vector3(gradient.x,gradient.y,0)).normalized()
      points.append(point)
      normals.append(normal)
     var order := [0,2,1,0,3,2] if side > 0 else [0,1,2,0,2,3]
     for index in order:
      surface.set_normal(normals[index])
      surface.set_uv(Vector2(points[index][u],points[index][v])*0.05)
      surface.add_vertex(points[index])
 return surface.commit()

static func knots(half: float, radius: float, flat_segments: int) -> PackedFloat32Array:
 var values := PackedFloat32Array()
 var inner := half-radius
 # Six samples on each rounded edge, with fewer across the almost-flat centre.
 for i in range(6): values.append(-half+radius*float(i)/6.0)
 for i in range(flat_segments+1): values.append(lerpf(-inner,inner,float(i)/flat_segments))
 for i in range(1,7): values.append(inner+radius*float(i)/6.0)
 return values
