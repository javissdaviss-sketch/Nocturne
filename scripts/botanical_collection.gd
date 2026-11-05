extends "res://scripts/lived_in_details.gd"
## Layered living collection: broad-leaf specimens, lower foliage and fern understory.
## Original clue plants remain in world.gd; these occupy the outer nursery beds.
const SOIL := Color("242b21")
const GLAZE := Color("31544c")
const LEAF_DARK := Color("214c36")
const LEAF_MID := Color("3d6b43")
const LEAF_YOUNG := Color("687f48")
const Crafted = preload("res://scripts/crafted_geometry.gd")
const GardenFixtures = preload("res://scripts/garden_fixture_geometry.gd")

func populate(side: int, lo: float, hi: float) -> void:
 name = "LivingCollection"
 make_leaf_meshes()
 var rows := [lo+65,(lo+hi)*0.5,hi-65]
 for index in range(rows.size()):
  var z: float = rows[index]
  # A high rear canopy, a spreading middle specimen and low fern at the aisle edge.
  var bed := Vector3(side*377,0,z)
  broadleaf(seated_pot_position(Vector3(side*(431-5*(index%2)),0,z+5),bed),98+index*9,0.2+index*0.6)
  broadleaf(seated_pot_position(Vector3(side*(363+6*(index%2)),0,z-8),bed),57+index*8,1.0+index*0.8)
  fern(seated_pot_position(Vector3(side*303,0,z+6),bed),index*0.6)
 finish_batches()
 for child in get_children():
  if child is MultiMeshInstance3D and (str(child.name).contains("broad_leaf") or str(child.name).contains("fern_frond")):
   child.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

static func seated_pot_position(p: Vector3, bed: Vector3) -> Vector3:
 # The vessel's flat foot begins 0.2 cm above its origin. Seat it directly on
 # the authored soil, rather than the old blockout's uniform Y67 surface.
 var local := p-bed
 p.y = bed.y+GardenFixtures.soil_height(local.x,local.z,190,52)-0.2
 return p

func pot(p: Vector3, diameter: float, height: float, tint: Color) -> Vector3:
 var key := "turned_pot_%s_%s" % [diameter,height]
 if not meshes.has(key): meshes[key] = GardenFixtures.pot_mesh(diameter,height)
 instance(key,p,Vector3.ONE,tint)
 instance("fine_ring",p+Vector3(0,height-0.35,0),Vector3(diameter*1.065,0.65,diameter*1.065),BRASS,true)
 cyl(p+Vector3(0,height-1.1,0),diameter*0.88,0.8,SOIL)
 return p+Vector3(0,height,0)

func broadleaf(p: Vector3, height: float, rotation_y: float) -> void:
 var base := pot(p,26 if height>80 else 23,18 if height>80 else 14,GLAZE if height>80 else Color("776346"))
 var top := base+Vector3(sin(rotation_y)*9,height,cos(rotation_y)*8)
 curved_stem(base,base.lerp(top,0.91),0.75,2.0,Color("4f5e37"))
 for i in range(9):
  var angle := rotation_y+i*2.39996
  var along := 0.28+i*0.073
  var stem := base.lerp(top,along)+Vector3(sin(along*PI)*2,0,cos(rotation_y)*sin(along*PI)*1.5)
  var reach := 13.0 if height>80 else 9.0
  var direction := Vector3(sin(angle),0,cos(angle))
  var leaf_root := stem+direction*reach+Vector3(0,6,0)
  curved_stem(stem,leaf_root,0.33,2.2,Color("566c3b"))
  var length := (38.0 if height>80 else 32.0)*(0.88+float(i%4)*0.065)
  var width := (23.0 if height>80 else 20.0)*(0.85+float((i+1)%3)*0.09)
  var pitch := -0.3 if i>6 else 0.18
  var tint := LEAF_YOUNG if i>6 else (LEAF_MID if i%2 else LEAF_DARK)
  instance("broad_leaf",leaf_root,Vector3(width,length,length),tint,false,Vector3(pitch+sin(i*1.7)*0.12,angle,sin(i*2.1)*0.10))

func fern(p: Vector3, angle: float) -> void:
 var base := pot(p,30,11,Color("846d4f"))
 for i in range(8):
  var yaw := angle+i*TAU/8
  var length := 39.0+float(i%3)*3
  instance("fern_frond",base+Vector3(0,1,0),Vector3(length,length,length),LEAF_MID if i%2 else LEAF_DARK,false,Vector3(0,yaw,0))

func make_leaf_meshes() -> void:
 # Thin folded laminae catch light as leaves, rather than flattened ellipsoids.
 var leaf := SurfaceTool.new()
 leaf.begin(Mesh.PRIMITIVE_TRIANGLES)
 append_leaf(leaf,Vector3.ZERO,Vector3(0,0,1),1.0,0.12)
 leaf.generate_normals()
 meshes["broad_leaf"] = leaf.commit()
 var frond := SurfaceTool.new()
 frond.begin(Mesh.PRIMITIVE_TRIANGLES)
 for pair in range(1,10):
  var along := float(pair)/11
  var root := Vector3(0,sin(along*PI)*0.38,along)
  var length := 0.28*pow(1.0-along,0.5)
  for side in [-1,1]:
   var tip := root+Vector3(side*length,-length*0.12,length*0.30)
   append_leaf(frond,root,tip,length*0.34,0.022)
 append_leaf(frond,Vector3(0,0.19,0.86),Vector3(0,0.08,1.08),0.08,0.025)
 frond.generate_normals()
 meshes["fern_frond"] = frond.commit()

func curved_stem(start: Vector3, end: Vector3, radius: float, arch: float, color: Color) -> void:
 var key := "bent_stem_"+str(end-start)+str(radius)+str(arch)
 if not meshes.has(key):
  var path: Array[Vector3] = []
  var radii: Array[float] = []
  var direction := end-start
  var lateral := Vector3(direction.z,0,-direction.x).normalized()
  for i in range(13):
   var t := float(i)/12
   path.append(direction*t+Vector3.UP*sin(t*PI)*arch+lateral*sin(t*PI)*minf(2,arch))
   radii.append(radius*lerpf(1.0,0.68,t))
  meshes[key] = Crafted.tube(path,radii,12)
 instance(key,start,Vector3.ONE,color)

func append_leaf(surface: SurfaceTool, start: Vector3, end: Vector3, width: float, arch: float) -> void:
 var across := (end-start).cross(Vector3.UP).normalized()
 var length := (end-start).length()
 # A cupped lamina with a raised midrib, curved tip and gently rolled margins.
 # Dense authored sections preserve an organic silhouette at fly distance.
 for segment in range(20):
  for strip in range(6):
   for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
    var t := float(segment+corner.y)/20
    var lateral := float(strip+corner.x)/3-1.0
    var outline := pow(maxf(0,sin(t*PI)),0.84)*(1.08-0.25*t)
    var half_width := outline*width*0.5
    var center := start.lerp(end,t)+Vector3.UP*(sin(t*PI)*arch-pow(t,5)*length*0.10)
    center += across*sin(t*PI)*sin(t*2.3)*width*0.08
    var cup := -pow(absf(lateral),1.6)*half_width*0.23
    var edge_curl := pow(absf(lateral),6)*half_width*0.11*sin(t*PI*1.6)
    var twist := lateral*sin(t*PI*1.3)*width*0.035
    surface.set_uv(Vector2((lateral+1)*0.5,t))
    surface.add_vertex(center+across*half_width*lateral+Vector3.UP*(cup+edge_curl+twist))

func material_id(color: Color, metal: bool, finish: int = -1) -> String:
 var key := super.material_id(color,metal,finish)
 if color in [LEAF_DARK,LEAF_MID,LEAF_YOUNG]:
  if not materials[key] is ShaderMaterial:
   materials[key] = preload("res://scripts/material_library.gd").make(14,color)
 return key
