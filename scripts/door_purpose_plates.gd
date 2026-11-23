extends RefCounted
## The corridor's eye-level room names fit into existing parked leaves,
## far from the open apertures. The formal carriage/section headers remain.
const I:=preload("res://scripts/room_identity.gd")
const F:=preload("res://scripts/material_library.gd")
const PURPOSE:Dictionary={
 "0:-1:0":"WRITING BERTH","0:1:0":"CREW BERTH",
 "0:-1:360":"COAST BERTH","0:1:360":"ENGINEERING",
 "1:-1:840":"CONCIERGE","1:1:840":"CLOAKROOM",
 "1:-1:990":"MERIDIAN DINING","1:1:990":"TEA SALON",
 "1:-1:1390":"PANTRY","1:1:1390":"STEWARD'S STORE",
 "2:-1:1680":"ORCHID NURSERY","2:1:1680":"POTTING ROOM",
 "2:-1:2045":"HERITAGE ARCHIVE","2:1:2045":"LIVE RESERVE",
}
const LOOKS:=[[F.Finish.WALNUT,"5f4a3a","d8c6a6"],[F.Finish.CERAMIC,"34554c","edd2a5"],[F.Finish.STEEL,"497468","e2e2ca"]]

static func key(car:int,side:int,lo:float)->String:
 return "%d:%d:%d"%[car,side,int(lo)]

static func attach(w:Node3D,parent:Node3D,car:int,side:int,lo:float,parked:float)->void:
 var id:=key(car,side,lo)
 if not PURPOSE.has(id):return
 var selected:Array=LOOKS[car]
 var holder:=Node3D.new()
 holder.name="Doormark_%d_%d_%d"%[car,side,int(lo)]
 holder.set_meta("door_purpose",id)
 parent.add_child(holder)
 holder.position=Vector3(side*48.42,114.0,parked)
 holder.rotation.y=side*PI*0.5
 var backing:=SurfaceTool.new()
 backing.begin(Mesh.PRIMITIVE_TRIANGLES)
 I.chamfer_slab(backing,Vector2.ZERO,Vector2(36.0,12.8),2.0,0.56)
 var plaque:MeshInstance3D=w.mesh_obj(holder,backing.commit(),Vector3.ZERO,Color.WHITE,true)
 plaque.name="FittedNameplate"
 plaque.material_override=F.make(selected[0],Color(selected[1]),false,false,car==2)
 plaque.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var pin:=SurfaceTool.new()
 pin.begin(Mesh.PRIMITIVE_TRIANGLES)
 for x in [-16.0,16.0]:
  I.disc(pin,Vector2(x,0),0.66,12,0.64)
 var fasteners:MeshInstance3D=w.mesh_obj(holder,pin.commit(),Vector3.ZERO,Color.WHITE,true)
 fasteners.name="FlushPlateFasteners"
 fasteners.material_override=F.make(F.Finish.BRASS,Color("b49b71"))
 fasteners.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var letters:Label3D=w.sign_text(PURPOSE[id],Vector3(0,0,-0.605),0.205,Color(selected[2]),holder)
 letters.name="RoomPurposeLabel"
 letters.double_sided=false
 letters.rotation.y=PI
