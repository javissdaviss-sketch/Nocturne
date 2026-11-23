extends SceneTree
const Floors:=preload("res://scripts/room_floor_finish.gd")
const M:=preload("res://scripts/material_library.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
 var fixtures:=[[[0,360],[360,800]],[[840,990],[990,1390],[1390,1640]],[[1680,2045],[2045,2480]]]
 var bad:=[]
 var group:={}
 var kinds:={}
 for car in range(3):
  for side in [-1,1]:
   for limits in fixtures[car]:
    var lo:float=limits[0]
    var hi:float=limits[1]
    var surface:=Floors.get_floor(car,side,lo,hi)
    if surface==null:
     bad.append("floor lacks its own room style")
     continue
    group[surface.get_instance_id()]=true
    kinds[surface.get_shader_parameter("style_kind")]=true
    if surface.get_shader_parameter("floor_center")!=Vector2(side*332,(lo+hi)*0.5) or surface.get_shader_parameter("floor_half")!=Vector2(150,(hi-lo-18)*0.5):
     bad.append("closed floor trim uses wrong physical centre/length")
    if surface.get_shader_parameter("reference_atlas")!=M.ATLAS: bad.append("new art dependencies beyond local photographs")
 if group.size()!=14 or kinds.size()!=4 or Floors.get_floor(3,1,2520,2820)!=null:
  bad.append("work not limited to 14 styled rooms")
 if bad.is_empty(): print("PASS: exact 14 unique floor materials on existing footprints, four surface systems, no extra texture assets or corridor changes.")
 else:
  for issue in bad: push_error(issue)
 quit(0 if bad.is_empty() else 1)
