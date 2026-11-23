extends SceneTree
const Drapes:=preload("res://scripts/sleeping_assets.gd")
const Heads:=preload("res://scripts/window_head_finish.gd")
class Stage extends "res://scripts/world.gd":
 func _ready()->void:pass
func _initialize()->void:call_deferred("run")
func run()->void:
 var fixture:=Stage.new()
 root.add_child(fixture)
 var issues:=[]
 var masks:={}
 var cast:={}
 var count:=0
 for car in range(3):
  var unit:=Drapes.build_curtains(fixture,fixture,car)
  var inside:=[]
  for child in unit.get_children():
   if not str(child.name).begins_with("FittedWindowCurtain_"):continue
   var group:=child as Node3D
   var label:String=group.get_meta("curtain_role")
   var role:=int(label.split(":")[2])
   var limits:Array=Heads.COACH_WALLS[car]
   var half:float=group.get_meta("physical_drop_half_cm")
   if not (group.position.z-half>=limits[role]+5.7-0.003 and
      group.position.z+half<=limits[role+1]-5.7+0.003 and half<=15.5 and half>=4.0):
    issues.append("cloth crosses the structural partition "+label)
   masks[label]=true
   count+=1
   var curtain:=group.get_child(0) as MeshInstance3D
   if not curtain.material_override is ShaderMaterial or absf(curtain.position.x)!=489 or curtain.position.y!=103:
    issues.append("unexpected visible curtain or mount shift")
   else:cast[curtain.material_override.get_instance_id()]=true
   var real:=group.transform*curtain.transform*curtain.get_aabb()
   if real.position.z<group.position.z-half-0.004 or real.end.z>group.position.z+half+0.004:
    issues.append("actual physical cloth extends beyond the planned grade")
   inside.append(real.position.z)
 if masks.size()!=14 or count!=32 or cast.size()!=14:
  issues.append("every distinct room should have its own cloth treatment "+str([masks.size(),count,cast.size()]))
 var hard:=Drapes.curtain_plan(1,1390)
 if hard.size()!=2 or hard[0].last>=1390 or hard[1].first<=1390: issues.append("legacy divider-straddling cloth must be split, not extended")
 if issues.is_empty(): print("PASS: 32 actual separately fitted folds across 14 fabric roles; old divider-straddling curtain physically cut into two mounted panels.")
 else:
  for item in issues: push_error(item)
 quit(0 if issues.is_empty() else 1)
