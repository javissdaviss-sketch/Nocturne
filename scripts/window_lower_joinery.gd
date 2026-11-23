extends RefCounted
## Side-end bay panels sit under the real sill, not against the glass or
## opening. Two batches per visible model, with exact profile collision.
const Id:=preload("res://scripts/room_identity.gd")
const Finishes:=preload("res://scripts/material_library.gd")
const Veneer:=preload("res://scripts/fitted_veneer.gd")
const Shapes:=preload("res://scripts/prop_meshes.gd")
const NAMES:=["SleeperFoldDownLocker","MeridianWalnutSideboard","GardenInsetVents"]
static var looks:Dictionary={}
static var meshes:Dictionary={}

static func pilot(car:int,lo:int,z:int) -> bool:
 return (car==0 and lo==0 and z in [96,168,240,312]) or (car==1 and lo==990 and z in [1086,1158,1230,1302]) or (car==2 and lo==2045 and z in [2069,2141,2213,2285,2357])

static func build(world:Node3D,parent:Node3D,car:int,side:int,z:float) -> Node3D:
 if not meshes.has(car): meshes[car]=geometry(car)
 if not looks.has(car): looks[car]=finish(car)
 var panel:=Node3D.new()
 panel.name="%s_%d_%d" % [NAMES[car],side,int(z)]
 parent.add_child(panel)
 panel.position=Vector3(side*506.0,47,z)
 panel.rotation.y=side*PI/2
 for i in range(2):
  var form:MeshInstance3D=world.mesh_obj(panel,meshes[car][i],Vector3.ZERO,Color.WHITE,true)
  form.name="RealBacking" if i==0 else "FormedFittings"
  form.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  form.material_override=looks[car][i]
  var shape := form.get_child(0).get_child(0) as CollisionShape3D
  (shape.shape as ConcavePolygonShape3D).backface_collision=true
 return panel

static func finish(car:int)->Array:
 match car:
  0: return [Veneer.make("field",Color("5e5241")),Finishes.make(Finishes.Finish.BRASS,Color("a99368"))]
  1:
   # The faces are Y/Z, so the old bed finish (strand +X) sampled almost
   # the same texel over the whole face. Grain belongs along the sill.
   var wood := Veneer.make("edge",Color("51392f"))
   wood.set_shader_parameter("strand_world",Vector3.BACK)
   wood.set_shader_parameter("repeat_cm",Vector2(27,123))
   wood.set_shader_parameter("satin",0.56)
   wood.set_shader_parameter("coat_amount",0.13)
   return [wood,Finishes.make(Finishes.Finish.BRASS,Color("9d7850"))]
  _: return [Finishes.make(Finishes.Finish.STEEL,Color("374b43"),false,false,true),Finishes.make(Finishes.Finish.STEEL,Color("859084"),false,false,true)]

static func geometry(car:int)->Array:
 var base:=SurfaceTool.new()
 base.begin(Mesh.PRIMITIVE_TRIANGLES)
 var hardware:=SurfaceTool.new()
 hardware.begin(Mesh.PRIMITIVE_TRIANGLES)
 match car:
  0:
   Id.chamfer_slab(base,Vector2(0,0),Vector2(57.9,55.8),4.5,1.0)
   Id.chamfer_slab(base,Vector2(0,-0.2),Vector2(51.1,44.3),8.8,1.73)
   Id.chamfer_slab(base,Vector2(0,-0.15),Vector2(46.5,39.6),9.7,2.05)
   for x in [-16.4,16.4]:
    Id.rail(hardware,Vector2(x-2.3,-20.0),Vector2(x+2.3,-20.0),1.25,2.31)
   hardware.append_from(Shapes.tube([
    Vector3(-4.7,8.1,-2.04),Vector3(-4.6,6.75,-2.70),Vector3(4.6,6.75,-2.70),
    Vector3(4.7,8.1,-2.04)],PackedFloat32Array([0.27]),8),0,Transform3D.IDENTITY)
  1:
   # Continuous raised sill compartment with curved ends and dark vertical
   # separation at existing joins. No bright monocolour pseudo-screens.
   Id.chamfer_slab(base,Vector2(0,0),Vector2(68.0,55.5),5.7,1.15)
   Id.chamfer_slab(base,Vector2(0,2.8),Vector2(58.3,45.3),9.7,1.92)
   Id.chamfer_slab(base,Vector2(0,2.8),Vector2(52.8,36.15),7.5,2.30)
   for y in [-22.6,23.4]:
    Id.rail(base,Vector2(-30.5,y),Vector2(30.5,y),2.2,2.44)
   for x in [-21.0,21.0]: Id.rail(hardware,Vector2(x,-13.9),Vector2(x,17.7),1.1,2.66)
   Id.ring(hardware,Vector2(0,4.3),2.85,1.96,12,2.60)
  _:
   # Actual dark recess between independent louvres. No flat texture
   # pretending to be cut holes, and fan cannot enter the body shell.
   Id.chamfer_slab(base,Vector2(0,0),Vector2(56.1,53.2),4.3,0.75)
   for x in [-25.0,25.0]:
    Id.rail(hardware,Vector2(x,-22.4),Vector2(x,22.4),1.4,1.95)
   for y in [-21.8,-17.5,-11.5,-5.5,0.5,6.5,13.0,21.8]:
    var band:=Vector3(0,y,-1.49)
    hardware.append_from(Shapes.tube([band+Vector3(-25,-0.8,0),
     band+Vector3(-23,0,-0.48),band+Vector3(23,0,-0.48),band+Vector3(25,0.8,0)],
     PackedFloat32Array([0.87]),6),0,Transform3D.IDENTITY)
 return [base.commit(),hardware.commit()]
