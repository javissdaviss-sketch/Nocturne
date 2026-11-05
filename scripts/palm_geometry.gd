extends RefCounted
## Organic palm surfaces with the original crown and collision envelope preserved.
const Crafted = preload("res://scripts/crafted_geometry.gd")
static var bark: StandardMaterial3D

static func bark_material() -> StandardMaterial3D:
 if bark == null:
  bark = StandardMaterial3D.new()
  bark.albedo_color = Color("4e5139")
  bark.vertex_color_use_as_albedo = true
  bark.roughness = 0.88
  bark.metallic_specular = 0.18
 return bark

static func cane_point(t: float, a: float, height: float) -> Vector3:
 # The cane stays within 0.4 cm of its original axis; its Y90 radius stays >2.4cm.
 var radius := lerpf(3.35,2.42,t)+sin(t*67.0+sin(t*13.0))*0.055
 radius += sin(a*7.0+t*4.0)*0.045
 return Vector3(sin(a)*radius+sin(t*PI)*0.32,28+t*(height-28),cos(a)*radius+sin(t*PI)*0.42)

static func cane(height: float) -> ArrayMesh:
 var surface := SurfaceTool.new()
 surface.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(72):
  for side in range(28):
   for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var t := float(row+corner.y)/72
    var a := float(side+corner.x)*TAU/28
    var point := cane_point(t,a,height)
    var around := cane_point(t,a+0.01,height)-cane_point(t,a-0.01,height)
    var upward := cane_point(minf(1,t+0.002),a,height)-cane_point(maxf(0,t-0.002),a,height)
    var normal := around.cross(upward).normalized()
    var scar := pow(0.5+0.5*sin(t*67.0+sin(t*13.0)),16)
    var fiber := sin(a*31+t*3.0)*0.025
    surface.set_color(Color.WHITE*(0.94-scar*0.12+fiber))
    surface.set_normal(normal)
    surface.set_uv(Vector2(a/TAU,t))
    surface.add_vertex(point)
 return surface.commit()

static func spine(t: float, length: float, lift: float) -> Vector3:
 return Vector3(sin(t*PI)*length*0.055,lift*sin(t*PI*0.9)-length*0.40*t*t,length*t)

static func rib(length: float, lift: float) -> ArrayMesh:
 var path: Array[Vector3] = []
 var radii: Array[float] = []
 for i in range(21):
  var t := float(i)/20
  path.append(spine(t,length,lift))
  radii.append(lerpf(0.38,0.09,t))
 return Crafted.tube(path,radii,10)

static func blade(surface: SurfaceTool, base: Vector3, tip: Vector3, width: float, stripe: float, phase: float) -> void:
 var delta := tip-base
 var across := delta.normalized().cross(Vector3.UP).normalized()
 var length := delta.length()
 for segment in range(12):
  for strip in range(4):
   for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var t := float(segment+corner.y)/12
    var edge := float(strip+corner.x)/2-1.0
    var half_width := width*pow(maxf(0,sin(t*PI)),0.82)*(1.08-0.15*t)*0.5
    var centre := base+delta*t+Vector3.UP*(sin(t*PI)*length*0.075-pow(t,4)*length*0.09)
    centre += across*sin(t*PI)*length*0.018*sin(phase)
    var cup := -pow(absf(edge),1.5)*half_width*0.30
    var roll := pow(absf(edge),5)*half_width*0.12*sin(t*PI*1.5+phase)
    var twist := edge*sin(t*PI)*width*0.045*cos(phase)
    surface.set_uv(Vector2(stripe+edge*0.055,t))
    surface.add_vertex(centre+across*edge*half_width+Vector3.UP*(cup+roll+twist))
