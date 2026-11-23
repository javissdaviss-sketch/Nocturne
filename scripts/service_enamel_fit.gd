extends RefCounted
## A dressed, stationary cupboard interior. No moving door, evidence, lower
## cable opening, contact point, cue, light or executable route lives here.
const Geometry=preload("res://scripts/crafted_geometry.gd")
const Finishes=preload("res://scripts/material_library.gd")
const MIN_Z:=1411.5
const MAX_Z:=1540.5
const TOP:=36.5
const SHELF_PROFILE:=[Vector2(83.50,34.55),Vector2(83.62,34.0),Vector2(84.05,33.68),
 Vector2(84.80,33.55),Vector2(159.96,33.5),Vector2(160.45,33.84),Vector2(160.5,36.11),
 Vector2(160.07,TOP),Vector2(84.82,TOP),Vector2(84.24,36.37),Vector2(83.79,36.12),Vector2(83.51,35.72)]

static func install(world:Node3D)->Node3D:
 var inner:=Node3D.new()
 inner.name="StationaryCupboardLining"
 world.add_child(inner)
 var tray:MeshInstance3D=world.mesh_obj(inner,pressed_tray(),Vector3.ZERO,Color.WHITE)
 tray.name="OriginalLevelPressedShelf"
 tray.material_override=null  # two real surface finishes follow the fold
 tray.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON  # original shelf cast
 # A fine join gives the large back wall a real depth cue. The two liner
 # inserts are backed by the existing shell at x157; they sit far behind
 # both spool and evidence and entirely above the under-shelf access.
 for z in [1448.0,1506.0]:
  var lining:MeshInstance3D=world.mesh_obj(inner,Geometry.rounded_box(Vector3(0.43,44,57.5),0.16),
   Vector3(157.1,60,z),Color("57716a"))
  lining.name="FormedBackEnamel"
  lining.material_override=Finishes.make(Finishes.Finish.STEEL,Color("57716a"),false,false,true)
  lining.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return inner

static func pressed_tray()->ArrayMesh:
 var dark:=SurfaceTool.new()
 var lip:=SurfaceTool.new()
 dark.begin(Mesh.PRIMITIVE_TRIANGLES)
 lip.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in range(SHELF_PROFILE.size()):
  var a:Vector2=SHELF_PROFILE[i]
  var b:Vector2=SHELF_PROFILE[(i+1)%SHELF_PROFILE.size()]
  var outward:=Vector3(b.y-a.y,a.x-b.x,0).normalized()
  var p0:=Vector3(a.x,a.y,MIN_Z)
  var p1:=Vector3(b.x,b.y,MIN_Z)
  var p2:=Vector3(b.x,b.y,MAX_Z)
  var p3:=Vector3(a.x,a.y,MAX_Z)
  var stream:=lip if i<3 or i>=9 else dark
  surface(stream,p0,p1,p2,outward)
  surface(stream,p0,p2,p3,outward)
  for z in [MIN_Z,MAX_Z]:
   var face:=Vector3.FORWARD if z==MIN_Z else Vector3.BACK
   surface(dark,Vector3(a.x,a.y,z),Vector3(b.x,b.y,z),Vector3(122,35,z),face)
 var mesh:=dark.commit()
 lip.commit(mesh)
 mesh.set_meta("solid_geometry_convex",true)
 mesh.surface_set_material(0,Finishes.make(Finishes.Finish.STEEL,Color("426762"),false,false,true))
 mesh.surface_set_material(1,Finishes.make(Finishes.Finish.STEEL,Color("77908a"),false,false,false))
 return mesh

static func surface(st:SurfaceTool,a:Vector3,b:Vector3,c:Vector3,outward:Vector3)->void:
 var order:=[a,c,b] if (b-a).cross(c-a).dot(outward)>0 else [a,b,c]
 for pos:Vector3 in order:
  st.set_normal(outward)
  st.set_uv(Vector2((pos.x-80)/80,(pos.z-MIN_Z)/(MAX_Z-MIN_Z)))
  st.add_vertex(pos)
