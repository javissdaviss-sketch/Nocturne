extends RefCounted
## The lighter tea-chair is open over its seat, with carved S-shaped uprights
## and a real bowed steam-bent crown, rather than a tufted panel.
const Props := preload("res://scripts/prop_meshes.gd")
const Veneer := preload("res://scripts/fitted_veneer.gd")

static func build(world: Node3D, seat: Node3D, timber: Color) -> void:
 var path: Array[Vector3] = []
 var weight := PackedFloat32Array()
 # The back rack is physically open. Low uprights merge into the original
 # raised seat frame; the arc is structural and carries a shallow headrest rail.
 for branch in [-1,0,1]:
  for i in range(21):
   var t := float(i)/20.0
   match branch:
    -1:
     path.append(Vector3(-24.1-2.1*sin(t*PI),39.2+43.4*t,25.2+t*2.1))
     weight.append(1.85+0.46*t)
    0:
     var x := lerpf(-24.1,24.1,t)
     path.append(Vector3(x,82.6+7.0*pow(maxf(0.0,1.0-pow(absf(t*2.0-1.0),2.0)),1.15),27.3-2.6*sin(t*PI)))
     weight.append(2.31+0.75*sin(t*PI))
    1:
     path.append(Vector3(24.1+2.1*sin(t*PI),82.6-43.4*t,27.3-t*2.1))
     weight.append(2.31-0.46*t)
 # Join endpoints only once to keep the tube's tangent finite.
 path.remove_at(42)
 path.remove_at(21)
 weight.remove_at(42)
 weight.remove_at(21)
 var rack: MeshInstance3D = world.mesh_obj(seat,Props.tube(path,weight,12),Vector3.ZERO,timber,true)
 rack.name = "TeaChairSteamBentCrown"
 rack.material_override = Veneer.make("bed",timber)
 # Three receding, open dividers follow the intended chair silhouette.
 # Each meets the physical curved rail at top and the seat crossbar at bottom.
 for k in [-1,0,1]:
  var fins: Array[Vector3] = []
  var fade := PackedFloat32Array()
  for i in range(17):
   var t := float(i)/16.0
   var x := float(k)*lerpf(10.4,11.1,smoothstep(0,1,t))
   var top := 88.4 if k==0 else 86.5
   fins.append(Vector3(x,44.0+t*(top-44.0),25.35-1.17*sin(t*PI)))
   fade.append(0.79+0.33*pow(sin(t*PI),2))
  var slat: MeshInstance3D = world.mesh_obj(seat,Props.tube(fins,fade,8),Vector3.ZERO,timber,true)
  slat.name = "TeaChairOpenSplats"
  slat.material_override = rack.material_override
