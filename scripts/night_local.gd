extends Node3D
## A render-only neighbouring train, seen once from a quiet salon perch.
const TRACK_X := -820.0
const SALON_Z := 1135.0
const START_Z := SALON_Z-1200.0
const END_Z := SALON_Z+2300.0
const PASS_SECONDS := 8.4
const HALF_COACH := 480.0
const RIGHT_FACE := 130.0
const INK := Color("111e20")
const TRUE_DARK := Color("0b1517")
const LINING := Color("283433")
const PAINT := Color("263532")
const OCHRE := Color("6f5d49")
const WINDOW_LO := 105.0
const WINDOW_HI := 185.0
const WINDOWS := [[-280.0,118.0],[-120.0,118.0],[40.0,132.0],[200.0,118.0],[360.0,118.0]]
var ambient_enabled := true
var played := false
var in_motion := false
var elapsed := 0.0
var mesh_triangles := 0
var mesh_surfaces := 0

class Batch:
 var points := PackedVector3Array()
 var normals := PackedVector3Array()
 var tints := PackedColorArray()
 func triangle(a: Vector3,b: Vector3,c: Vector3,normal: Vector3,colors: PackedColorArray) -> void:
  points.append_array(PackedVector3Array([a,b,c]))
  normals.append_array(PackedVector3Array([normal,normal,normal]))
  tints.append_array(colors)
 func quad(a: Vector3,b: Vector3,c: Vector3,d: Vector3,normal: Vector3,tint: Color) -> void:
  var colors := PackedColorArray([tint,tint,tint])
  triangle(a,b,c,normal,colors)
  triangle(a,c,d,normal,colors)
 func mesh() -> ArrayMesh:
  var arrays := []
  arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX] = points
  arrays[Mesh.ARRAY_NORMAL] = normals
  arrays[Mesh.ARRAY_COLOR] = tints
  var output := ArrayMesh.new()
  output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  return output

func build() -> void:
 name = "NightLocal"
 set_meta("solid_geometry_exclude",true)
 var body := Batch.new()
 var fittings := Batch.new()
 var through_glass := Batch.new()
 coach(body,fittings,through_glass,0.0,true)
 coach(body,fittings,through_glass,-1040.0,false)
 # Author low-frequency steel tones in the mesh. A full-window triplanar
 # finish cost more at this foreground distance than its texture warranted.
 add_batch("PaintedSteel",body,flat_material())
 add_batch("FramesAndShadow",fittings,flat_material())
 add_batch("CabinLampsAndReader",through_glass,flat_material())
 position = Vector3(TRACK_X,0,START_Z)
 hide()
 set_meta("night_local_budget",{"mesh_surfaces":mesh_surfaces,"triangles":mesh_triangles,"projected_lights":0,"shadow_casters":0})

func flat_material() -> StandardMaterial3D:
 var result := StandardMaterial3D.new()
 result.vertex_color_use_as_albedo = true
 result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
 result.cull_mode = BaseMaterial3D.CULL_DISABLED
 return result

func add_batch(title: String, group: Batch, material: Material) -> void:
 var node := MeshInstance3D.new()
 node.name = title
 node.mesh = group.mesh()
 node.material_override = material
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(node)
 mesh_triangles += group.points.size()/3
 mesh_surfaces += node.mesh.get_surface_count()

func block(group: Batch, center: Vector3, size: Vector3,tint: Color) -> void:
 var a := center-size*0.5
 var b := center+size*0.5
 var f0 := Vector3(a.x,a.y,a.z); var f1 := Vector3(b.x,a.y,a.z)
 var f2 := Vector3(b.x,b.y,a.z); var f3 := Vector3(a.x,b.y,a.z)
 var n0 := Vector3(a.x,a.y,b.z); var n1 := Vector3(b.x,a.y,b.z)
 var n2 := Vector3(b.x,b.y,b.z); var n3 := Vector3(a.x,b.y,b.z)
 group.quad(f0,f3,f2,f1,Vector3.FORWARD,tint)
 group.quad(n0,n1,n2,n3,Vector3.BACK,tint)
 group.quad(f1,f2,n2,n1,Vector3.RIGHT,tint)
 group.quad(f0,n0,n3,f3,Vector3.LEFT,tint)
 group.quad(f0,f1,n1,n0,Vector3.DOWN,tint)
 group.quad(f3,n3,n2,f2,Vector3.UP,tint)

func pane(group: Batch,x: float,y0: float,y1: float,z0: float,z1: float,color: Color) -> void:
 group.quad(Vector3(x,y0,z0),Vector3(x,y0,z1),Vector3(x,y1,z1),Vector3(x,y1,z0),Vector3.RIGHT,color)

func roof(group: Batch,travel: float) -> void:
 var front := travel-476
 var rear := travel+476
 var bends := [Vector2(-130,239),Vector2(-119,251),Vector2(-94,259),Vector2(94,259),Vector2(119,251),Vector2(130,239)]
 for i in range(bends.size()-1):
  var a: Vector2 = bends[i]
  var b: Vector2 = bends[i+1]
  var facing := Vector3(a.y-b.y,b.x-a.x,0).normalized()
  var tone := PAINT.lerp(Color("424540"),0.32 if i in [0,4] else 0.12)
  group.quad(Vector3(a.x,a.y,front),Vector3(a.x,a.y,rear),Vector3(b.x,b.y,rear),Vector3(b.x,b.y,front),facing,tone)
  var bottom := Vector3(0,238,front)
  var colors := PackedColorArray([PAINT,PAINT,PAINT])
  group.triangle(bottom,Vector3(a.x,a.y,front),Vector3(b.x,b.y,front),Vector3.FORWARD,colors)
  bottom.z = rear
  group.triangle(bottom,Vector3(a.x,a.y,rear),Vector3(b.x,b.y,rear),Vector3.BACK,colors)

func end_door(group: Batch,z: float,short_side: int) -> void:
 # Same-side vestibule seam and a little inset pane identify moving coaches,
 # not a continuous building frontage. All of this is part of the trim batch.
 var centre := z+short_side*447
 pane(group,130.34,24,185,centre-26,centre+26,PAINT.darkened(0.24))
 for edge in [-24.0,24.0]:
  pane(group,130.46,22,188,centre+edge-0.7,centre+edge+0.7,TRUE_DARK)
 pane(group,130.45,119,166,centre-18,centre+18,INK)
 pane(group,130.5,128,161,centre-14,centre+14,LINING.darkened(0.20))
 pane(group,130.50,83,110,centre+19,centre+20.8,OCHRE)

func coach(body: Batch,fittings: Batch,through_glass: Batch,travel: float,inhabited: bool) -> void:
 # The window openings are actual recessed gaps between the side-wall pieces.
 block(body,Vector3(126,27.5,travel),Vector3(8,155,960),PAINT)
 block(body,Vector3(126,212.5,travel),Vector3(8,55,960),PAINT)
 block(body,Vector3(-126,95,travel),Vector3(8,290,960),PAINT)
 block(body,Vector3(0,-46,travel),Vector3(260,8,960),PAINT)
 for end in [-1,1]:
  block(body,Vector3(0,95,travel+end*476),Vector3(260,290,8),PAINT.darkened(0.30))
  block(fittings,Vector3(0,-49,travel+end*482),Vector3(45,17,15),TRUE_DARK)
  block(fittings,Vector3(13,106,travel+end*483),Vector3(136,203,12),INK)
  end_door(fittings,travel,end)
 roof(body,travel)
 block(fittings,Vector3(0,-64,travel),Vector3(216,28,850),TRUE_DARK)
 for bogie in [-315.0,315.0]:
  block(fittings,Vector3(104,-76,travel+bogie),Vector3(29,38,103),INK)
 pane(fittings,130.22,80.5,82.8,travel-465,travel+465,OCHRE.darkened(0.25))
 pane(fittings,130.24,221.0,224.0,travel-463,travel+463,LINING.lightened(0.11))
 pane(fittings,130.30,17.5,20.5,travel-465,travel+465,INK)
 var cursor := -HALF_COACH
 for window in WINDOWS:
  var centre: float = window[0]
  var width: float = window[1]
  var left := centre-width*0.5
  var right := centre+width*0.5
  block(body,Vector3(126,145,travel+(cursor+left)*0.5),Vector3(8,80,left-cursor),PAINT)
  var offset := travel+centre
  for y in [WINDOW_LO+2.0,WINDOW_HI-2.0]:
   block(fittings,Vector3(124.5,y,offset),Vector3(9,4,width),INK)
  for end in [-1,1]:
   block(fittings,Vector3(124.5,145,offset+end*(width*0.5-2)),Vector3(9,80,4),INK)
  if centre==40.0:
   warm_berth(through_glass,offset,width,inhabited)
  else:
   pane(fittings,118.6,109,181,offset-width*0.5+4,offset+width*0.5-4,TRUE_DARK.lerp(LINING,0.35 if centre==-120.0 else 0.12))
  cursor = right
 block(body,Vector3(126,145,travel+(cursor+HALF_COACH)*0.5),Vector3(8,80,HALF_COACH-cursor),PAINT)

func warm_berth(group: Batch,z: float,width: float,inhabited: bool) -> void:
 var lo := z-width*0.5+4.0
 var hi := z+width*0.5-4.0
 var glow := Color("a4815e") if inhabited else Color("6f574a")
 # Stepped recess has actual near/inner profiles and shoulders. Keep ambient
 # warm light in this one berth, with contrast away from the sill rather
 # than a single backlit cut-out against a bright rectangular billboard.
 var a := Vector3(110.0,109,lo+2)
 var b := Vector3(110.0,109,hi-2)
 var c := Vector3(110.0,181,hi-2)
 var d := Vector3(110.0,181,lo+2)
 group.triangle(a,b,c,Vector3.RIGHT,PackedColorArray([glow.darkened(0.32),glow.darkened(0.30),glow]))
 group.triangle(a,c,d,Vector3.RIGHT,PackedColorArray([glow.darkened(0.32),glow,glow.lightened(0.04)]))
 group.quad(Vector3(128,109,lo),Vector3(128,109,hi),b,a,Vector3.UP,Color("66513e"))
 group.quad(Vector3(128,181,lo),d,c,Vector3(128,181,hi),Vector3.DOWN,Color("3d362c"))
 group.quad(Vector3(128,109,lo),a,d,Vector3(128,181,lo),Vector3.BACK,glow.darkened(0.41))
 group.quad(Vector3(128,109,hi),Vector3(128,181,hi),c,b,Vector3.FORWARD,glow.darkened(0.41))
 pane(group,113.0,117,180,lo+2,lo+12,glow.darkened(0.30))
 pane(group,113.0,117,180,hi-10,hi-2,glow.darkened(0.24))
 if not inhabited:
  pane(group,115.0,118,135,z-23,z+16,Color("413631"))
  return
 var person := Color("3e312b")
 var head := Vector3(121.0,154,z+5)
 for step in range(18):
  var a0 := float(step)*TAU/18.0
  var a1 := float(step+1)*TAU/18.0
  var rim0 := Vector3(-4,sin(a0)*10.3,cos(a0)*8.6)
  var rim1 := Vector3(-4,sin(a1)*10.3,cos(a1)*8.6)
  var rim_color := person.lightened(0.12+0.05*sin(a0))
  group.triangle(head,head+rim0,head+rim1,Vector3.RIGHT,PackedColorArray([person,rim_color,rim_color]))
 group.triangle(Vector3(117.5,155,z-2.0),Vector3(118.8,151,z-7.9),Vector3(117.5,149,z-2.0),Vector3.RIGHT,PackedColorArray([person,person,person]))
 group.quad(Vector3(120,116,z-15),Vector3(119,115,z+26),Vector3(117,137,z+21),Vector3(118,140,z-6),Vector3.RIGHT,person)
 pane(group,118.8,138,148,z-1,z+11,person.darkened(0.10))
 # Foreground book sits below the profile, still one cheap mesh surface.
 var paper := Color("bc9f79")
 group.quad(Vector3(121.5,123,z-14),Vector3(122.4,125,z-5),Vector3(122.4,131,z-5),Vector3(121.1,131,z-16),Vector3.RIGHT,paper)
 group.quad(Vector3(122.4,125,z-5),Vector3(120.9,126,z+2),Vector3(120.9,130,z+5),Vector3(122.4,131,z-5),Vector3.RIGHT,paper.darkened(0.17))

static func is_salon_view(viewer: Vector3,forward: Vector3) -> bool:
 return viewer.x < -390.0 and absf(viewer.z-SALON_Z)<180.0 and viewer.y>96.0 and viewer.y<247.0 and forward.x < -0.35

func observe(viewer: Vector3,forward: Vector3,playing: bool) -> void:
 if played or not ambient_enabled or not playing: return
 if not is_salon_view(viewer,forward): return
 played = true
 in_motion = true
 elapsed = 0.0
 sample_crossing(0)
 show()

func sample_crossing(progress: float) -> void:
 position.z = lerpf(START_Z,END_Z,clampf(progress,0.0,1.0))

func advance(delta: float) -> void:
 if not in_motion: return
 elapsed += delta
 sample_crossing(elapsed/PASS_SECONDS)
 if elapsed>=PASS_SECONDS:
  in_motion = false
  hide()

func set_ambient_enabled(enabled: bool) -> void:
 ambient_enabled = enabled
 if enabled: return
 if in_motion: sample_crossing(1)
 in_motion = false
 hide()
