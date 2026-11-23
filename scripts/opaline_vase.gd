extends RefCounted
## Original Deco opaline flower vase. The glass carries a quiet glow, not a Light3D.
## The original six-centimetre footprint and 96cm maximum height are kept.
const Finishes=preload("res://scripts/material_library.gd")
const AXIS:=Vector3(-127,77.39,1278)
const BRONZE:=Color("9b7b49")
const GLASS:=Color("c4d1b5")

static func fit(world:Node3D)->Node3D:
 var stand:=Node3D.new()
 stand.name="MeridianOpalineVase"
 world.add_child(stand)
 stand.position=AXIS
 var foot:=rotated([Vector2(0,0),Vector2(2.52,0),Vector2(2.73,0.13),
  Vector2(2.80,0.27),Vector2(2.78,0.46),Vector2(2.56,0.62),Vector2(2.23,0.78),
  Vector2(2.13,0.96),Vector2(2.16,1.18),Vector2(0,1.21)],38,0)
 var foot_node:MeshInstance3D=world.mesh_obj(stand,foot,Vector3.ZERO,BRONZE)
 foot_node.name="TurnedBrassVaseFoot"
 foot_node.material_override=Finishes.make(Finishes.Finish.BRASS,BRONZE)
 foot_node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 # The profile runs continuously over the rolled lip and back into a real
 # shallow well. Existing stems seat below the mouth without moving blooms.
 var glass:=rotated([Vector2(0,0.89),Vector2(1.75,0.89),Vector2(2.24,1.08),Vector2(2.56,1.70),
  Vector2(2.77,2.98),Vector2(2.86,5.95),Vector2(2.84,7.84),Vector2(2.69,9.70),
  Vector2(2.46,11.70),Vector2(2.08,13.5),Vector2(1.61,15),Vector2(1.44,16.08),
  Vector2(1.46,17.12),Vector2(1.60,17.69),Vector2(1.77,18.05),Vector2(1.79,18.35),
  Vector2(1.69,18.58),Vector2(1.54,18.60),Vector2(1.39,18.49),
  Vector2(1.31,18.24),Vector2(1.21,17.89),Vector2(1.09,17.68),Vector2(0,17.68)],54,0.065)
 var opal:MeshInstance3D=world.mesh_obj(stand,glass,Vector3.ZERO,GLASS)
 opal.name="FlutedOpalineAndHollowMouth"
 var satin:=StandardMaterial3D.new()
 satin.albedo_color=GLASS
 satin.roughness=0.43
 satin.metallic=0.06
 satin.emission_enabled=true
 satin.emission=Color("adbda1")
 satin.emission_energy_multiplier=0.26
 opal.material_override=satin
 opal.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 return stand

static func rotated(spine:Array[Vector2],sides:int,fluting:float)->ArrayMesh:
 var st:=SurfaceTool.new()
 st.begin(Mesh.PRIMITIVE_TRIANGLES)
 for row in range(spine.size()-1):
  for i in range(sides):
   for tri in [[Vector2i(0,0),Vector2i(0,1),Vector2i(1,0)],
     [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]]:
    var points:Array[Vector3]=[]
    var norms:Array[Vector3]=[]
    var tex:Array[Vector2]=[]
    for point:Vector2i in tri:
     var k:=row+point.y
     var theta:=TAU*float(i+point.x)/sides
     var line:=spine[k]
     var delta:Vector2=spine[mini(spine.size()-1,k+1)]-spine[maxi(0,k-1)]
     var depth:=fluting*smoothstep(0.5,2.1,line.x)
     var radius:=line.x+depth*cos(theta*9.0)
     var perp:=-9.0*depth*sin(theta*9.0)/maxf(0.1,radius)
     points.append(Vector3(radius*cos(theta),line.y,radius*sin(theta)))
     norms.append(Vector3(delta.y*(cos(theta)+perp*sin(theta)),-delta.x,delta.y*(sin(theta)-perp*cos(theta))).normalized())
     tex.append(Vector2(float(i+point.x)/sides,float(k)/(spine.size()-1)))
    if (points[1]-points[0]).cross(points[2]-points[0]).length_squared()<0.00000000001:continue
    var normal:=(norms[0]+norms[1]+norms[2]).normalized()
    var order:=[0,2,1] if (points[1]-points[0]).cross(points[2]-points[0]).dot(normal)>0 else [0,1,2]
    for j in order:
     st.set_normal(norms[j])
     st.set_uv(tex[j])
     st.add_vertex(points[j])
 st.index()
 return st.commit()
