extends SceneTree
const World = preload("res://scripts/world.gd")
const Liners = preload("res://scripts/gangway_liners.gd")
func _initialize()->void:call_deferred("run")
func run()->void:
 var errors:Array[String]=[]
 var component:=OS.get_cmdline_user_args().has("--component-only")
 # Component-only probes the actual profile, and uses the same original clear
 # rectangular physical planes as criteria; the World mode adds real sweeps.
 var passes:=0
 for garden in [false,true]:
  var contour:=Liners.profile(garden)
  if contour.size()!=(36 if garden else 28):errors.append("fold count")
  for i in range(contour.size()):
   if not contour[i].is_finite() or contour[i].y<0 or contour[i].y>=Liners.BACK_DEPTH or (i>0 and contour[i].x<=contour[i-1].x):
    errors.append("invalid or narrowing contour")
 if component:
  print("Gangway authored profiles issues=",errors)
  quit(0 if errors.is_empty() else 1)
  return
 var train:=World.new()
 root.add_child(train)
 await physics_frame
 await process_frame
 var space:=train.get_world_3d().direct_space_state
 var shape:=SphereShape3D.new()
 shape.radius=0.16
 var search:=PhysicsShapeQueryParameters3D.new()
 search.shape=shape
 search.collision_mask=1
 var depth_ranges:Dictionary={}
 for row in [[820.0,"MeridianBellows"],[1660.0,"BotanicalBellows"]]:
  var mid:float=row[0]
  var liner:=train.get_node(NodePath(row[1])) as Node3D
  var parts:=liner.find_children("Formed*","MeshInstance3D",false,false)
  if parts.size()!=2:errors.append("two bounded mesh batches required")
  for part:MeshInstance3D in parts:
   if part.mesh.get_faces().size()/3>1000 or part.cast_shadow!=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
    errors.append("unexpected geometry or shadow budget")
  for x in [-53.0,-30.0,0.0,30.0,53.0]:
   for height in [2.5,16.0,90.0,158.0,215.0]:
    for direction in [-1,1]:
     # The end portals already have local fascia/furniture outside ±30;
     # compare the narrow inside margins of the actual 40cm gangway itself.
     var half_distance := 19.0 if absf(x)>30.0 else 26.0
     search.transform.origin=Vector3(x,height,mid-half_distance*direction)
     search.motion=Vector3(0,0,2.0*half_distance*direction)
     if space.cast_motion(search)[0]<0.999:errors.append("blocked previous route "+str([row,x,height,direction]))
     passes+=1
  # Verify that the ray meets the actual lining mesh before its structural
  # backing at repeated stations, with a genuine >1cm depth change.
  var lo:=INF
  var hi:=-INF
  for z in range(-13,14):
   for aim in [Vector3(61,118,mid+z),Vector3(-61,118,mid+z),Vector3(0,236,mid+z)]:
    var from:=Vector3(0,118 if aim.x!=0 else 222,aim.z)
    var ray:=PhysicsRayQueryParameters3D.create(from,aim,1)
    ray.hit_back_faces=true
    var hit:=space.intersect_ray(ray)
    if hit.is_empty():
     errors.append("lining aperture opened unexpectedly")
     continue
    var contact:Vector3=hit.position
    var depth:float=absf(contact.x)-55.0 if aim.x!=0 else contact.y-230.0
    if depth < -0.015 or depth>2.0 or not liner.is_ancestor_of(hit.collider):
     errors.append("visual-contact mismatch "+str([aim,contact,hit.collider.get_path()]))
    lo=minf(lo,depth)
    hi=maxf(hi,depth)
  depth_ranges[row[1]]=Vector2(lo,hi)
  if hi-lo<1.05:errors.append("profile is flat in physical world")
 print("Gangway liners issues=",errors," original_clear_sweeps=",passes," physical_depth_cm=",depth_ranges)
 train.queue_free()
 await process_frame
 quit(0 if errors.is_empty() else 1)
