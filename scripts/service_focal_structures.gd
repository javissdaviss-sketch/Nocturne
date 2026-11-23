extends RefCounted
## Large, room-specific service silhouettes at the real counter. All new
## structures fit the existing footprint/deck/height and use physical meshes.
const Props:=preload("res://scripts/prop_meshes.gd")
const Identity:=preload("res://scripts/room_identity.gd")
const Mat:=preload("res://scripts/material_library.gd")
const Veneer:=preload("res://scripts/fitted_veneer.gd")

static func dress(w:Node3D, root:Node3D,width:float,role:String)->void:
 match role:
  "concierge":
   fit(w,root,"ConciergeCounterArch",concierge_fascia(width),Veneer.make("field",Color("334c3e")))
   fit(w,root,"ConciergeCastCrown",concierge_trim(width),Mat.make(Mat.Finish.BRASS,Color("a58b5f")))
   legend(w,root,"CONCIERGE",Vector3(0,186,-54.5), Color("dcc39a"))
  "cloak":
   fit(w,root,"CloakroomFittedCoatRail",cloak_frame(width),Mat.make(Mat.Finish.STEEL,Color("798580"),false,false,true))
   fit(w,root,"CloakroomHangingTopcoat",cloak_coat(),Mat.make(Mat.Finish.VELVET,Color("76584b")))
  "steward":
   fit(w,root,"StewardSolidSortingCase",sorting_frame(width),Veneer.make("field",Color("46504b")))
   fit(w,root,"StewardSortingSlotEdges",sorting_trim(width),Mat.make(Mat.Finish.STEEL,Color("8c8b74"),false,false,true))
   legend(w,root,"DISPATCH",Vector3(0,186.2,26.75),Color("e0d3b3"))

static func concierge_fascia(width:float)->ArrayMesh:
 var out:=begin()
 var edge:=width*0.5-9.5
 for x in [-edge,edge]:
  block(out,Vector3(x,128,-48.4),Vector3(7.2,64,10),1.4)
  block(out,Vector3(x,99,-48),Vector3(11.5,6,13),1.2)
 var rise:=34.0
 for row in range(18):
  var a:=PI*float(row)/18.0
  var b:=PI*float(row+1)/18.0
  var span:PackedVector2Array=[
   Vector2(edge*cos(a),156+rise*sin(a)),Vector2(edge*cos(b),156+rise*sin(b)),
   Vector2((edge-8)*cos(b),156+(rise-8)*sin(b)),Vector2((edge-8)*cos(a),156+(rise-8)*sin(a))]
  prism(out,span,-53,-43)
 block(out,Vector3(0,186,-51.8),Vector3(66,13,4.8),0.9)
 return out.commit()

static func concierge_trim(width:float)->ArrayMesh:
 var out:=begin()
 var edge:=width*0.5-11.0
 for x in [-edge,edge]:
  wire(out,[Vector3(x,103,-53.05),Vector3(x,156,-53.05)],0.58)
 var arc:Array[Vector3]=[]
 for i in range(37):
  var a:=PI*float(i)/36.0
  arc.append(Vector3(edge*cos(a),156+32.1*sin(a),-53.12))
 wire(out,arc,0.71)
 for x in [-34.2,34.2]:
  block(out,Vector3(x,186,-53.5),Vector3(1.8,7.2,1.1),0.24)
 return out.commit()

static func cloak_frame(width:float)->ArrayMesh:
 var out:=begin()
 var edge:=width*0.5-11.0
 for x in [-edge,edge]:
  wire(out,[Vector3(x,96.3,17),Vector3(x,177,17),Vector3(x,185,12),Vector3(x,185,-13)],1.55)
  block(out,Vector3(x,97.5,17),Vector3(9.6,3.0,8.4),0.5)
 wire(out,[Vector3(-edge,185,-13),Vector3(edge,185,-13)],1.62)
 for x in [-29.0,21.0,40.0]:
  wire(out,[Vector3(x,182,-13),Vector3(x,182,-15),Vector3(x,177,-16),Vector3(x,174.7,-13)],0.65)
 wire(out,[Vector3(-50,166,-14),Vector3(-29,177,-14),Vector3(-9,166,-14)],0.72)
 return out.commit()

static func cloak_coat()->ArrayMesh:
 var out:=begin()
 # Tapered real closed shell with narrow sleeves and alternating fold depth.
 var contour:PackedVector2Array=[
  Vector2(-38,172),Vector2(-21,172),Vector2(-18,166),Vector2(-7,162),
  Vector2(-7,152),Vector2(-6,134),Vector2(-11,128),Vector2(-17,139),
  Vector2(-18,113),Vector2(-30,111),Vector2(-42,115),Vector2(-43,138),
  Vector2(-47,129),Vector2(-54,133),Vector2(-51,158),Vector2(-43,166)]
 prism(out,contour,-21.4,-12.7)
 for i in range(5):
  var x:float=-40+float(i)*4.5
  wire(out,[Vector3(x+1,159,-21.15),Vector3(x-0.7,139,-21.9),
   Vector3(x+0.4,121,-21.47),Vector3(x+0.8,115,-21.3)],0.85+0.19*float(i%2))
 wire(out,[Vector3(-37,170,-22.0),Vector3(-29.5,161,-22.3),Vector3(-21,170,-22.0)],1.45)
 wire(out,[Vector3(-29.5,161,-22.1),Vector3(-29.25,115,-22.0)],0.54)
 return out.commit()

static func sorting_frame(width:float)->ArrayMesh:
 var out:=begin()
 var size:=width-26.0
 block(out,Vector3(0,99,43),Vector3(size,6,40),0.8)
 block(out,Vector3(0,136,60),Vector3(size,77,5.3),0.85)
 block(out,Vector3(0,166,44),Vector3(size,5.4,35),1.0)
 for i in range(5):
  var x:float=lerpf(-size*0.5+3.2,size*0.5-3.2,float(i)/4.0)
  var support:=PackedVector2Array([Vector2(23,102),Vector2(62,102),
   Vector2(62,168),Vector2(40,168),Vector2(35,155),Vector2(23,126)])
  # The stepped divider is first modeled facing -Z, then rotated into Y/Z.
  var side:=begin()
  prism(side,support,-2.1,2.1)
  out.append_from(side.commit(),0,Transform3D(Basis(Vector3.UP,-PI/2),Vector3(x,0,0)))
 for y in [123.0,145.0]:
  block(out,Vector3(0,y,43),Vector3(size-6,3.2,31.6),0.75)
 # The housed paper sorts remain physically open; the label is placed
 # above them and the existing front dispatch worktop stays unobstructed.
 block(out,Vector3(0,186.2,30),Vector3(76,11.4,6.0),0.9)
 block(out,Vector3(0,180.4,44),Vector3(83.5,9.4,25),1.2)
 return out.commit()

static func sorting_trim(width:float)->ArrayMesh:
 var out:=begin()
 var size:=width-26.0
 for y in [102.4,124.55,146.55]:
  wire(out,[Vector3(-size*0.5+8,y,26.55),Vector3(size*0.5-8,y,26.55)],0.7)
 for x in [-40.0,40.0]:
  block(out,Vector3(x,186.2,27.2),Vector3(1.0,6.3,1.7),0.22)
 return out.commit()

static func legend(w:Node3D,p:Node3D,words:String,pos:Vector3,tone:Color)->void:
 var title:Label3D=w.sign_text(words,pos,0.63,tone,p)
 title.rotation.y=PI
 title.name=words.capitalize()+"CounterLegend"

static func fit(w:Node3D,p:Node3D,key:String,shape:ArrayMesh,finish:Material)->void:
 var part:MeshInstance3D=w.mesh_obj(p,shape,Vector3.ZERO,Color.WHITE,true)
 part.name=key
 part.material_override=finish
 part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 part.set_meta("service_focal_structure",true)

static func begin()->SurfaceTool:
 var result:=SurfaceTool.new()
 result.begin(Mesh.PRIMITIVE_TRIANGLES)
 return result

static func wire(out:SurfaceTool,path:Array[Vector3],radius:float)->void:
 out.append_from(Props.tube(path,PackedFloat32Array([radius]),8),0,Transform3D.IDENTITY)

static func block(out:SurfaceTool,p:Vector3,size:Vector3,r:float)->void:
 # A 2-segment profile keeps real rounded edges without adding close-up density
 # to all of the back-of-counter fittings.
 var half:=size*0.5
 var radius:=minf(r,minf(half.x,minf(half.y,half.z))*0.95)
 var inside:=half-Vector3.ONE*radius
 for axis in range(3):
  var u:=(axis+1)%3
  var v:=(axis+2)%3
  var us:=corners(half[u],radius)
  var vs:=corners(half[v],radius)
  for side in [-1,1]:
   for i in range(3):
    for j in range(3):
     var points:Array[Vector3]=[]
     var normals:Array[Vector3]=[]
     for c in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
      var q:=Vector3.ZERO
      q[axis]=half[axis]*side
      q[u]=us[i+c.x]
      q[v]=vs[j+c.y]
      var near:=q.clamp(-inside,inside)
      var norm:Vector3=(q-near).normalized()
      points.append(p+near+norm*radius)
      normals.append(norm)
     Props.quad(out,points,normals)

static func corners(half:float,bevel:float)->PackedFloat32Array:
 return PackedFloat32Array([-half,-half+bevel,half-bevel,half])

static func prism(out:SurfaceTool,shape:PackedVector2Array,front:float,back:float)->void:
 var idx:=Geometry2D.triangulate_polygon(shape)
 for i in range(0,idx.size(),3):
  var a:=shape[idx[i]]
  var b:=shape[idx[i+1]]
  var c:=shape[idx[i+2]]
  Identity.triangle(out,Vector3(a.x,a.y,front),Vector3(b.x,b.y,front),Vector3(c.x,c.y,front),Vector3.FORWARD)
  Identity.triangle(out,Vector3(a.x,a.y,back),Vector3(b.x,b.y,back),Vector3(c.x,c.y,back),Vector3.BACK)
 var area:=0.0
 for i in range(shape.size()): area+=shape[i].cross(shape[(i+1)%shape.size()])
 for i in range(shape.size()):
  var a:=shape[i]
  var b:=shape[(i+1)%shape.size()]
  var n2:=Vector2(b.y-a.y,a.x-b.x).normalized()
  if area<0.0: n2=-n2
  var normal:=Vector3(n2.x,n2.y,0)
  Props.quad(out,[Vector3(a.x,a.y,front),Vector3(a.x,a.y,back),
   Vector3(b.x,b.y,back),Vector3(b.x,b.y,front)],[normal,normal,normal,normal])
