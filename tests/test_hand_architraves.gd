extends SceneTree
const Portal:=preload("res://scripts/coach_architraves.gd")
class Stage extends "res://scripts/world.gd":
 func _ready()->void: pass
func _initialize()->void: call_deferred("run")
func run()->void:
 var sim:=Stage.new()
 root.add_child(sim)
 var notes:=[]
 var fitted:=[]
 for car in [0,2]:
  var z:float=50+car*840
  for side in [-1,1]:
   var tall:=Portal.add(sim,sim,car,Vector3(side*55,112,z),Vector3(9,224,3))
   var head:=Portal.add(sim,sim,car,Vector3(side*55,223,z+70),Vector3(9,3,98))
   for unit in [tall,head]:
    var dims:=Vector3(9.005,224.005,3.005) if unit==tall else Vector3(9.005,3.005,98.005)
    var allowed:=AABB(-dims*0.5,dims)
    var size:=0
    if unit.get_child_count()!=2: notes.append("same unmodelled block or bad grouping")
    for piece:MeshInstance3D in unit.get_children():
     if not allowed.encloses(piece.get_aabb()): notes.append("new architrave projects into existing clear envelope "+str(piece.get_aabb()))
     size+=piece.mesh.get_faces().size()/3
    if size<120 or size>800: notes.append("bad geometry budget "+str(size))
   fitted.append([car,side,z])
 await physics_frame
 await physics_frame
 var sp:=sim.get_world_3d().direct_space_state
 var cutoffs:=[]
 for sample in fitted:
  var side:float=sample[1]
  var z:float=sample[2]
  var solids:=PhysicsRayQueryParameters3D.create(Vector3(side*47,112,z+0.18),Vector3(side*60,112,z+0.18))
  var clear:=PhysicsRayQueryParameters3D.create(Vector3(side*47,112,z+2.1),Vector3(side*60,112,z+2.1))
  var step:=PhysicsRayQueryParameters3D.create(Vector3(side*47,112,z+1.36),Vector3(side*60,112,z+1.36))
  var found:=sp.intersect_ray(solids)
  var second:=sp.intersect_ray(step)
  if found.is_empty() or second.is_empty() or not sp.intersect_ray(clear).is_empty():
   notes.append("actual physical contact missing or stone trim enters original clear slot")
  else:
   var arc:float=absf(found.position.x-second.position.x)
   if arc<0.20: notes.append("side of jamb is a flat face, not formed")
   cutoffs.append(arc)
 if cutoffs.size()==4 and absf(cutoffs[0]-cutoffs[2])<0.08: notes.append("two roles did not use visibly distinct shapes")
 if notes.is_empty(): print("PASS: two physically distinct coach door cross-sections, both handed, with original doorway borders; non-flat shoulder offsets ",cutoffs)
 else:
  for note in notes: push_error(note)
 quit(0 if notes.is_empty() else 1)
