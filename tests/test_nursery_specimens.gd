extends SceneTree
const Plants:=preload("res://scripts/botanical_collection.gd")
func _initialize()->void: call_deferred("run")
func run()->void:
 var observations:=[]
 var signatures:=[]
 var issue:=[]
 for setup in [[-1,1680,2045,"orchid"],[1,1680,2045,"potting"],[-1,2045,2480,"heritage"],[1,2045,2480,"reserve"]]:
  var nursery:=Plants.new()
  root.add_child(nursery)
  nursery.populate(setup[0],setup[1],setup[2])
  var ranges:=PackedVector2Array()
  var ti:=PackedStringArray()
  var outline:=Vector3.ZERO
  var count:=0
  for candidate in nursery.get_children():
   if not candidate is MultiMeshInstance3D or not str(candidate.name).contains("broad_leaf"): continue
   var finest:=candidate as MultiMeshInstance3D
   var mm:=finest.multimesh
   outline=mm.mesh.get_aabb().size
   var item_positions:Array=mm.get_meta("solid_geometry_transforms")
   for blade:Transform3D in item_positions:
    var scale:=blade.basis.get_scale()
    ranges.append(Vector2(scale.x,scale.z))
    if absf(blade.origin.x)>475 or absf(blade.origin.x)<272 or blade.origin.y>210 or blade.origin.z<setup[1]+50 or blade.origin.z>setup[2]-45:
     issue.append("spawn leaves outside original planter depth/height bounds")
   count+=mm.instance_count
   ti.append(str(finest.material_override.get_shader_parameter("tint")))
  if nursery.role!=setup[3] or count!=54 or ti.size()!=3: issue.append("missing differentiated cultivar palette or topology")
  ti.sort()
  var w_f:=0.0
  var z_f:=0.0
  for size in ranges:
   w_f=maxf(w_f,size.x)
   z_f=maxf(z_f,size.y)
  observations.append([setup[3],w_f,z_f,outline.x,count])
  signatures.append(str([w_f,z_f,outline.x,str(ti)]))
 if signatures.size()!=4 or Array(signatures.duplicate()).count(signatures[0])!=1 or signatures[1]==signatures[2] or signatures[1]==signatures[3] or signatures[2]==signatures[3]:
  issue.append("no real palette/shape distinction across nursery rooms")
 if issue.is_empty(): print("PASS: four different conservatory leaf profiles, palettes and fitted planters; same 54 canopy blades each. ",observations)
 else:
  for found in issue: push_error(found)
 quit(0 if issue.is_empty() else 1)
