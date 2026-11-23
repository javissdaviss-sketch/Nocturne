extends CharacterBody3D

const TrainLayout = preload("res://scripts/train_layout.gd")
const DOUBLE_TAP_WINDOW := 0.30
const JUMP_SPEED := 18.0
const JUMP_GRAVITY := 90.0
const FLIGHT_EYE_RADIUS := 0.12
const FLIGHT_EYE_PAD := 0.025
const BOOM_RELEASE_SPEED := 16.0
var yaw := 0.0
var pitch := -0.12
var distance := 14.0
var sensitivity := 0.0025
var landed := false
var jumping := false
var space_tap_remaining := 0.0
var active := false
var precision := false
var precision_toggle := false
var precision_latched := false
var body_collision: CollisionShape3D
var restore_pending := false
var camera: Camera3D
var visual: Node3D
var wing_l: MeshInstance3D
var wing_r: MeshInstance3D
var safe_position := Vector3(-75,88,1225)
var clock := 0.0
var inspection := false
var focus := Vector3.ZERO
var inspect_distance := 25.0
var inspect_max_distance := 120.0
var inspect_yaw := 0.5
var inspect_pitch := 0.55
var inspect_eye_shape := SphereShape3D.new()
var flight_eye_shape := SphereShape3D.new()
var flight_eye_query := PhysicsShapeQueryParameters3D.new()
var flight_boom_anchor := Vector3.ZERO
var flight_boom_length := 0.0
var flight_boom_zoom := 0.0
var flight_boom_actor := Vector3.ZERO
var flight_boom_valid := false
var flight_boom_releasing := false
var inspect_clear_pose := Transform3D.IDENTITY
var inspect_clear_pose_valid := false

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 floor_snap_length = 0.15
 safe_margin = 0.015
 var shape := CollisionShape3D.new()
 body_collision = shape
 var sphere := SphereShape3D.new()
 sphere.radius = 0.16
 shape.shape = sphere
 add_child(shape)
 visual = Node3D.new()
 add_child(visual)
 var m := SphereMesh.new()
 m.radius = 0.12
 m.height = 0.46
 m.radial_segments = 12
 m.rings = 8
 var body := MeshInstance3D.new()
 body.mesh = m
 body.rotation.x = PI/2
 var shell := StandardMaterial3D.new()
 shell.albedo_color = Color("293f3d")
 shell.metallic = 0.55
 shell.roughness = 0.3
 body.material_override = shell
 visual.add_child(body)
 var head := MeshInstance3D.new()
 head.mesh = SphereMesh.new()
 head.scale = Vector3(0.21,0.17,0.18)
 head.position = Vector3(0,0.03,-0.22)
 head.material_override = shell
 visual.add_child(head)
 for side in [-1,1]:
  var eye := MeshInstance3D.new()
  eye.mesh = SphereMesh.new()
  eye.scale = Vector3(0.12,0.12,0.12)
  eye.position = Vector3(side*0.08,0.06,-0.26)
  var em := StandardMaterial3D.new()
  em.albedo_color = Color("ab6349")
  eye.material_override = em
  visual.add_child(eye)
  var wing := MeshInstance3D.new()
  var wm := SphereMesh.new()
  wm.radius = 0.5
  wm.height = 1
  wing.mesh = wm
  wing.scale = Vector3(0.22,0.016,0.5)
  wing.position = Vector3(side*0.22,0.08,0.03)
  wing.rotation.y = side*-0.45
  var glass := StandardMaterial3D.new()
  glass.albedo_color = Color(0.7,0.88,0.82,0.65)
  glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
  glass.cull_mode = BaseMaterial3D.CULL_DISABLED
  wing.material_override = glass
  visual.add_child(wing)
  if side == -1: wing_l = wing
  else: wing_r = wing
  for i in range(3):
   var leg := MeshInstance3D.new()
   var lm := CylinderMesh.new()
   lm.top_radius = 0.012
   lm.bottom_radius = 0.012
   lm.height = 0.25
   leg.mesh = lm
   leg.position = Vector3(side*0.13,-0.1,float(i)*0.13-0.12)
   leg.rotation.z = side*0.65
   leg.material_override = shell
   visual.add_child(leg)
 camera = Camera3D.new()
 add_child(camera)
 camera.top_level = true
 camera.near = 0.05
 camera.far = 8000
 camera.fov = 65
 camera.current = true
 inspect_eye_shape.radius = 0.15
 flight_eye_shape.radius = FLIGHT_EYE_RADIUS
 flight_eye_query.shape = flight_eye_shape
 flight_eye_query.collision_mask = 1
 flight_eye_query.margin = 0.002
 position = safe_position

func _input(event: InputEvent) -> void:
 # Mouse look must run before GUI controls can consume motion events.
 # Menus disable `active`; inspection still requires captured right-drag.
 if not active: return
 if event is InputEventKey and event.pressed and not event.echo and not inspection:
  if event.physical_keycode == KEY_SPACE or event.keycode == KEY_SPACE:
   press_space()
  elif precision_toggle and not landed and not jumping and (event.physical_keycode == KEY_SHIFT or event.keycode == KEY_SHIFT):
   precision_latched = not precision_latched
 if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
  if inspection:
   inspect_yaw -= event.relative.x*sensitivity
   inspect_pitch = clamp(inspect_pitch+event.relative.y*sensitivity,0.25,1.35)
  else:
   yaw -= event.relative.x*sensitivity
   pitch = clamp(pitch-event.relative.y*sensitivity,-1.25,1.25)
 if event is InputEventMouseButton and event.pressed:
  var factor := 0.85 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.18
  if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   if inspection: inspect_distance = clamp(inspect_distance*factor,3.0,inspect_max_distance)
   else: distance = clamp(distance*factor,2.5,170)

func _physics_process(delta: float) -> void:
 if restore_pending:
  restore_pending = false
  resolve_restored_position()
 clock += delta
 if active and not inspection:
  space_tap_remaining = maxf(0.0, space_tap_remaining - delta)
  precision = not landed and not jumping and (precision_latched if precision_toggle else Input.is_key_pressed(KEY_SHIFT))
  var move := Vector3.ZERO
  if Input.is_physical_key_pressed(KEY_W): move.z -= 1
  if Input.is_physical_key_pressed(KEY_S): move.z += 1
  if Input.is_physical_key_pressed(KEY_A): move.x -= 1
  if Input.is_physical_key_pressed(KEY_D): move.x += 1
  if not landed and not jumping:
   if Input.is_physical_key_pressed(KEY_SPACE): move.y += 1
   if Input.is_physical_key_pressed(KEY_CTRL): move.y -= 1
  move = move.rotated(Vector3.UP,yaw).normalized()
  if jumping:
   velocity.x = move.x * 5.0
   velocity.z = move.z * 5.0
   velocity.y -= JUMP_GRAVITY * delta
  elif landed:
   velocity = move*5.0
   velocity.y = -3
  else:
   velocity = velocity.lerp(move*(11.0 if precision else 165.0),1-exp(-delta*8))
  move_and_slide()
  if jumping and is_on_floor() and velocity.y <= 0.0:
   jumping = false
   landed = true
   velocity = Vector3.ZERO
  elif landed and not is_on_floor():
   # Walking off a surface falls naturally and lands on the next one.
   landed = false
   jumping = true
  if position.y < 0 or abs(position.x)>516 or position.z < 0 or position.z > 2480:
   position = safe_position
   reset_movement()
  if position.y > 2 and position.y < 285: safe_position = position
  visual.rotation.y = yaw
  visual.position.y = 0 if landed or jumping else sin(clock*12)*0.025
  wing_l.rotation.z = 0.1 if landed or jumping else sin(clock*180)*0.7
  wing_r.rotation.z = -wing_l.rotation.z
 update_camera(delta)

func set_precision_toggle(enabled: bool) -> void:
 if precision_toggle == enabled: return
 precision_toggle = enabled
 reset_precision()

func reset_precision() -> void:
 precision_latched = false
 precision = false

func update_camera(delta: float) -> void:
 if inspection:
  flight_boom_valid=false
  var offset := Vector3(sin(inspect_yaw)*cos(inspect_pitch),sin(inspect_pitch),cos(inspect_yaw)*cos(inspect_pitch))*inspect_distance
  place_inspection_eye(focus+offset)
 elif active:
  var forward := Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
  var target := global_position+Vector3(0,0.4,0)
  camera.position = flight_camera_boom(target,target-forward*distance+Vector3(0,distance*0.17,0),delta)
  camera.look_at(target+forward*distance*0.35,Vector3.UP)
 else:
  flight_boom_valid=false

func flight_camera_boom(from:Vector3,to:Vector3,delta:float)->Vector3:
 var allowed:=clear_camera(from,to)
 var reach:=allowed-flight_boom_anchor
 var limit:=reach.length()
 var blocked:=limit<from.distance_to(to)-0.05
 var reset:=not flight_boom_valid or not is_equal_approx(flight_boom_zoom,distance) or flight_boom_actor.distance_to(global_position)>25.0
 if reset or not flight_boom_releasing or limit<=flight_boom_length:
  # Keep all intentional scroll changes and obstruction retraction immediate.
  flight_boom_length=limit
 else:
  flight_boom_length=lerpf(flight_boom_length,limit,1.0-exp(-maxf(delta,0.0)*BOOM_RELEASE_SPEED))
  if limit-flight_boom_length<0.04:flight_boom_length=limit
 flight_boom_valid=true
 flight_boom_releasing=blocked or limit-flight_boom_length>0.035
 flight_boom_zoom=distance
 flight_boom_actor=global_position
 return flight_boom_anchor+reach*(flight_boom_length/limit) if limit>0.0001 else allowed

func aim_inspection_eye(at: Vector3) -> void:
 var towards := (focus-at).normalized()
 if towards.is_zero_approx(): return
 camera.global_position = at
 camera.look_at(focus,Vector3.FORWARD if absf(towards.dot(Vector3.UP))>0.9999 else Vector3.UP)

func inspection_eye_is_clear() -> bool:
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape = inspect_eye_shape
 # The renderer moves the optical eye when framing the item beside its card.
 # Testing position alone misses an eye moved into a prop by that lens offset.
 query.transform.origin = camera.get_camera_transform().origin
 query.collision_mask = 1
 return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func place_inspection_eye(preferred: Vector3) -> void:
 var previous := camera.global_transform
 aim_inspection_eye(preferred)
 if inspection_eye_is_clear():
  inspect_clear_pose = camera.global_transform
  inspect_clear_pose_valid = true
  return
 # A blocked view request must not put the lens within solid furniture. Do
 # not treat the object along the focus ray as a blocker: it may be the item
 # under inspection, and free orbit around it is still useful.
 if inspect_clear_pose_valid:
  camera.global_transform = inspect_clear_pose
  if inspection_eye_is_clear(): return
  inspect_clear_pose_valid = false
 # A newly inspected object may not have a prior orbit. Try the player's
 # actual approach before nearby alternatives, never changing the fly pose.
 for near in [global_position+Vector3(0,0.4,0),focus+(preferred-focus)*0.65,focus+(preferred-focus).rotated(Vector3.UP,0.5),focus+(preferred-focus).rotated(Vector3.UP,-0.5)]:
  aim_inspection_eye(near)
  if inspection_eye_is_clear():
   inspect_clear_pose = camera.global_transform
   inspect_clear_pose_valid = true
   return
 camera.global_transform = previous

func clear_camera(from: Vector3, to: Vector3) -> Vector3:
 # The active camera has a near plane, not a zero-width eye. A thin rail
 # can clip the view without ever touching the old center ray. In a small
 # gap the elevated orbit point can also begin inside overhead furniture.
 var space:=get_world_3d().direct_space_state
 var anchor:=from
 flight_eye_query.motion=Vector3.ZERO
 if not flight_eye_clear(space,anchor):
  # This point uses the fly body's smaller actual free space. Retain the
  # requested boom direction and zoom rather than moving the player.
  anchor=global_position
  if not flight_eye_clear(space,anchor):
   flight_boom_anchor=anchor
   return anchor
 flight_boom_anchor=anchor
 var travel:=to-from
 var total:=travel.length()
 if total<=FLIGHT_EYE_PAD:return anchor
 flight_eye_query.motion=travel
 var swept:=space.cast_motion(flight_eye_query)
 flight_eye_query.motion=Vector3.ZERO
 var safe:=clampf(swept[0],0.0,1.0)
 if safe<1.0: safe=maxf(0.0,safe-FLIGHT_EYE_PAD/total)
 var proposed:=anchor+travel*safe
 # An endpoint overlap can still happen at the bevel of a concave prop.
 # Retract rather than keep a clipped position or move to a stale room.
 if not flight_eye_clear(space,proposed):
  proposed=anchor+travel*safe*0.72
  if not flight_eye_clear(space,proposed):return anchor
 return proposed

func flight_eye_clear(space:PhysicsDirectSpaceState3D, point:Vector3)->bool:
 flight_eye_query.transform.origin=point
 return space.intersect_shape(flight_eye_query,1).is_empty()

func position_is_clear(point: Vector3) -> bool:
 var query := PhysicsShapeQueryParameters3D.new()
 query.shape = body_collision.shape
 query.transform = Transform3D(global_basis,point)
 query.collision_mask = 1
 query.exclude = [get_rid()]
 query.margin = 0.001
 return get_world_3d().direct_space_state.intersect_shape(query,1).is_empty()

func restore_position(point: Vector3) -> void:
 global_position = point
 safe_position = point
 reset_movement()
 # Resolve after the new world's bodies have entered the physics space.
 restore_pending = true

func resolve_restored_position() -> void:
 if position_is_clear(global_position): return
 var preferred := global_position
 var directions := [Vector3.UP,Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK,
  Vector3(1,1,0).normalized(),Vector3(-1,1,0).normalized(),Vector3(0,1,1).normalized(),Vector3(0,1,-1).normalized()]
 for distance_from_save in [0.5,1.0,2.0,4.0,8.0,16.0,32.0,64.0]:
  for direction in directions:
   var candidate: Vector3 = preferred+direction*distance_from_save
   if absf(candidate.x)>=TrainLayout.HALF_WIDTH or candidate.y<=1 or candidate.y>=285 or candidate.z<=0 or candidate.z>=2480: continue
   if position_is_clear(candidate):
    global_position = candidate
    safe_position = candidate
    return
 # The existing safe-perch location is clear of the investigation props.
 global_position = Vector3(-75,88,1225)
 safe_position = global_position

func press_space() -> void:
 if space_tap_remaining > 0.0 and (jumping or landed):
  take_off()
 elif landed:
  landed = false
  jumping = true
  space_tap_remaining = DOUBLE_TAP_WINDOW
  velocity.y = JUMP_SPEED

func take_off() -> void:
 landed = false
 jumping = false
 space_tap_remaining = 0.0
 # Sweep the body upward; taking off under a thin shelf must not teleport through.
 move_and_collide(Vector3.UP*0.6)
 velocity.y = maxf(velocity.y, 12.0)

func settle_after_modal_return() -> void:
 # With no current direction input, don't resume old airborne velocity
 # as surprise movement after reading a panel or pausing.
 if landed or jumping: return
 for key in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE, KEY_CTRL]:
  if Input.is_physical_key_pressed(key): return
 velocity = Vector3.ZERO

func reset_movement() -> void:
 flight_boom_valid=false
 landed = false
 jumping = false
 space_tap_remaining = 0.0
 velocity = Vector3.ZERO

func try_land() -> bool:
 if landed:
  take_off()
  return true
 # Test the whole fly rather than a center ray, then sweep down to the surface.
 # This also prevents snapping through an obstruction beside a narrow opening.
 var landing := KinematicCollision3D.new()
 if test_move(global_transform,Vector3.DOWN*18.0,landing,safe_margin) and landing.get_normal().y > 0.8:
  move_and_collide(Vector3.DOWN*18.0)
  velocity = Vector3.ZERO
  landed = true
  jumping = false
  space_tap_remaining = 0.0
  return true
 return false

func inspect_at(point: Vector3, zoom: float = 25.0, max_zoom: float = 120.0) -> void:
 flight_boom_valid=false
 inspection = true
 focus = point
 inspect_distance = zoom
 inspect_max_distance = max_zoom
 inspect_yaw = 0.4
 inspect_pitch = 0.65
 inspect_clear_pose_valid = false
