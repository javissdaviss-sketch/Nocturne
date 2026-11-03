extends CharacterBody3D
var yaw := 0.0
var pitch := -0.12
var distance := 14.0
var sensitivity := 0.0025
var landed := false
var active := false
var precision := false
var camera: Camera3D
var visual: Node3D
var wing_l: MeshInstance3D
var wing_r: MeshInstance3D
var safe_position := Vector3(-75,88,1225)
var clock := 0.0
var inspection := false
var focus := Vector3.ZERO
var inspect_distance := 25.0
var inspect_yaw := 0.5
var inspect_pitch := 0.55

func _ready() -> void:
 collision_layer = 2
 collision_mask = 1
 floor_snap_length = 0.15
 safe_margin = 0.015
 var shape := CollisionShape3D.new()
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
 position = safe_position

func _input(event: InputEvent) -> void:
 # Mouse look must run before GUI controls can consume motion events.
 # Menus disable `active`; inspection still requires captured right-drag.
 if not active: return
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
   if inspection: inspect_distance = clamp(inspect_distance*factor,3,120)
   else: distance = clamp(distance*factor,2.5,170)

func _physics_process(delta: float) -> void:
 clock += delta
 if active and not inspection:
  precision = Input.is_key_pressed(KEY_SHIFT)
  var move := Vector3.ZERO
  if Input.is_physical_key_pressed(KEY_W): move.z -= 1
  if Input.is_physical_key_pressed(KEY_S): move.z += 1
  if Input.is_physical_key_pressed(KEY_A): move.x -= 1
  if Input.is_physical_key_pressed(KEY_D): move.x += 1
  if Input.is_physical_key_pressed(KEY_SPACE):
   move.y += 1
   landed = false
  if Input.is_physical_key_pressed(KEY_CTRL): move.y -= 1
  move = move.rotated(Vector3.UP,yaw).normalized()
  if landed:
   velocity = move*5.0
   velocity.y = -3
  else:
   velocity = velocity.lerp(move*(11.0 if precision else 165.0),1-exp(-delta*8))
  move_and_slide()
  if position.y < 0 or abs(position.x)>176 or position.z < 0 or position.z > 2480:
   position = safe_position
   velocity = Vector3.ZERO
  if position.y > 2 and position.y < 285: safe_position = position
  visual.rotation.y = yaw
  visual.position.y = 0 if landed else sin(clock*12)*0.025
  wing_l.rotation.z = 0.1 if landed else sin(clock*180)*0.7
  wing_r.rotation.z = -wing_l.rotation.z
 update_camera(delta)

func update_camera(_delta: float) -> void:
 if inspection:
  var offset := Vector3(sin(inspect_yaw)*cos(inspect_pitch),sin(inspect_pitch),cos(inspect_yaw)*cos(inspect_pitch))*inspect_distance
  camera.position = focus+offset
  camera.look_at(focus,Vector3.UP)
 elif active:
  var forward := Vector3(-sin(yaw)*cos(pitch),sin(pitch),-cos(yaw)*cos(pitch))
  var target := global_position+Vector3(0,0.4,0)
  camera.position = clear_camera(target,target-forward*distance+Vector3(0,distance*0.17,0))
  camera.look_at(target+forward*distance*0.35,Vector3.UP)

func clear_camera(from: Vector3, to: Vector3) -> Vector3:
 var query := PhysicsRayQueryParameters3D.create(from,to,1)
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 if hit: return hit.position+hit.normal*0.2
 return to

func try_land() -> bool:
 if landed:
  landed = false
  position.y += 0.6
  return true
 var query := PhysicsRayQueryParameters3D.create(position,position-Vector3(0,18,0),1)
 var hit := get_world_3d().direct_space_state.intersect_ray(query)
 if hit and hit.normal.y > 0.8:
  position = hit.position+Vector3(0,0.19,0)
  velocity = Vector3.ZERO
  landed = true
  return true
 return false

func inspect_at(point: Vector3, zoom: float = 25.0) -> void:
 inspection = true
 focus = point
 inspect_distance = zoom
 inspect_yaw = 0.4
 inspect_pitch = 0.65
