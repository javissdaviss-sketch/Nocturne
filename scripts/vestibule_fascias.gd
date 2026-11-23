extends RefCounted
## Only projecting joinery is new. The full original carriage shell, floor,
## ceiling and unaltered through aisle remain as separate structural contacts.
const Finishes := preload("res://scripts/material_library.gd")
const Identity := preload("res://scripts/room_identity.gd")

static func dress(world: Node3D, end_z: float, garden: bool, from_rear: bool, depth_scale: float = 1.0) -> void:
 var root := Node3D.new()
 root.name = "ArchiveRibbedVestibule" if garden else "MeridianSteppedVestibule"
 world.add_child(root)
 root.position.z = end_z
 if from_rear: root.rotation.y = PI
 var frame := SurfaceTool.new()
 var detail := SurfaceTool.new()
 frame.begin(Mesh.PRIMITIVE_TRIANGLES)
 detail.begin(Mesh.PRIMITIVE_TRIANGLES)
 if garden:
  # A low-slung elliptical profile after the salon; one genuine swept inner
  # return over the opening, with separate ribs on both curtain walls.
  for i in range(3):
   Identity.arch(frame,Vector2(0,223.1+i*2),69-i*2.65,34-i*2,32-i*1.9,2.3,5.8+i*0.39)
   Identity.arch(detail,Vector2(0,225.5+i*2),67.85-i*2.70,33-i*2,31-i*1.9,0.79,6.35+i*0.39)
  Identity.rail(detail,Vector2(-52,229),Vector2(52,229),1.08,5.55)
 else:
  # Mirrored stepped corners around a broad flat Deco lintel instead of
  # sending additional render-visible box edges across the doorway.
  Identity.stamp(frame,[Vector2(-69,225),Vector2(69,225),Vector2(69,238),Vector2(62,238),Vector2(62,247),Vector2(51,247),Vector2(51,253),Vector2(-51,253),Vector2(-51,247),Vector2(-62,247),Vector2(-62,238),Vector2(-69,238)],5.9)
  for j in range(3): Identity.rail(detail,Vector2(-55+j*5,230+j*7.0),Vector2(55-j*5,230+j*7.0),1.25,6.3+j*0.15)
 for side in [-1,1]:
  # Even the outside-facing base stays outside abs(x)=55. The board and the
  # actual collision agree; nothing decorative narrows the corridor.
  Identity.chamfer_slab(frame,Vector2(side*61,115),Vector2(11.5,223),3.6,5.45)
  Identity.chamfer_slab(frame,Vector2(side*61,8),Vector2(11.5,12),2.7,6.4)
  for x in [58.5,62.5,64.5]:
   Identity.rail(detail,Vector2(side*x,16),Vector2(side*x,225.5),0.58 if garden else 0.78,5.9 if garden else 5.8)
 for slot in [0,1]:
  var surface := frame if slot==0 else detail
  var finish := Finishes.Finish.WALNUT if slot==0 else Finishes.Finish.BRASS
  var tint := Color("4b5b51") if garden else Color("634635")
  if slot==1: tint = Color("a7956e") if garden else Color("a08257")
  var finished := surface.commit()
  if depth_scale < 1.0:
   var raw := finished.surface_get_arrays(0)
   var vertices: PackedVector3Array = raw[Mesh.ARRAY_VERTEX]
   var normals: PackedVector3Array = raw[Mesh.ARRAY_NORMAL]
   for i in range(vertices.size()):
    vertices[i].z *= depth_scale
    normals[i] = Vector3(normals[i].x,normals[i].y,normals[i].z/depth_scale).normalized()
   raw[Mesh.ARRAY_VERTEX] = vertices
   raw[Mesh.ARRAY_NORMAL] = normals
   finished = ArrayMesh.new()
   finished.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,raw)
  var object: MeshInstance3D = world.mesh_obj(root,finished,Vector3.ZERO,tint,true)
  object.name = "SculptedTimber" if slot==0 else "WorkedMetal"
  object.material_override = Finishes.make(finish,tint)
  object.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
