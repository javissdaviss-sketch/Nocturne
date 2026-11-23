extends RefCounted
## Four short-room counters share the original grounded cabinet shell but
## carry distinct service fittings: greeting, cloakroom, preparation, dispatch.
## All sizes in centimetres. Register the actual contact surfaces only.

const Props := preload("res://scripts/prop_meshes.gd")
const Sleep := preload("res://scripts/sleeping_assets.gd")
const Finishes := preload("res://scripts/material_library.gd")
const Veneer := preload("res://scripts/fitted_veneer.gd")
const BRONZE := Color("ab9470")
const OAK := Color("62543e")
const WOOL := Color("4d4744")
const WORKTOP_Y := 96.0

static func dress(world: Node3D, counter: Node3D, role: String) -> void:
 match role:
  "concierge":
   mount(world,counter,"ConciergeOpenTicketCradle",ticket_cradle(),Vector3(17,WORKTOP_Y,2),Finishes.make(Finishes.Finish.BRASS,BRONZE))
   mount(world,counter,"ConciergeServiceBell",bell(),Vector3(-20,WORKTOP_Y,-28),Finishes.make(Finishes.Finish.BRASS,Color("b29267")))
  "cloak":
   var tray := Vector3(1.5,WORKTOP_Y,-11)
   mount(world,counter,"CloakroomKeyReturnTray",return_tray(),tray,Veneer.make("table",OAK))
   mount(world,counter,"CloakroomFoldedCoat",folded_coat(),tray+Vector3(-2,0.80,0),Finishes.make(Finishes.Finish.VELVET,WOOL))


  "pantry":
   var bowl := Vector3(-26,WORKTOP_Y,-25)
   mount(world,counter,"PantryOpenMixingBowl",prep_bowl(),bowl,Finishes.make(Finishes.Finish.BRASS,Color("987354")))
   mount(world,counter,"PantryRibbedDishRack",drain_rack(),Vector3(24,WORKTOP_Y,-13),Finishes.make(Finishes.Finish.STEEL,Color("82958c")))
  "steward":
   var tray := Vector3(-17,WORKTOP_Y,-24)
   mount(world,counter,"StewardRaisedDispatchTray",dispatch_tray(),tray,Finishes.make(Finishes.Finish.STEEL,Color("586f78")))
   mount(world,counter,"StewardBlankWorkSheet",folded_sheet(),tray+Vector3(0,0.76,0),Finishes.make(Finishes.Finish.PAPER,Color("c6bfaa")))
   mount(world,counter,"StewardBrassSheetClip",paper_clip(),tray+Vector3(-2,1.11,6.1),Finishes.make(Finishes.Finish.BRASS,Color("b29f6d")))
   mount(world,counter,"StewardInkRest",ink_rest(),Vector3(15,WORKTOP_Y,-28),Finishes.make(Finishes.Finish.WALNUT,Color("71604c")))

static func prep_bowl() -> ArrayMesh:
 # A real shallow vessel with separate rolled lip and returned wall.
 return Sleep.lathe([
  Vector2(0.006,0.0),Vector2(5.9,0.0),Vector2(6.12,0.16),Vector2(6.15,0.52),
  Vector2(7.9,1.35),Vector2(9.7,2.8),Vector2(10.95,4.48),Vector2(11.62,6.55),
  Vector2(11.95,7.18),Vector2(12.0,7.37),Vector2(11.82,7.59),Vector2(11.61,7.62),
  Vector2(11.41,7.44),Vector2(11.47,7.2),Vector2(11.11,6.72),Vector2(10.38,4.65),
  Vector2(9.18,3.07),Vector2(7.59,1.82),Vector2(6.02,1.02),Vector2(0.006,0.98)
 ],48)

static func drain_rack() -> ArrayMesh:
 var out := begin()
 append(out,Props.rounded(Vector3(28,0.88,19.2),0.38),Vector3(0,0.44,0))
 for z in [-8.2,8.2]:
  wire(out,[Vector3(-12.0,0.75,z),Vector3(12.0,0.75,z)],0.63)
 for i in range(5):
  var x := -10.8+float(i)*5.4
  wire(out,[Vector3(x,0.56,-8.2),Vector3(x,3.8,-6.0),Vector3(x,4.65,-3.8),
   Vector3(x,4.65,3.8),Vector3(x,3.8,6.0),Vector3(x,0.56,8.2)],0.58)
 return out.commit()

static func dispatch_tray() -> ArrayMesh:
 var out := begin()
 append(out,Props.rounded(Vector3(37,0.76,24),0.32),Vector3(0,0.38,0))
 for x in [-17.8,17.8]:
  wire(out,[Vector3(x,0.84,-10.6),Vector3(x,1.43,-7.5),Vector3(x,4.25,6.7),Vector3(x,4.46,10.8)],0.80)
  append(out,Props.rounded(Vector3(0.9,1.5,20.0),0.35),Vector3(x,1.30,1.0))
 wire(out,[Vector3(-17.7,4.46,10.8),Vector3(17.7,4.46,10.8)],0.80)
 append(out,Props.rounded(Vector3(35.0,2.5,1.2),0.43),Vector3(0,2.19,10.8))
 return out.commit()

static func folded_sheet() -> ArrayMesh:
 var out := begin()
 append(out,Props.rounded(Vector3(27,0.35,16.4),0.14),Vector3(0,0.175,0))
 var curled := [
  Vector3(12.8,0.35,-7.7),Vector3(9.0,0.72,-7.7),Vector3(11.1,0.74,-4.0),Vector3(13.3,0.35,-3.85)]
 var plane: Array[Vector3] = [curled[0],curled[1],curled[2],curled[3]]
 Props.quad(out,plane,[Vector3.UP,Vector3.UP,Vector3.UP,Vector3.UP])
 return out.commit()

static func paper_clip() -> ArrayMesh:
 var out := begin()
 append(out,Props.rounded(Vector3(6.0,0.52,2.9),0.20),Vector3(0,0.26,0))
 wire(out,[Vector3(-2.5,0.1,1.05),Vector3(-2.5,1.18,1.05),Vector3(2.5,1.18,1.05),Vector3(2.5,0.1,1.05)],0.22)
 return out.commit()

static func ink_rest() -> ArrayMesh:
 var out := begin()
 append(out,Props.rounded(Vector3(13.4,1.35,5.8),0.58),Vector3(0,0.675,0))
 wire(out,[Vector3(-5.4,1.46,0.5),Vector3(5.4,1.46,-0.5)],0.40)
 return out.commit()

static func mount(world: Node3D, counter: Node3D, object_name: String, drawable: ArrayMesh, origin: Vector3, finish: Material) -> void:
 var node: MeshInstance3D = world.mesh_obj(counter,drawable,origin,Color.WHITE,true)
 node.name = object_name
 node.material_override = finish
 node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 node.set_meta("reception_prop",true)

static func ticket_cradle() -> ArrayMesh:
 var result := begin()
 # The foot rails support the receiver at exactly table-top height.
 for z in [-4.1,4.1]:
  append(result,Props.rounded(Vector3(25,0.95,1.8),0.34),Vector3(0,0.475,z))
  wire(result,[Vector3(-12.0,1.0,z),Vector3(-12.0,8.05,z),Vector3(12.0,8.05,z),Vector3(12.0,1.0,z)],0.60)
  for x in [-8.0,0.0,8.0]:
   # Open stepped lozenges, not a copied museum pattern or flat placard.
   wire(result,[
    Vector3(x,1.2,z),Vector3(x-1.05,2.8,z),Vector3(x-2.0,2.8,z),Vector3(x-3.55,4.6,z),
    Vector3(x-2.0,6.35,z),Vector3(x-1.05,6.35,z),Vector3(x,7.9,z),
    Vector3(x+1.05,6.35,z),Vector3(x+2.0,6.35,z),Vector3(x+3.55,4.6,z),
    Vector3(x+2.0,2.8,z),Vector3(x+1.05,2.8,z),Vector3(x,1.2,z)
   ],0.37)
 for x in [-11.6,-6.0,0.0,6.0,11.6]:
  wire(result,[Vector3(x,1.15,-4.1),Vector3(x,1.15,4.1)],0.38)
 for x in [-12.0,12.0]:
  wire(result,[Vector3(x,5.0,-4.1),Vector3(x,5.0,4.1)],0.52)
 return result.commit()

static func bell() -> ArrayMesh:
 return Sleep.lathe([
  Vector2(0.006,0.0),Vector2(3.58,0.0),Vector2(3.70,0.16),Vector2(3.70,0.43),
  Vector2(3.55,0.58),Vector2(3.15,0.75),Vector2(3.11,1.35),Vector2(2.82,2.20),
  Vector2(2.24,2.85),Vector2(1.46,3.15),Vector2(0.79,3.25),Vector2(0.53,3.33),
  Vector2(0.42,3.77),Vector2(0.61,3.95),Vector2(0.56,4.19),Vector2(0.006,4.24)
 ],40)

static func return_tray() -> ArrayMesh:
 var out := begin()
 var base := Props.rounded(Vector3(31.0,0.8,20.0),0.30)
 append(out,base,Vector3(0,0.4,0))
 # Rolled dovetailed rim. Four gently profiled sides leave a physically
 # open centre rather than a shallow thin panel pretending to be a tray.
 for z in [-9.25,9.25]:
  append(out,Props.rounded(Vector3(29,3.3,1.75),0.55),Vector3(0,1.68,z))
 for x in [-15.0,15.0]:
  append(out,Props.rounded(Vector3(1.6,3.25,18),0.55),Vector3(x,1.65,0))
 return out.commit()

static func folded_coat() -> ArrayMesh:
 var out := begin()
 # Cotton layers bend into one another, rather than three tiered cuboids.
 # The lower cloth follows irregular edges; a skew sleeve makes half a lapel.
 fabric_layer(out,Vector2(10.9,6.8),Vector3.ZERO,0.07,2.62)
 fabric_layer(out,Vector2(7.1,5.7),Vector3(0.6,1.73,0.4),-0.21,2.47)
 fabric_layer(out,Vector2(4.4,4.3),Vector3(-2.65,2.82,0.95),0.32,2.05)
 wire(out,[Vector3(-6.2,4.1,1.8),Vector3(-4.91,4.48,2.38),Vector3(-3.15,4.53,2.77),
  Vector3(-1.51,4.25,2.92),Vector3(-0.36,4.08,2.72)],0.148)
 return out.commit()

static func cloth_point(u: float,v: float,half: Vector2,origin: Vector3, twist: float, relief: float, top: bool) -> Vector3:
 var rounded_u := u*(1.0-0.13*pow(absf(v),5.0))
 var rounded_v := v*(1.0-0.16*pow(absf(u),5.0))
 var wave := 0.24*sin(4.1*u+5.3*v)+0.12*sin(9.5*v-3.0*u)
 var p := Vector2(rounded_u*half.x+0.46*sin(v*4.0),rounded_v*half.y+0.36*sin(u*4.3)).rotated(twist)
 var edge := (1.0-0.36*pow(absf(u),5.0))*(1.0-0.27*pow(absf(v),5.0))
 var yy := maxf(0.32,relief*edge+wave+0.81*exp(-pow((u+0.22)*5.5,2.0))*cos(v*0.8)) if top else 0.0
 return origin+Vector3(p.x,yy,p.y)

static func fabric_layer(out: SurfaceTool,half: Vector2,origin: Vector3,twist: float,relief: float) -> void:
 var nx := 29
 var ny := 20
 for a in range(nx):
  var u := -1.0+float(a)*2.0/nx
  var uu := -1.0+float(a+1)*2.0/nx
  for b in range(ny):
   var v := -1.0+float(b)*2.0/ny
   var vv := -1.0+float(b+1)*2.0/ny
   var p := [cloth_point(u,v,half,origin,twist,relief,true),cloth_point(uu,v,half,origin,twist,relief,true),cloth_point(uu,vv,half,origin,twist,relief,true),cloth_point(u,vv,half,origin,twist,relief,true)]
   var normals: Array[Vector3] = []
   for uv: Vector2 in [Vector2(u,v),Vector2(uu,v),Vector2(uu,vv),Vector2(u,vv)]:
    var du := cloth_point(uv.x+0.002,uv.y,half,origin,twist,relief,true)-cloth_point(uv.x-0.002,uv.y,half,origin,twist,relief,true)
    var dv := cloth_point(uv.x,uv.y+0.002,half,origin,twist,relief,true)-cloth_point(uv.x,uv.y-0.002,half,origin,twist,relief,true)
    normals.append(dv.cross(du).normalized())
   var corners: Array[Vector3] = [p[0],p[1],p[2],p[3]]
   Props.quad(out,corners,normals)
 for edge in range(4):
  var n2 := [Vector2(-1,0),Vector2(1,0),Vector2(0,-1),Vector2(0,1)][edge] as Vector2
  n2 = n2.rotated(twist)
  var n := Vector3(n2.x,0,n2.y)
  for step in range(nx):
   var a := -1.0+float(step)*2.0/nx
   var b := -1.0+float(step+1)*2.0/nx
   var ca := Vector2(-1 if edge==0 else 1,a) if edge<2 else Vector2(a,-1 if edge==2 else 1)
   var cb := Vector2(-1 if edge==0 else 1,b) if edge<2 else Vector2(b,-1 if edge==2 else 1)
   var quad: Array[Vector3] = [cloth_point(ca.x,ca.y,half,origin,twist,relief,false),cloth_point(cb.x,cb.y,half,origin,twist,relief,false),cloth_point(cb.x,cb.y,half,origin,twist,relief,true),cloth_point(ca.x,ca.y,half,origin,twist,relief,true)]
   Props.quad(out,quad,[n,n,n,n])

static func wire(target: SurfaceTool, path: Array[Vector3], radius: float) -> void:
 append(target,Props.tube(path,PackedFloat32Array([radius]),8),Vector3.ZERO)

static func begin() -> SurfaceTool:
 var output := SurfaceTool.new()
 output.begin(Mesh.PRIMITIVE_TRIANGLES)
 return output

static func append(target: SurfaceTool, mesh: ArrayMesh, at: Vector3, axis: Basis = Basis.IDENTITY) -> void:
 target.append_from(mesh,0,Transform3D(axis,at))
