extends RefCounted
## Physically different ways to use the same supported desktop. Dimensions
## are protected by the original bed, chair and slate clearance contract.
const Props := preload("res://scripts/prop_meshes.gd")
const Finishes := preload("res://scripts/material_library.gd")
const Veneer := preload("res://scripts/fitted_veneer.gd")
const STEEL := Color("455352")
const INSET := Color("354647")
const ASH := Color("777056")
const LEATHER := Color("6b5d44")
const WRITING_OAK := Color("514030")
const COAST_LIGHT := Color("788178")

static func dress(world: Node3D, root: Node3D, width: float, depth: float, top: MeshInstance3D, use: String) -> void:
 if use=="engineering":
  top.material_override = Finishes.make(Finishes.Finish.STEEL,STEEL,false,false,true)
  engineering_base(world,root,width,depth)
 elif use=="crew":
  top.material_override = Veneer.make("table",ASH)
  crew_base(world,root,width,depth)
 elif use=="writing":
  top.material_override = Veneer.make("table",WRITING_OAK)
  writing_base(world,root,width,depth)
 elif use=="coast":
  top.material_override = Veneer.make("table",COAST_LIGHT)
  coast_base(world,root,width,depth)

static func part(world: Node3D,parent: Node3D, name: String, mesh: ArrayMesh, material: Material) -> void:
 var instance: MeshInstance3D = world.mesh_obj(parent,mesh,Vector3.ZERO,Color.WHITE,true)
 instance.name = name
 # Very small pieces share matte shadows from the existing appropriate key
 # and wider directional light; don't introduce another light or PCSS budget.
 instance.material_override = material

static func engineering_base(world: Node3D, root: Node3D, width: float, depth: float) -> void:
 var frame := begin()
 var details := begin()
 # Lower break in the front keeps this recognisably usable as a working
 # station: open footwell on the left, locker/support structure to the right.
 for x in [-width*0.5+8,width*0.5-8]:
  for z in [-depth*0.5+9,depth*0.5-9]:
   block(frame,Vector3(x,34.0,z),Vector3(3.6,68.0,5.2),0.95)
   block(details,Vector3(x,1.0,z),Vector3(5.0,2.0,6.8),0.42)
  block(frame,Vector3(x,69.0,0),Vector3(5.3,5.0,depth-15.5),0.8)
  block(frame,Vector3(x,15.8,0),Vector3(3.4,3.5,depth-20.2),0.62)
 block(frame,Vector3(0,67.5,-depth*0.5+8),Vector3(width-14,8,3.2),0.68)
 block(frame,Vector3(0,67.5,depth*0.5-8),Vector3(width-14,8,3.2),0.68)
 # Folded-face drawer station is recessed within the old footprint, with
 # individually separated softened drawers and centred physical pulls.
 var x := width*0.5-20.0
 block(frame,Vector3(x,35.1,4.5),Vector3(22.9,60.9,41),1.42)
 for y in [12.0,23.5,36.5,49.6,60.5]:
  block(details,Vector3(x,y,25.25),Vector3(21.5,9.75,0.85),0.33)
  wire(details,[Vector3(x-4.7,y+2.0,25.4),Vector3(x-4.3,y+2.0,26.95),
   Vector3(x+4.3,y+2.0,26.95),Vector3(x+4.7,y+2.0,25.4)],0.38)
 for i in range(4):
  block(details,Vector3(-16.4+i*4.7,67.4,-depth*0.5+6.28),Vector3(3.2,1.2,0.8),0.25)
 part(world,root,"EngineeringStressedSteelStation",frame.commit(),Finishes.make(Finishes.Finish.STEEL,STEEL,false,false,true))
 part(world,root,"EngineeringRecessedDrawerFronts",details.commit(),Finishes.make(Finishes.Finish.STEEL,INSET,false,false,true))

static func crew_base(world: Node3D, root: Node3D, width: float, depth: float) -> void:
 var frame := begin()
 var trim := begin()
 var legs := begin()
 # Narrow upper frames and flat plank end boxes, not the tapered legs and
 # scalloped apron used by the passenger suites. Keep both sides traversable.
 for x in [-width*0.5+10,width*0.5-10]:
  for z in [-depth*0.5+8,depth*0.5-8]:
   block(legs,Vector3(x,35.75,z),Vector3(5.2,71.5,4.82),0.73)
  for y in [21.5,61.5,69.5]:
   block(frame,Vector3(x,y,0),Vector3(5.15,4.0,depth-13.65),0.7)
  for z in [-12.0,0.0,12.0]:
   block(frame,Vector3(x,42.0,z),Vector3(1.9,38.0,3.7),0.54)
 # A strapped seat-level stowage shelf, physically seated across the rails.
 block(frame,Vector3(0,23.8,1),Vector3(width-17,2.1,depth-26),0.63)
 block(frame,Vector3(0,69.8,-depth*0.5+10),Vector3(width-16.7,3.4,6.3),0.78)
 block(frame,Vector3(0,69.8,depth*0.5-10),Vector3(width-16.7,3.4,6.3),0.78)
 for x in [-17.6,17.6]:
  wire(trim,[Vector3(x,24.4,17.2),Vector3(x,28.1,17.35),Vector3(x,29.2,14.5),
   Vector3(x,29.2,-12.4),Vector3(x,24.8,-13.4)],0.64)
 part(world,root,"CrewAshSlattedWorkDesk",frame.commit(),Veneer.make("bed",ASH))
 part(world,root,"CrewLowerRackRestraints",trim.commit(),Finishes.make(Finishes.Finish.LEATHER,LEATHER))
 part(world,root,"CrewLongGrainStiles",legs.commit(),Veneer.make("field",ASH))

static func writing_base(world: Node3D,root: Node3D,width: float,depth: float) -> void:
 var frame := begin()
 var fascia := begin()
 var fittings := begin()
 # The dark writing desk stays open underneath a continuous drawer rail.
 # Slightly tapered modelled columns support it at the original footprint.
 for x in [-width*0.5+8,width*0.5-8]:
  for z in [-depth*0.5+8,depth*0.5-8]:
   var path: Array[Vector3] = [Vector3(x,2.25,z),Vector3(x*0.975,20,z),
     Vector3(x*0.94,52,z),Vector3(x*0.95,71.462,z)]
   wire_sized(frame,path,[1.66,2.0,2.7,2.48])
   block(frame,Vector3(x,1.15,z),Vector3(6.0,2.3,5.7),0.86)
 for z in [-depth*0.5+7,depth*0.5-7]:
  block(frame,Vector3(0,65.25,z),Vector3(width-14,12.5,4.0),0.82)
 for x in [-30.0,30.0]:
  block(frame,Vector3(x,65.25,0),Vector3(3.4,12.5,depth-15),0.63)
 # Broad centre drawer and two smaller stationery drawers. Rails and
 # handles have their own turned contact edges, not drawn-on grooves.
 for segment in [[0.0,31.5],[-22.2,11.8],[22.2,11.8]]:
  var x := float(segment[0])
  block(fascia,Vector3(x,65.15,28.1),Vector3(float(segment[1]),9.0,1.6),0.75)
  var reach := 3.85 if x==0.0 else 2.58
  wire(fittings,[Vector3(x-reach,65.75,28.5),Vector3(x-reach*0.82,64.0,29.68),
    Vector3(x,63.07,30.24),Vector3(x+reach*0.82,64.0,29.68),Vector3(x+reach,65.75,28.5)],0.51)
 part(world,root,"WritingTaperedWalnutFrame",frame.commit(),Veneer.make("field",WRITING_OAK))
 part(world,root,"WritingGraduatedStationeryDrawers",fascia.commit(),Veneer.make("bed",Color("634b38")))
 part(world,root,"WritingDrawnBrassPulls",fittings.commit(),Finishes.make(Finishes.Finish.BRASS,Color("9f8156")))

static func coast_base(world: Node3D,root: Node3D,width: float,depth: float) -> void:
 var frame := begin()
 var countercurves := begin()
 # Bleached elm bent into broad, airy open side hoops, visibly different
 # from a drawer or four turned legs. The rounded cradle remains half-depth.
 for x in [-width*0.5+8,width*0.5-8]:
  for z in [-depth*0.5+9,depth*0.5-9]:
   block(frame,Vector3(x,1.75,z),Vector3(6.85,3.5,7.1),1.0)
  var spine: Array[Vector3] = [
   Vector3(x,3.2,-23.5),Vector3(x,15,-24.7),Vector3(x,35,-21.5),
   Vector3(x,54,-16),Vector3(x,69,-20.8),Vector3(x,69,20.8),
   Vector3(x,54,16),Vector3(x,35,21.5),Vector3(x,15,24.7),Vector3(x,3.2,23.5)]
  wire_sized(frame,spine,[2.35,2.38,2.53,2.63,2.49,2.49,2.63,2.53,2.38,2.35])
  wire(countercurves,[Vector3(x,24.5,-23),Vector3(x,19.5,-15.2),Vector3(x,17.7,-8),
    Vector3(x,17.4,0),Vector3(x,17.7,8),Vector3(x,19.5,15.2),Vector3(x,24.5,23)],1.85)
 # A restrained slatted lip and low shelf on real lower support.
 for x in [-18,-12,-6,0,6,12,18]:
  block(countercurves,Vector3(x,19.5,2),Vector3(4.38,1.6,33.8),0.57)
 for z in [-13.85,16.25]:
  block(frame,Vector3(0,18.35,z),Vector3(57.3,4.3,3.25),0.67)
 block(frame,Vector3(0,69.5,-20.8),Vector3(60.0,4.0,5.1),0.82)
 block(frame,Vector3(0,69.5,20.8),Vector3(60.0,4.0,5.1),0.82)
 part(world,root,"CoastBentElmsOpenHoops",frame.commit(),Veneer.make("field",COAST_LIGHT))
 part(world,root,"CoastCurvedLuggageCradle",countercurves.commit(),Veneer.make("table",Color("8b8066")))

static func wire_sized(out: SurfaceTool,path:Array[Vector3],radii:Array) -> void:
 out.append_from(Props.tube(path,PackedFloat32Array(radii),12),0,Transform3D.IDENTITY)


static func begin() -> SurfaceTool:
 var out := SurfaceTool.new()
 out.begin(Mesh.PRIMITIVE_TRIANGLES)
 return out

static func block(out: SurfaceTool, p: Vector3, dims: Vector3, bevel: float) -> void:
 out.append_from(Props.rounded(dims,bevel),0,Transform3D(Basis.IDENTITY,p))

static func wire(out: SurfaceTool,path:Array[Vector3],radius:float) -> void:
 out.append_from(Props.tube(path,PackedFloat32Array([radius]),8),0,Transform3D.IDENTITY)
