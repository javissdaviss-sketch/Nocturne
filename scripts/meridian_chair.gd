extends RefCounted
## A shaped walnut shell and crowned velvet upholstery, kept inside the chair's
## original reach envelope. All centimetres. Local -Z faces the table.

const PropMeshes := preload("res://scripts/prop_meshes.gd")
const STEPS := 40
# From front face through the bevel to the back. The smaller ratios at the
# shoulders draw the upper silhouette inward without moving the legs or arms.
const SHELL := [
 Vector2(0.0,22.0),Vector2(0.55,21.35),Vector2(0.90,21.25),Vector2(0.97,22.4),
 Vector2(1.0,24.15),Vector2(1.0,27.05),Vector2(0.98,29.0),Vector2(0.92,30.1),
 Vector2(0.65,31.2),Vector2(0.0,31.65)
]
const PAD := [
 Vector2(0.0,17.6),Vector2(0.25,17.45),Vector2(0.53,17.6),Vector2(0.72,17.95),
 Vector2(0.82,18.6),Vector2(0.88,19.55),Vector2(0.89,20.75),Vector2(0.86,22.0),
 Vector2(0.73,22.6),Vector2(0.0,23.15)
]

static func section_point(angle: float, row: Vector2, pad: bool) -> Vector3:
 var ss := sin(angle)
 var cc := cos(angle)
 var y := signf(ss)*pow(absf(ss),0.78)*28.9*row.x
 var x := signf(cc)*pow(absf(cc),0.72)*(30.4-3.3*ss)*row.x
 var bow := 1.75*pow(absf(x)/32.0,1.7)
 if pad: bow = -0.65*pow(absf(x)/32.0,1.7)
 var depth := row.y+y*0.061+bow
 if not pad and depth > 23.0: depth = 23.0+(depth-23.0)*0.73
 return Vector3(x,63.5+y,depth)

static func surface_normal(profile: Array, row: int, angle: float, pad: bool) -> Vector3:
 if row == 0: return Vector3(0,0.061,-1).normalized()
 if row == profile.size()-1: return Vector3(0,-0.061,1).normalized()
 var tangent := section_point(angle+0.002,profile[row],pad)-section_point(angle-0.002,profile[row],pad)
 var cross_section := section_point(angle,profile[row+1],pad)-section_point(angle,profile[row-1],pad)
 return tangent.cross(cross_section).normalized()

static func body(pad: bool) -> ArrayMesh:
 var profile := PAD if pad else SHELL
 var st := SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(profile.size()-1):
  for i in range(STEPS):
   var a := TAU*float(i)/STEPS
   var b := TAU*float(i+1)/STEPS
   var corners := [
    Vector2(a,row),Vector2(b,row),Vector2(b,row+1),Vector2(a,row+1),
   ]
   var points: Array[Vector3] = []
   var normals: Array[Vector3] = []
   for corner: Vector2 in corners:
    points.append(section_point(corner.x,profile[int(corner.y)],pad))
    normals.append(surface_normal(profile,int(corner.y),corner.x,pad))
   if row == 0 or row == profile.size()-2:
    var ids := [0,2,3] if row == 0 else [0,1,2]
    stamp_triangle(st,points,normals,ids)
   else:
    stamp_triangle(st,points,normals,[0,1,2])
    stamp_triangle(st,points,normals,[0,2,3])
 return st.commit()

static func stamp_triangle(st: SurfaceTool, points: Array[Vector3], normals: Array[Vector3], ids: Array) -> void:
 var a: int = ids[0]
 var b: int = ids[1]
 var c: int = ids[2]
 if (points[b]-points[a]).cross(points[c]-points[a]).dot(normals[a]+normals[b]+normals[c]) > 0:
  var swap := b
  b = c
  c = swap
 for i: int in [a,b,c]:
  st.set_normal(normals[i])
  st.set_uv(Vector2(points[i].x,points[i].y)*0.01)
  st.add_vertex(points[i])

static func welt() -> ArrayMesh:
 var path: Array[Vector3] = []
 for i in range(STEPS+1):
  var angle := TAU*float(i%STEPS)/STEPS
  path.append(section_point(angle,Vector2(0.846,19.01),true))
 return PropMeshes.tube(path,PackedFloat32Array([0.27]),8)

static func build(world: Node, model: Node3D, velvet: Color, timber: Color) -> void:
 var shell: MeshInstance3D = world.mesh_obj(model,body(false),Vector3.ZERO,timber,true)
 shell.name = "MeridianBookmatchedShell"
 shell.material_override = world.cabin_finish(2,timber)
 var padding: MeshInstance3D = world.mesh_obj(model,body(true),Vector3.ZERO,velvet,true)
 padding.name = "MeridianCrownedShoulder"
 padding.material_override = world.cabin_finish(1,velvet)
 var cord: MeshInstance3D = world.mesh_obj(model,welt(),Vector3.ZERO,velvet.lightened(0.18))
 cord.name = "MeridianInsetWelt"
 cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
