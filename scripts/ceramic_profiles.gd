extends RefCounted
## Closed-section, open-bowl lathed ceramics, in centimetres.
static func cup_mesh() -> ArrayMesh:
 return lathe([Vector2(0.02,0.7),Vector2(3.45,0.7),Vector2(3.8,0.9),Vector2(4.0,1.3),Vector2(4.2,2.5),Vector2(4.55,6.5),Vector2(4.7,7.9),Vector2(4.67,8.2),Vector2(4.5,8.35),Vector2(4.3,8.2),Vector2(4.25,7.95),Vector2(4.15,6.5),Vector2(3.85,2.4),Vector2(3.6,1.5),Vector2(3.3,1.3),Vector2(0.02,1.3)])

static func saucer_mesh() -> ArrayMesh:
 return lathe([Vector2(0.02,0.06),Vector2(4.2,0.06),Vector2(5.4,0.17),Vector2(6.3,0.4),Vector2(6.55,0.65),Vector2(6.45,0.82),Vector2(6.2,0.8),Vector2(5.4,0.6),Vector2(4.2,0.4),Vector2(0.02,0.4)])

static func plate_mesh() -> ArrayMesh:
 return lathe([Vector2(0.02,0.05),Vector2(14,0.05),Vector2(14.5,-0.15),Vector2(15.4,-0.15),Vector2(15.9,0.05),Vector2(20,0.2),Vector2(24,1.0),Vector2(24.8,1.2),Vector2(25,1.45),Vector2(24.9,1.65),Vector2(24.4,1.7),Vector2(23.5,1.55),Vector2(19,0.6),Vector2(17,0.4),Vector2(0.02,0.4)])

static func lathe(profile: Array[Vector2]) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 var segments := 128
 for row in range(profile.size()-1):
  for j in range(segments):
   for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
    var i: int = row+corner.y
    var a := float(j+corner.x)*TAU/segments
    var point := profile[i]
    var tangent := profile[mini(i+1,profile.size()-1)]-profile[maxi(i-1,0)]
    surface.set_normal(Vector3(tangent.y*cos(a),-tangent.x,tangent.y*sin(a)).normalized())
    surface.set_uv(Vector2(float(j+corner.x)/segments,float(i)/(profile.size()-1)))
    surface.add_vertex(Vector3(cos(a)*point.x,point.y,sin(a)*point.x))
 return surface.commit()
