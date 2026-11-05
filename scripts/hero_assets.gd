extends RefCounted
## Independently modeled investigation props; all dimensions are centimetres.
const Geometry = preload("res://scripts/crafted_geometry.gd")
const Ceramic = preload("res://scripts/ceramic_profiles.gd")
const GOLD := Color("bca172")
const TIMBER := Color("4d3328")
const IVORY := Color("e0d3b7")

static func evidence_cup(w: Node3D, parent: Node3D, p: Vector3) -> Node3D:
 var root := Node3D.new()
 root.name = "EvidenceCup"
 parent.add_child(root)
 root.position = p
 # Preserve the accepted open ceramic geometry, tea level and brass handle.
 var saucer: MeshInstance3D = w.mesh_obj(root,Ceramic.saucer_mesh(),Vector3.ZERO,IVORY)
 saucer.name = "PorcelainSaucer"
 var body: MeshInstance3D = w.mesh_obj(root,Ceramic.cup_mesh(),Vector3.ZERO,IVORY)
 body.name = "PorcelainCup"
 var tea: MeshInstance3D = w.cyl(Vector3(0,4,0),3.95,0.12,Color("593c31"),false,root)
 tea.name = "TeaSurface"
 tea.material_override = w.mat(Color("593c31"))
 tea.material_override.roughness = 0.13
 var handle := TorusMesh.new()
 handle.inner_radius = 1.4
 handle.outer_radius = 2.1
 var h: MeshInstance3D = w.mesh_obj(root,handle,Vector3(6,4.8,0),Color("c6a46c"),false,0.6)
 h.name = "BrassHandle"
 h.rotation.x = PI/2
 # Dried pesticide clings to the wall above the liquid. Use a private seed so
 # refining this clue cannot change world foliage, furniture or exterior layout.
 var random := RandomNumberGenerator.new()
 random.seed = 9031031
 var deposits := SurfaceTool.new()
 deposits.begin(Mesh.PRIMITIVE_TRIANGLES)
 var crystals := SurfaceTool.new()
 crystals.begin(Mesh.PRIMITIVE_TRIANGLES)
 var patches := [Vector4(4.22,4.74,1.58,0.72),Vector4(5.02,4.53,0.83,0.49),Vector4(2.76,4.88,1.06,0.61),Vector4(0.20,4.58,0.64,0.42),Vector4(1.72,5.02,0.44,0.31)]
 for patch_index in range(patches.size()):
  var patch: Vector4 = patches[patch_index]
  residue_patch(deposits,patch,random)
  # Only a few angular protrusions, with varied orientation and size. Most of
  # the violet reading comes from the thin uneven deposit, not loose beads.
  var count := 3 if patch_index == 0 else (2 if patch_index == 2 else 1)
  for shard in range(count):
   var angle := patch.x+random.randf_range(-0.26,0.26)*patch.z/cup_inner_radius(patch.y)
   var y := patch.y+random.randf_range(-0.18,0.18)*patch.w
   residue_crystal(crystals,angle,y,random.randf_range(0.09,0.18),random.randf_range(0.18,0.34),random.randf_range(0.045,0.12),random.randf_range(-0.8,0.8),random)
 # Small satellite flakes break up the edge without making a regular ring.
 for patch in [Vector4(3.96,4.46,0.22,0.17),Vector4(4.53,4.94,0.19,0.15),Vector4(2.99,4.58,0.17,0.13)]:
  residue_patch(deposits,patch,random)
 var film: MeshInstance3D = w.mesh_obj(root,deposits.commit(),Vector3.ZERO,Color("a36ab9"))
 film.name = "AdheredVioletDeposit"
 var film_material := StandardMaterial3D.new()
 film_material.albedo_color = Color("a36ab9")
 film_material.vertex_color_use_as_albedo = true
 film_material.roughness = 0.79
 film_material.metallic_specular = 0.25
 film.material_override = film_material
 var shards: MeshInstance3D = w.mesh_obj(root,crystals.commit(),Vector3.ZERO,Color("b69ac9"))
 shards.name = "AngularVioletCrystals"
 var crystal_material := StandardMaterial3D.new()
 crystal_material.albedo_color = Color("b69ac9")
 crystal_material.vertex_color_use_as_albedo = true
 crystal_material.roughness = 0.32
 crystal_material.metallic_specular = 0.48
 shards.material_override = crystal_material
 return root

static func cup_inner_radius(y: float) -> float:
 # Exact accepted cup profile over the deposit's height range (2.4–6.5 cm).
 return lerpf(3.85,4.15,(y-2.4)/4.1)

static func residue_point(angle: float, y: float, inward_depth: float) -> Vector3:
 var radius := cup_inner_radius(y)-inward_depth
 return Vector3(cos(angle)*radius,y,sin(angle)*radius)

static func residue_patch(surface: SurfaceTool, patch: Vector4, random: RandomNumberGenerator) -> void:
 var outline: Array[Vector2] = []
 var points := 19
 for j in range(points):
  var a := float(j)*TAU/points
  var edge := random.randf_range(0.73,1.08)
  outline.append(Vector2(cos(a)*patch.z*0.5*edge,sin(a)*patch.w*0.5*edge))
 # A continuous curved film with a feathered rim and a ceramic-contact back.
 for back in [false,true]:
  for ring in range(3):
   var inner := float(ring)/3
   var outer := float(ring+1)/3
   for j in range(points):
    var vertices: Array[Vector3] = []
    var normals: Array[Vector3] = []
    for entry in [Vector2i(j,0),Vector2i((j+1)%points,0),Vector2i((j+1)%points,1),Vector2i(j,1)]:
     var fraction := inner if entry.y == 0 else outer
     var offset: Vector2 = outline[entry.x]*fraction
     var angle := patch.x+offset.x/cup_inner_radius(patch.y)
     var y := patch.y+offset.y
     var depth := -0.002 if back else 0.006+0.030*pow(1.0-fraction,0.7)*(0.85+0.15*sin(j*1.7+fraction*4))
     vertices.append(residue_point(angle,y,depth))
     normals.append(Vector3(-cos(angle),0.3/4.1,-sin(angle)).normalized()*(-1 if back else 1))
    var shade := 0.90+random.randf()*0.10
    residue_quad(surface,vertices,normals,Color(shade,shade,shade))
 # Close the thin outside edge, touching the ceramic instead of hovering.
 for j in range(points):
  var vertices: Array[Vector3] = []
  for entry in [Vector2i(j,0),Vector2i((j+1)%points,0),Vector2i((j+1)%points,1),Vector2i(j,1)]:
   var offset: Vector2 = outline[entry.x]
   var angle := patch.x+offset.x/cup_inner_radius(patch.y)
   vertices.append(residue_point(angle,patch.y+offset.y,0.006 if entry.y == 0 else -0.002))
  var normal := -(vertices[1]-vertices[0]).cross(vertices[2]-vertices[0]).normalized()
  residue_quad(surface,vertices,[normal,normal,normal,normal],Color(0.92,0.92,0.92))

static func residue_quad(surface: SurfaceTool, points: Array[Vector3], normals: Array[Vector3], color: Color) -> void:
 var direction := (points[1]-points[0]).cross(points[2]-points[0])
 if direction.length_squared() < 0.000000000001:
  direction = (points[2]-points[0]).cross(points[3]-points[0])
 var order := [0,2,1,0,3,2] if direction.dot(normals[0]+normals[1]+normals[2]+normals[3]) > 0 else [0,1,2,0,2,3]
 for triangle in range(2):
  var a: int = order[triangle*3]
  var b: int = order[triangle*3+1]
  var c: int = order[triangle*3+2]
  if (points[b]-points[a]).cross(points[c]-points[a]).length_squared() < 0.000000000001: continue
  for index in [a,b,c]:
   surface.set_normal(normals[index])
   surface.set_color(color)
   surface.add_vertex(points[index])

static func residue_crystal(surface: SurfaceTool, angle: float, y: float, width: float, height: float, depth: float, rotation: float, random: RandomNumberGenerator) -> void:
 var outline := [Vector2(-0.5,-0.48),Vector2(0.28,-0.5),Vector2(0.55,-0.2),Vector2(0.33,0.5),Vector2(-0.28,0.45),Vector2(-0.55,0.12)]
 var points: Array[Vector3] = []
 for outline_point in outline:
  var offset := Vector2(outline_point.x*width,outline_point.y*height).rotated(rotation)
  points.append(residue_point(angle+offset.x/cup_inner_radius(y),y+offset.y,-0.002))
 for tip in [Vector2(-0.10,-0.25),Vector2(0.12,0.30)]:
  var offset := Vector2(tip.x*width,tip.y*height).rotated(rotation)
  points.append(residue_point(angle+offset.x/cup_inner_radius(y),y+offset.y,depth*(1.0 if points.size() == 6 else 0.75)))
 var center := residue_point(angle,y,depth*0.3)
 for indices in [[0,1,6],[1,2,6],[2,3,7,6],[3,4,7],[4,5,7],[5,0,6,7],[5,4,3,2,1,0]]:
  var face: Array[Vector3] = []
  for index in indices: face.append(points[index])
  var normal := (face[1]-face[0]).cross(face[2]-face[0]).normalized()
  var face_center := Vector3.ZERO
  for point in face: face_center += point
  face_center /= face.size()
  if normal.dot(face_center-center) < 0:
   face.reverse()
   normal = -normal
  var shade := random.randf_range(0.80,1.0)
  for triangle in range(1,face.size()-1):
   for point in [face[0],face[triangle+1],face[triangle]]:
    surface.set_normal(normal)
    surface.set_color(Color(shade,shade,shade))
    surface.add_vertex(point)

static func rounded(w: Node3D, parent: Node3D, p: Vector3, size: Vector3, radius: float, color: Color, metal: float = 0.0) -> MeshInstance3D:
 var node: MeshInstance3D = w.mesh_obj(parent,Geometry.rounded_box(size,radius),p,color,false,metal)
 if color == TIMBER: node.material_override = w.cabin_finish(2,TIMBER)
 return node

static func terminal(w: Node3D, parent: Node3D, p: Vector3) -> Node3D:
 var root := Node3D.new()
 root.name = "MaintenanceInstrument"
 parent.add_child(root)
 root.position = p
 rounded(w,root,Vector3.ZERO,Vector3(29,9,22),1.6,Color("293c3e"))
 rounded(w,root,Vector3(0,4.3,0),Vector3(27.5,0.8,20.5),0.35,GOLD,0.7)
 rounded(w,root,Vector3(0,4.78,0),Vector3(25.6,0.35,18.6),0.16,Color("0c2428"))
 var screen := rounded(w,root,Vector3(0,5.0,0),Vector3(24.5,0.12,17.5),0.05,Color("163a3b"))
 screen.material_override = w.mat(Color("163a3b"),0.15,0.12)
 var display: Label3D = w.sign_text("AXLE 12 · I. CHEN\n22:10 — 22:36\nAUTHENTICATED",Vector3(0,5.18,0),0.16,Color("b3d1bc"),root)
 display.rotation.x = -PI/2
 display.rotation.y = PI
 for z in [-7.4,7.4]: rounded(w,root,Vector3(0,5.15,z),Vector3(21,0.04,0.12),0.01,Color("527d74"))
 # The lid is a separate serviceable part, with a continuous housing joint.
 for x in [-14.4,14.4]: rounded(w,root,Vector3(x,2.2,0),Vector3(0.12,0.18,18),0.04,Color("111f23"))
 for z in [-10.85,10.85]: rounded(w,root,Vector3(0,2.2,z),Vector3(26,0.18,0.12),0.04,Color("111f23"))
 for x in [-10.5,10.5]:
  for z in [-7.5,7.5]: rounded(w,root,Vector3(x,-4.6,z),Vector3(3.2,0.7,3.2),0.32,Color("182325"))
 for x in [-12.5,12.5]:
  for z in [-9,9]:
   var screw: MeshInstance3D = w.cyl(Vector3(x,4.8,z),0.45,0.2,GOLD,false,root,-1,0.7)
   w.line(Vector3(x-0.2,4.92,z),Vector3(x+0.2,4.92,z),0.04,Color("3e352d"),root)
 for i in range(6):
  rounded(w,root,Vector3(-10+i*4,0,-11.02),Vector3(3,3,0.35),0.16,Color("101d20"))
  rounded(w,root,Vector3(-10+i*4,0,-11.28),Vector3(2.2,2.2,0.5),0.22,Color("5d6761"),0.3)
  var legend: Label3D = w.sign_text(str(6-i),Vector3(-10+i*4,0,-11.56),0.09,IVORY,root)
  legend.rotation.y = PI
 rounded(w,root,Vector3(14.48,-0.8,0),Vector3(0.4,4.8,17.8),0.15,Color("101c1e"))
 for i in range(12):
  rounded(w,root,Vector3(14.72,-0.8,-7.7+i*1.4),Vector3(0.15,3.8,0.48),0.06,Color("455657"),0.5)
 rounded(w,root,Vector3(-14.45,-0.8,2),Vector3(0.25,2.8,5),0.12,GOLD,0.6)
 rounded(w,root,Vector3(-14.62,-0.8,2),Vector3(0.15,1.6,3.6),0.06,Color("081516"))
 var status: MeshInstance3D = w.ball(Vector3(11.8,2.9,-10.9),Vector3(0.75,0.75,0.35),Color("94c3a4"),root,0.25)
 return root

static func framed_photo(w: Node3D, parent: Node3D, p: Vector3) -> void:
 rounded(w,parent,p,Vector3(18,1,23),0.5,TIMBER).material_override = w.cabin_finish(2,TIMBER)
 for x in [-8.1,8.1]: rounded(w,parent,p+Vector3(x,0.6,0),Vector3(1.5,0.65,22),0.3,GOLD,0.7)
 for z in [-10.6,10.6]: rounded(w,parent,p+Vector3(0,0.6,z),Vector3(15,0.65,1.4),0.3,GOLD,0.7)
 rounded(w,parent,p+Vector3(0,0.55,0),Vector3(14.8,0.18,19.8),0.08,IVORY)
 var photo := rounded(w,parent,p+Vector3(0,0.7,0),Vector3(13.8,0.1,18.8),0.04,Color("526c64"))
 photo.material_override = w.mat(Color("526c64"),0.05)
 # A botanical travel photograph, with landscape layers beneath the glazing.
 for i in range(5):
  var foliage: MeshInstance3D = w.ball(p+Vector3(-4+i*2,0.79,2+sin(i)*3),Vector3(3.6,0.1,5),Color("74876e"),parent)
 var glass := StandardMaterial3D.new()
 glass.albedo_color = Color(0.8,0.92,0.86,0.12)
 glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 glass.roughness = 0.08
 var pane := rounded(w,parent,p+Vector3(0,0.85,0),Vector3(14,0.08,19),0.03,Color.WHITE)
 pane.material_override = glass

static func chemical_bottle(w: Node3D, parent: Node3D, p: Vector3) -> void:
 var profile: Array[Vector2] = [Vector2(0.01,0),Vector2(2.8,0)]
 for i in range(1,17):
  var a := float(i)*PI/32
  profile.append(Vector2(2.8+0.7*sin(a),0.9*(1-cos(a))))
 profile.append(Vector2(3.5,9.4))
 for i in range(1,33):
  var t := float(i)/32
  profile.append(Vector2(3.5-1.8*smoothstep(0,1,t),9.4+3.4*t))
 profile.append_array([Vector2(1.7,14.2),Vector2(1.9,14.35),Vector2(1.9,14.8),Vector2(1.5,15),Vector2(0.01,15)])
 var body: MeshInstance3D = w.mesh_obj(parent,Ceramic.lathe(profile),p,Color("604065"))
 var glass := StandardMaterial3D.new()
 glass.albedo_color = Color("342239")
 glass.roughness = 0.08
 glass.metallic_specular = 0.8
 glass.clearcoat_enabled = true
 glass.clearcoat = 0.8
 body.material_override = glass
 var cap_profile: Array[Vector2] = [Vector2(0.01,0),Vector2(1.95,0),Vector2(2.1,0.2),Vector2(2.1,1.6),Vector2(1.9,1.85),Vector2(0.01,1.85)]
 w.mesh_obj(parent,Ceramic.lathe(cap_profile),p+Vector3(0,13.7,0),GOLD,false,0.7)
 for j in range(32):
  var a := float(j)*TAU/32
  w.line(p+Vector3(cos(a)*2.1,14.0,sin(a)*2.1),p+Vector3(cos(a)*2.1,15.15,sin(a)*2.1),0.045,Color("786142"),parent)
 w.mesh_obj(parent,Geometry.arc_label(3.53,7,1.6),p+Vector3(0,7.5,0),IVORY)
 curved_text(w,parent,p+Vector3(0,9.1,0),"V9",0.18,3.57)
 curved_text(w,parent,p+Vector3(0,7.4,0),"SABLE",0.085,3.57)
 curved_text(w,parent,p+Vector3(0,5.8,0),"BOTANICAL REAGENT",0.02,3.57)
 curved_text(w,parent,p+Vector3(0,5.3,0),"LOT 031 · 30 ml",0.02,3.57)
 # A separate sealing ring and moulded base reveal the vessel's construction.
 var band: MeshInstance3D = w.cyl(p+Vector3(0,13.5,0),1.84,0.38,Color("382c30"),false,parent)

static func dispatch_cover(w: Node3D, parent: Node3D, p: Vector3) -> MeshInstance3D:
 # A removable protective case: thin lid and separately joined walls, open below.
 var roof := Geometry.rounded_box(Vector3(44,1.4,34),0.5).duplicate() as ArrayMesh
 var arrays := roof.surface_get_arrays(0)
 var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
 for i in range(points.size()): points[i].y += 3.3
 arrays[Mesh.ARRAY_VERTEX] = points
 roof.clear_surfaces()
 roof.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
 var lid: MeshInstance3D = w.mesh_obj(parent,roof,p,Color("244945"))
 lid.name = "DispatchDocumentCase"
 for x in [-21.2,21.2]:
  rounded(w,lid,Vector3(x,-0.2,0),Vector3(1.6,6.4,34),0.35,TIMBER)
 for z in [-16.2,16.2]:
  rounded(w,lid,Vector3(0,-0.2,z),Vector3(41,6.4,1.6),0.35,TIMBER)
 for x in [-20,20]: rounded(w,lid,Vector3(x,4.1,0),Vector3(1.1,0.45,31),0.2,GOLD,0.6)
 for z in [-14.8,14.8]: rounded(w,lid,Vector3(0,4.1,z),Vector3(39,0.45,1.1),0.2,GOLD,0.6)
 rounded(w,lid,Vector3(0,4.4,-13),Vector3(29,0.7,6),0.5,GOLD,0.7)
 for j in range(3):
  var lock: MeshInstance3D = w.cyl(Vector3(-8+j*8,4.9,-13),2.5,0.7,GOLD,false,lid,-1,0.7)
  w.cyl(Vector3(-8+j*8,5.32,-13),2.08,0.2,Color("1b3031"),false,lid)
  w.cyl(Vector3(-8+j*8,5.58,-13),1.2,0.4,Color("506d67"),false,lid,-1,0.4)
  rounded(w,lid,Vector3(-8+j*8,5.81,-13),Vector3(0.25,0.1,1.5),0.04,Color("102528"))
  rounded(w,lid,Vector3(-8+j*8,5.5,-15.3),Vector3(0.18,0.2,0.6),0.07,IVORY)
  var digit: Label3D = w.sign_text(str(j+1),Vector3(-8+j*8,5.47,-11.4),0.045,IVORY,lid)
  digit.rotation.x = -PI/2
  for i in range(12):
   var a := float(i)*TAU/12
   w.line(Vector3(-8+j*8+cos(a)*1.6,5.2,-13+sin(a)*1.6),Vector3(-8+j*8+cos(a)*1.9,5.2,-13+sin(a)*1.9),0.035,GOLD,lid)
 for x in [-15,15]: rounded(w,lid,Vector3(x,2.4,17.2),Vector3(4,1.2,1.6),0.4,GOLD,0.6)
 return lid

static func ledger(w: Node3D, parent: Node3D, p: Vector3) -> void:
 var leather := Color("613d35")
 rounded(w,parent,p,Vector3(25,1.1,29),0.35,leather).material_override = preload("res://scripts/material_library.gd").make(5,leather)
 rounded(w,parent,p+Vector3(0,0.8,0),Vector3(24,0.9,27.8),0.25,Color("bdae91")).material_override = preload("res://scripts/material_library.gd").make(13,Color("bdae91"))
 rounded(w,parent,p+Vector3(0,1.45,0),Vector3(25.3,0.35,29),0.15,leather).material_override = preload("res://scripts/material_library.gd").make(5,leather)
 for x in [-11.4,11.4]: rounded(w,parent,p+Vector3(x,1.65,0),Vector3(0.12,0.1,26),0.04,GOLD,0.7)
 for z in [-13,13]: rounded(w,parent,p+Vector3(0,1.65,z),Vector3(22.8,0.1,0.12),0.04,GOLD,0.7)
 for y in [0.5,0.7,0.9,1.1]:
  w.line(p+Vector3(12.05,y,-13.5),p+Vector3(12.05,y,13.5),0.025,Color("8b7a60"),parent)
 for z in [-9,9]: rounded(w,parent,p+Vector3(-12.5,0.7,z),Vector3(0.5,1.3,1.2),0.2,GOLD,0.6)

static func side_table(w: Node3D, parent: Node3D, p: Vector3) -> void:
 var top := rounded(w,parent,p+Vector3(0,83,0),Vector3(53,6,57),1.8,TIMBER)
 top.material_override = w.cabin_finish(2,TIMBER)
 rounded(w,parent,p+Vector3(0,85.7,0),Vector3(50,0.4,54),0.18,GOLD,0.7)
 var profile: Array[Vector2] = [Vector2(0.1,0),Vector2(15,0),Vector2(17,1),Vector2(17,2.5),Vector2(13,4),Vector2(5,8),Vector2(3.2,15),Vector2(3.2,64),Vector2(5,71),Vector2(8,76),Vector2(0.1,80)]
 w.mesh_obj(parent,Ceramic.lathe(profile),p,GOLD,false,0.75)

static func set_colliders(node: Node, enabled: bool) -> void:
 if node is StaticBody3D: node.collision_layer = 1 if enabled else 0
 for child in node.get_children(): set_colliders(child,enabled)

static func curved_text(w: Node3D, parent: Node3D, p: Vector3, content: String, size: float, radius: float) -> void:
 var font := preload("res://assets/Interface.ttf")
 var width := font.get_string_size(content,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x*size/4
 var cursor := -width*0.5
 for character in content:
  var advance := font.get_string_size(character,HORIZONTAL_ALIGNMENT_LEFT,-1,48).x*size/4
  var angle := -(cursor+advance*0.5)/radius
  var glyph: Label3D = w.sign_text(character,p+Vector3(sin(angle)*radius,0,-cos(angle)*radius),size,Color("4c3650"),parent)
  glyph.rotation.y = PI-angle
  cursor += advance

static func data_slate(w: Node3D, parent: Node3D, p: Vector3) -> void:
 var slate := Node3D.new()
 parent.add_child(slate)
 slate.position = p
 slate.rotation.y = 0.08
 rounded(w,slate,Vector3.ZERO,Vector3(17,1.5,23),0.65,TIMBER)
 rounded(w,slate,Vector3(0,0.8,0),Vector3(15,0.3,21),0.14,GOLD,0.7)
 var glass := rounded(w,slate,Vector3(0,1.0,0),Vector3(13.2,0.18,18.2),0.08,Color("163b3c"))
 glass.material_override = w.mat(Color("163b3c"),0.15,0.12)
 for j in range(5):
  rounded(w,slate,Vector3(-1,1.13,-5+j*2.4),Vector3(9-j,0.06,0.18),0.02,Color("6fb5ae"))
 for x in [-7.5,7.5]:
  for z in [-10.5,10.5]:
   w.cyl(Vector3(x,1.0,z),0.3,0.12,GOLD,false,slate,-1,0.7)
 for z in range(-8,9,2):
  rounded(w,slate,Vector3(-8.2,0.5,z),Vector3(0.3,0.3,0.6),0.12,Color("aa9470"))
 # A fitted brass pen rests in a real retaining loop beside the leather case.
 var pen: MeshInstance3D = w.mesh_obj(slate,Ceramic.lathe([Vector2(0.05,0),Vector2(0.4,2),Vector2(0.4,13),Vector2(0.5,13.4),Vector2(0.5,15),Vector2(0.05,15.5)]),Vector3(9.4,0.9,-7),GOLD,false,0.7)
 pen.rotation.x = PI/2

static func covered_scene(w: Node3D, parent: Node3D, p: Vector3) -> void:
 var cloth := SurfaceTool.new()
 cloth.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(64):
  for col in range(32):
   for thickness in [0.0,-0.18]:
    var order: Array[Vector2i] = [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]
    if thickness < 0: order.reverse()
    for corner in order:
     var u := float(col+corner.x)/32*2-1
     var v := float(row+corner.y)/64*2-1
     var x := u*24
     var z := v*52
     var body := 16*exp(-x*x/180-pow(z-5,2)/850)
     var head := 13*exp(-x*x/80-pow(z+32,2)/100)
     var edge := pow(abs(u),10)*12+pow(abs(v),14)*5
     var fold := sin(u*24+v*3)*0.85*pow(abs(u),3)+sin(v*33)*0.4*pow(abs(v),4)
     cloth.set_uv(Vector2(u,v)*5)
     cloth.add_vertex(Vector3(x,31+body+head-edge+fold+thickness,z))
 cloth.generate_normals()
 var cover: MeshInstance3D = w.mesh_obj(parent,cloth.commit(),p,IVORY)
 cover.material_override = preload("res://scripts/sleeping_assets.gd").cloth_material(IVORY)
 for x in [-20,20]:
  rounded(w,parent,p+Vector3(x,25,0),Vector3(3,5,90),1,TIMBER)
  for z in [-34,34]:
   w.cyl(p+Vector3(x,12,z),2.8,24,TIMBER,false,parent,2.1)
 for z in [-43,43]: rounded(w,parent,p+Vector3(0,25,z),Vector3(38,5,3),1,TIMBER)
