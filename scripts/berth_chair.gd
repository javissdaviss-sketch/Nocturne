extends RefCounted
## Purpose-built writing, crew, coast and engineering desk seats. All backs
## keep the original legs, seating support and authored furniture footprint.
const P:=preload("res://scripts/prop_meshes.gd")
const G:=preload("res://scripts/service_focal_structures.gd")
const Mat:=preload("res://scripts/material_library.gd")
const Veneer:=preload("res://scripts/fitted_veneer.gd")
const FINISH:Dictionary={
 "writing":["513b37","745055",Mat.Finish.VELVET],
 "crew":["756752","605e47",Mat.Finish.LINEN],
 "coast":["7d7561","657579",Mat.Finish.LINEN],
 "engineering":["536162","424f4e",Mat.Finish.LEATHER],
}

static func build(w:Node3D,seat:Node3D,role:String)->void:
 var recipe:Array=FINISH[role]
 var frame:=G.begin()
 var cloth:=G.begin()
 var have_cloth:=role!="coast"
 match role:
  "writing":
   # Walnut bridge with a separate fitted velvet panel. Open between
   # the bridge panel and seat instead of the former full solid backrest.
   var shape := PackedVector2Array([
    Vector2(-25,57),Vector2(-25,72),Vector2(-22,82),Vector2(-16,87),
    Vector2(-7,90),Vector2(7,90),Vector2(16,87),Vector2(22,82),
    Vector2(25,72),Vector2(25,57),Vector2(16,53),Vector2(-16,53)])
   G.prism(frame,shape,22.9,29.8)
   wire(frame,[Vector3(-24,33,25),Vector3(-25,56,25)],2.0)
   wire(frame,[Vector3(24,33,25),Vector3(25,56,25)],2.0)
   for i in range(shape.size()):
    var a:=shape[i]
    var b:=shape[(i+1)%shape.size()]
    wire(frame,[Vector3(a.x,a.y,22.85),Vector3(b.x,b.y,22.85)],0.66)
   G.block(cloth,Vector3(0,72,22.9),Vector3(43,29,6.8),2.95)
  "crew":
   # Low tensioned canvas is hung from ash stiles with a visible open base.
   for x in [-25.,25.]:
    wire(frame,[Vector3(x,33,25),Vector3(x*0.98,53,25.6),
     Vector3(x*0.97,68,27),Vector3(x*0.92,80,28)],2.0)
   wire(frame,[Vector3(-23,80,28),Vector3(-17,82,29),Vector3(17,82,29),Vector3(23,80,28)],1.55)
   wire(frame,[Vector3(-24,52,25.6),Vector3(0,51,26.6),Vector3(24,52,25.6)],1.5)
   develop_sling(cloth)
  "coast":
   var arch:Array[Vector3]=[]
   for i in range(19):
    var a:=PI*float(i)/18
    arch.append(Vector3(24*cos(a),73+16*sin(a),27+sin(a)*1.5))
   wire(frame,arch,2.05)
   for x in [-24.0,24.0]:
    wire(frame,[Vector3(x,33,25),Vector3(x,56,26),Vector3(x,73,27)],2.0)
   wire(frame,[Vector3(-24,49,25.5),Vector3(0,49,25.0),Vector3(24,49,25.5)],1.7)
   for i in [-1,0,1]:
    var x:=10.1*float(i)
    wire(frame,[Vector3(x*0.93,49,25),Vector3(x,65,23.7),
     Vector3(x*1.13,78,25.0),Vector3(x,87.5-1.2*abs(i),28.1)],1.27)
  "engineering":
   # Blackened tube and low padded top rail; no trappings of the lounge.
   wire(frame,[Vector3(-24,33,24.2),Vector3(-25,69,27),
    Vector3(-22,78,28),Vector3(-16,80,29.3),Vector3(16,80,29.3),
    Vector3(22,78,28),Vector3(25,69,27),Vector3(24,33,24.2)],1.95)
   wire(frame,[Vector3(-24.25,56,26.5),Vector3(24.25,56,26.5)],1.65)
   wire(frame,[Vector3(-21.0,70,27.4),Vector3(21.0,70,27.4)],1.55)
   for x in [-18.0,18.0]:
    wire(frame,[Vector3(x,48,26.0),Vector3(x,71,27.5)],1.1)
   G.block(cloth,Vector3(0,70.8,26.05),Vector3(43.2,12.6,6.0),2.4)
   for i in range(6):
    var x:float=-15.0+float(i)*6
    wire(cloth,[Vector3(x,66.05,23.1),Vector3(x,75.05,23.1)],0.30)
 var frame_tint:=Color(recipe[0])
 var frame_mat:=Mat.make(Mat.Finish.STEEL,frame_tint) if role=="engineering" else Veneer.make("field",frame_tint)
 fit(w,seat,frame.commit(),role.capitalize()+"ShapedDeskChairBack",frame_mat)
 if have_cloth:
  fit(w,seat,cloth.commit(),role.capitalize()+"DeskChairUpholstery",Mat.make(recipe[2],Color(recipe[1])))

static func develop_sling(out:SurfaceTool)->void:
 for scan in range(2):
  var normal:=Vector3.FORWARD if scan==0 else Vector3.BACK
  for y in range(5):
   for x in range(10):
    var points:Array[Vector3]=[]
    for offset in [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
     var u:=float(x+offset.x)/10.0*2.0-1.0
     var v:=float(y+offset.y)/5.0
     points.append(sling_point(u,v,scan))
    P.quad(out,points,[normal,normal,normal,normal])
 for u in [-1.,1.]:
  for y in range(5):
   var low:=float(y)/5.0
   var high:=float(y+1)/5.0
   var n:=Vector3(u,0,0)
   P.quad(out,[sling_point(u,low,0),sling_point(u,low,1),sling_point(u,high,1),sling_point(u,high,0)],[n,n,n,n])
 for v in [0.,1.]:
  for x in range(10):
   var lo:=float(x)/5.0-1.0
   var hi:=float(x+1)/5.0-1.0
   var n:=Vector3(0,signf(v-0.5),0)
   P.quad(out,[sling_point(lo,v,0),sling_point(hi,v,0),sling_point(hi,v,1),sling_point(lo,v,1)],[n,n,n,n])
 for y in [0.06,0.95]:
  var seam:Array[Vector3]=[]
  for i in range(11):
   seam.append(sling_point(float(i)/5.0-1.0,y,0)+Vector3(0,0,-0.14))
  wire(out,seam,0.23)

static func sling_point(u:float,v:float,rear:int)->Vector3:
 var x:=u*lerpf(23.4,22.6,v)
 var y:=lerpf(52.0,80.9,v)-sin(v*PI)*0.6+(1.0-u*u)*smoothstep(0.25,1.0,v)*0.7
 var sag:float=(1.0-u*u)*(0.8+1.9*sin(v*PI))
 return Vector3(x,y,lerpf(24.1,27.4,v)+sag+rear*1.34)

static func wire(out:SurfaceTool, path:Array[Vector3],radius:float)->void:
 out.append_from(P.tube(path,PackedFloat32Array([radius]),10),0,Transform3D.IDENTITY)

static func fit(w:Node3D,p:Node3D,m:ArrayMesh,label:String,mat:Material)->void:
 var solid:MeshInstance3D=w.mesh_obj(p,m,Vector3.ZERO,Color.WHITE,true)
 solid.name=label
 solid.material_override=mat
 solid.set_meta("berth_chair_back",true)
