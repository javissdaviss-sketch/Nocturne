extends SceneTree

const Identity:=preload("res://scripts/room_identity.gd")
const Layout:=preload("res://scripts/train_layout.gd")
const World:=preload("res://scripts/world.gd")
const SHIFTED:=["CrewKitShelf","CoastPorthole","EngineeringInstrumentBay"]

func _initialize()->void: call_deferred("run")
func run()->void:
 var lightweight:=OS.get_cmdline_user_args().has("--component-only")
 var errors:Array[String]=[]
 if lightweight:
  var examples:Array[Dictionary]=[
   {"car":0,"side":-1,"lo":0.0,"hi":360.0,"entry":55.0,"name":"WritingBerthTambour"},
   {"car":0,"side":1,"lo":0.0,"hi":360.0,"entry":194.0,"name":"CrewKitShelf"},
   {"car":0,"side":-1,"lo":360.0,"hi":800.0,"entry":740.0,"name":"CoastPorthole"},
   {"car":0,"side":1,"lo":360.0,"hi":800.0,"entry":740.0,"name":"EngineeringInstrumentBay"},
   {"car":1,"side":1,"lo":990.0,"hi":1390.0,"entry":1240.0,"name":"TeawareShelves"}
  ]
  for room in examples: check_mount(room,room.name,errors)
 else:
  var world:=World.new()
  root.add_child(world)
  await physics_frame
  await physics_frame
  var layout:Layout=world.get_node("CompartmentLayout")
  var space:=world.get_world_3d().direct_space_state
  var visible:=0
  for room in layout.rooms:
   var name:String=Identity.style(room)[0]
   check_mount(room,name,errors)
   var fixture:Node3D=world.find_child(name,true,false)
   if not is_instance_valid(fixture) or not fixture.global_transform.is_equal_approx(Identity.mount(room)):
    errors.append(name+": missing single intended built fitting")
    continue
   if name in SHIFTED:
    var toward_room:=fixture.global_basis*Vector3.FORWARD
    var hit:=space.intersect_ray(PhysicsRayQueryParameters3D.create(fixture.global_position+toward_room*14,fixture.global_position+toward_room*0.3,1))
    if hit.is_empty(): errors.append(name+": fitted relief does not have physical front geometry")
    var from:=Vector3(room.side*104,115,room.entry)
    var aim:=Vector3(room.side*369,132,(room.lo+room.hi)*0.5)
    var direction:Vector3=(aim-from).normalized()
    var center:Vector3=(fixture.global_position-from).normalized()
    if direction.dot(center)<cos(deg_to_rad(51.0)): errors.append(name+": fitting outside fixed entrance horizontal field")
    var regions:=0
    for off in [Vector2.ZERO,Vector2(-16,0),Vector2(16,0),Vector2(0,-10),Vector2(0,12)]:
     var target:=Vector3(fixture.global_position.x+off.x,fixture.global_position.y+off.y,fixture.global_position.z)
     var first:=space.intersect_ray(PhysicsRayQueryParameters3D.create(from,target,1))
     if not first.is_empty() and first.position.distance_to(target)<8.0: regions+=1
    if regions<3: errors.append(name+": too much of the finished feature still hidden on entry")
    else: visible+=1
  if visible!=SHIFTED.size(): errors.append("expected three physically built forward-facing residence features")
  world.queue_free()
 print("Residence wall focus ", "component" if lightweight else "full world", " issues=",errors)
 quit(0 if errors.is_empty() else 1)

func check_mount(room:Dictionary,name:String,errors:Array[String])->void:
 var fitted:=Identity.mount(room)
 var new_side:=name in SHIFTED
 var end:float=room.lo if new_side else room.hi
 var into:=1.0 if new_side else -1.0
 var center:=Vector3(room.side*350,160,end+into*(Identity.bulkhead_liner_inset(room.car,end)+0.5))
 if not fitted.origin.is_equal_approx(center) or not (fitted.basis*Vector3.FORWARD).is_equal_approx(Vector3(0,0,into)):
  errors.append(name+": backing and front normal mismatch")
