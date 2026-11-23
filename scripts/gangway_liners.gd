extends RefCounted
## Fitted accordion liners bridge existing carriage ends. Every facet is behind
## the original 110 cm clear side planes or above the original 230 cm ceiling.
## The existing floor is untouched and the visible folds are actual contacts.
const CLEAR_HALF_WIDTH := 55.0
const CLEAR_HEIGHT := 230.0
const HALF_LENGTH := 20.0
const BACK_DEPTH := 2.30
const PEAK_DEPTH := 1.90
const EDGE_Z := [-20.0,-18.5,-17.3,-16.1,16.1,17.3,18.5,20.0]
const EDGE_RISE := [0.0,0.0,0.62,0.22,0.22,0.62,0.0,0.0]
const HEIGHTS := [0.0,10.5,12.3,17.5,22.4,213.0,222.4,230.0]
const HEIGHT_GAIN := [0.0,0.0,0.20,0.48,1.0,1.0,0.48,0.0]

static func profile(garden: bool) -> Array[Vector2]:
 var points: Array[Vector2] = []
 for i in range(4): points.append(Vector2(EDGE_Z[i], EDGE_RISE[i]))
 var folds := 7 if garden else 5
 var length := 32.2/folds
 for i in range(folds):
  var z := -16.1+float(i)*length
  points.append(Vector2(z+length*0.28,PEAK_DEPTH if garden else 1.64))
  points.append(Vector2(z+length*0.51,PEAK_DEPTH if garden else 1.64))
  points.append(Vector2(z+length*0.82,0.08 if garden else 0.0))
  points.append(Vector2(z+length*0.93,0.08 if garden else 0.0))
 for i in range(4,8): points.append(Vector2(EDGE_Z[i], EDGE_RISE[i]))
 return points

static func dress(world: Node3D, center_z: float, garden: bool) -> Node3D:
 var group := Node3D.new()
 group.name = "BotanicalBellows" if garden else "MeridianBellows"
 world.add_child(group)
 group.position.z = center_z
 var profile_z := profile(garden)
 var sides := SurfaceTool.new()
 var roof := SurfaceTool.new()
 sides.begin(Mesh.PRIMITIVE_TRIANGLES)
 roof.begin(Mesh.PRIMITIVE_TRIANGLES)
 for side in [-1,1]:
  for i in range(profile_z.size()-1):
   for j in range(HEIGHTS.size()-1):
    var vz := profile_z[i]
    var next := profile_z[i+1]
    var y0: float = HEIGHTS[j]
    var y1: float = HEIGHTS[j+1]
    var depth0: float = HEIGHT_GAIN[j]
    var depth1: float = HEIGHT_GAIN[j+1]
    var tint := paint(garden,i,j,profile_z.size(),vz.y,next.y)
    var pts := PackedVector3Array([
     Vector3(side*(CLEAR_HALF_WIDTH+depth0*vz.y),y0,vz.x),
     Vector3(side*(CLEAR_HALF_WIDTH+depth0*next.y),y0,next.x),
     Vector3(side*(CLEAR_HALF_WIDTH+depth1*next.y),y1,next.x),
     Vector3(side*(CLEAR_HALF_WIDTH+depth1*vz.y),y1,vz.x)])
    face(sides,pts,Vector3(-side,0,0),tint)
  backing(group,Vector3(side*(CLEAR_HALF_WIDTH+BACK_DEPTH+1.85),115,0),Vector3(3.7,230,40))
 for i in range(profile_z.size()-1):
  var left := profile_z[i]
  var right := profile_z[i+1]
  for lane in range(3):
   var a: float = [-55.0,-47.8,47.8][lane]
   var b: float = [-47.8,47.8,55.0][lane]
   var fac_a := 0.0 if lane==0 else 1.0
   var fac_b := 0.0 if lane==2 else 1.0
   var pts := PackedVector3Array([
    Vector3(a,CLEAR_HEIGHT+fac_a*left.y,left.x),
    Vector3(b,CLEAR_HEIGHT+fac_b*left.y,left.x),
    Vector3(b,CLEAR_HEIGHT+fac_b*right.y,right.x),
    Vector3(a,CLEAR_HEIGHT+fac_a*right.y,right.x)])
   face(roof,pts,Vector3.DOWN,paint(garden,i,3 if lane==1 else 1,profile_z.size(),left.y,right.y))
 backing(group,Vector3(0,CLEAR_HEIGHT+BACK_DEPTH+1.85,0),Vector3(120,3.7,40))
 fit(world,group,sides.commit(),"FormedSideBellows",garden)
 fit(world,group,roof.commit(),"FormedOverheadBellows",garden)
 return group

static func paint(garden: bool, strip: int, band: int, n: int, a: float, b: float) -> Color:
 var brim := strip<3 or strip>=n-4
 var warm := Color("786755") if garden else Color("9a7850")
 var cool := Color("2e5551") if garden else Color("3b3736")
 if band==0 or band==6: return Color("30474b") if garden else Color("332d2b")
 if band==1 or brim: return warm.lightened(0.045) if brim and strip%2==0 else warm
 if band==2 or band==5: return cool.lightened(0.12)
 # Broad matte folds and quiet ridge tint, not narrow procedural stripes.
 return cool.lerp(Color("4c7770") if garden else Color("605449"),0.34*(1.0-clampf((a+b)*0.5/PEAK_DEPTH,0.0,1.0)))

static func face(st: SurfaceTool, p: PackedVector3Array, inward: Vector3, color: Color) -> void:
 for corners in [[0,1,2],[0,2,3]]:
  var a: Vector3 = p[corners[0]]
  var b: Vector3 = p[corners[1]]
  var c: Vector3 = p[corners[2]]
  var normal := (b-a).cross(c-a).normalized()
  var reverse := inward.dot(normal)>0.0
  if not reverse: normal = -normal
  for point in [a,c,b] if reverse else [a,b,c]:
   st.set_color(color)
   st.set_normal(normal)
   st.add_vertex(point)

static func fit(world: Node3D, group: Node3D, mesh: Mesh, id: String, garden: bool) -> void:
 var lining: MeshInstance3D = world.mesh_obj(group,mesh,Vector3.ZERO,Color.WHITE,false)
 lining.name = id
 # Per-facet dye stands up consistently in both renderers without shimmer.
 var finish := StandardMaterial3D.new()
 finish.vertex_color_use_as_albedo = true
 finish.vertex_color_is_srgb = true
 finish.roughness = 0.77 if garden else 0.84
 finish.metallic = 0.12 if garden else 0.08
 lining.material_override = finish
 lining.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

static func backing(group: Node3D, p: Vector3, size: Vector3) -> void:
 var body := StaticBody3D.new()
 body.name = "RecessedShellBacking"
 body.collision_layer = 1
 body.collision_mask = 0
 group.add_child(body)
 body.position = p
 var collider := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collider.shape = shape
 body.add_child(collider)
