extends Node3D
## A fictional nursery fixture built at centimetre scale. No part of the case.
const MOUNT := Vector3(-190,120,2472.5)
const INTAKE_PATH := [
 Vector3(-17,-5,-33),Vector3(-17,-5,-18),Vector3(0,-5,-18),Vector3(0,-5,-8)
]
const SPOON_TOP := Vector3(0,-5.5,-8)
const SEED_PATH := [Vector3(9,4.5,-8),Vector3(12.4,1.2,-5.6),Vector3(16,-4.05,-3)]
const TRANSFER_TIME := 1.18
const WOOD := Color("404438")
const STEEL := Color("43595a")
const BRASS := Color("b6a16e")
const GOLD := Color("e3c77e")
var spoon_body: StaticBody3D
var modifiable: Node3D
var finish: Dictionary = {}
var status: Label3D
var cradle_status: Label3D
var seed: MeshInstance3D
var rocker: Node3D
var indicator: StandardMaterial3D
var transfer: Tween
var returned := false
var visibly_ready := false

func build() -> void:
 name = "SeedLift"
 position = MOUNT
 set_meta("solid_geometry_exclude",true)
 modifiable = Node3D.new()
 modifiable.name = "SeedAndSignal"
 add_child(modifiable)
 # A shared lower floor, with the three open bands forming one two-turn route.
 panel(Vector3(0,-8.5,-14),Vector3(56,1,28),STEEL,false)
 for band in [
  [-28.0,-21.0,-20.5,-13.5],
  [-21.0,-15.0,-20.5,3.5],
  [-15.0,-10.0,-3.5,3.5]
 ]:
  baffle_fill(float(band[0]),float(band[1]),-28.0,float(band[2]))
  baffle_fill(float(band[0]),float(band[1]),float(band[3]),28.0)
 panel(Vector3(0,-1.75,-19),Vector3(56,0.5,18),STEEL,false)
 # Transparent but solid main inspection face. It never opens for the fly.
 var window := panel(Vector3(7.5,5.75,-27.5),Vector3(37,14.5,0.28),Color("758b82"),false)
 var glass := StandardMaterial3D.new()
 glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 glass.albedo_color = Color(0.58,0.78,0.70,0.19)
 glass.roughness = 0.14
 glass.cull_mode = BaseMaterial3D.CULL_DISABLED
 window.material_override = glass
 window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 panel(Vector3(-19.5,5.75,-27.5),Vector3(17,14.5,0.45),WOOD,false)
 panel(Vector3(27,5.75,-27.5),Vector3(2,14.5,0.45),WOOD,false)
 panel(Vector3(0,14,-27.5),Vector3(56,2,0.45),BRASS,true)
 panel(Vector3(0,15,-14),Vector3(56,1,28),WOOD,false)
 panel(Vector3(0,3.5,-0.4),Vector3(56,23,0.8),WOOD,false)
 for side in [-1,1]:
  panel(Vector3(side*27.65,6.5,-14),Vector3(0.7,17,28),WOOD,false)
  # Back the straps onto the fitted wall finish. Keep their front faces at
  # local z=-0.20; a small embed at the rear closes the original 1.7 mm gap.
  var wall_strap := panel(Vector3(side*22,1.5,0.92),Vector3(2,18,2.24),STEEL,false)
  wall_strap.name = "LeftWallStrap" if side<0 else "RightWallStrap"
 # Narrow polished edges mark the only entrance without filling its aperture.
 for x in [-20.75,-13.25]: trim(Vector3(x,-5,-28.18),Vector3(0.46,6.3,0.58),BRASS)
 for y in [-8.2,-1.8]: trim(Vector3(-17,y,-28.18),Vector3(7.7,0.38,0.58),BRASS)
 var pad := panel(SPOON_TOP-Vector3(0,0.4,0),Vector3(4.2,0.8,3.6),BRASS,true)
 spoon_body = pad.get_child(0) as StaticBody3D
 spoon_body.name = "BalanceSpoon"
 trim(Vector3(0,-7.0,-7.6),Vector3(1.3,2.0,1.4),STEEL)
 trim(Vector3(16,-5.3,-3),Vector3(5.3,1.6,3.8),STEEL)
 for x in [13.55,18.45]: trim(Vector3(x,-4.45,-3),Vector3(0.28,0.6,3.8),BRASS)
 for z in [-4.8,-1.2]: trim(Vector3(16,-4.45,z),Vector3(5.3,0.6,0.28),BRASS)
 trim(Vector3(4,14.3,-28.30),Vector3(19.6,2.8,0.22),WOOD)
 text_at("SEED LIFT",Vector3(4,14.3,-28.52),0.067,GOLD)
 text_at("INTAKE",Vector3(-17,1.8,-28),0.043,GOLD)
 text_at("BALANCE SPOON",Vector3(0,-3.8,-5.6),0.015,GOLD)
 text_at("TIDE IRIS  /  ONE SEED FOR THE SHORE",Vector3(7,10.3,-20.6),0.031,GOLD)
 status = text_at("RETURN PENDING",Vector3(10,1,-28),0.047,GOLD,modifiable)
 cradle_status = text_at("EMPTY",Vector3(14.15,-2.5,-3),0.021,GOLD,modifiable)
 cradle_status.rotation.y = -PI/2
 build_path_markings()
 build_seed_path()
 set_returned(false)

func build_path_markings() -> void:
 # A continuous painted guide is flush with the floor. These are colours,
 # not colliders or new projected lights in the little flight channel.
 var inlay := StandardMaterial3D.new()
 inlay.albedo_color = Color("ac925d")
 inlay.roughness = 0.63
 inlay.emission_enabled = true
 inlay.emission = Color("b99b59")
 inlay.emission_energy_multiplier = 0.18
 var strips := [
  [Vector3(-17,-7.975,-23.0),Vector3(0.34,0.018,9.66)],
  [Vector3(-8.5,-7.975,-18),Vector3(17.34,0.018,0.34)],
  [Vector3(0,-7.975,-13.86),Vector3(0.34,0.018,7.94)]
 ]
 for strip in strips:
  var painted := trim(strip[0],strip[1],BRASS)
  painted.material_override = inlay
  painted.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 text_at("←",Vector3(-17,-4.2,-15.18),0.056,GOLD)
 var second := text_at("→",Vector3(3.32,-4.2,-18),0.056,GOLD)
 second.rotation.y = -PI/2

func build_seed_path() -> void:
 for i in range(SEED_PATH.size()-1):
  transparent_tube(SEED_PATH[i],SEED_PATH[i+1])
 for point in SEED_PATH:
  trim(point+Vector3(0,-0.95,0),Vector3(2.6,0.3,1.4),BRASS)
 rocker = Node3D.new()
 modifiable.add_child(rocker)
 rocker.position = SEED_PATH[0]
 trim(Vector3(-1.2,-0.6,0),Vector3(2.8,0.35,0.6),BRASS,rocker)
 seed = MeshInstance3D.new()
 var seed_shape := SphereMesh.new()
 seed_shape.radius = 1.0
 seed_shape.height = 2.0
 seed_shape.radial_segments = 24
 seed_shape.rings = 12
 seed.mesh = seed_shape
 seed.scale = Vector3(0.52,0.45,0.69)
 seed.rotation_degrees = Vector3(12,25,20)
 seed.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 var seed_finish := StandardMaterial3D.new()
 seed_finish.albedo_color = Color("dba352")
 seed_finish.roughness = 0.37
 seed_finish.emission_enabled = true
 seed_finish.emission = Color("cf7c31")
 seed_finish.emission_energy_multiplier = 0.31
 seed.material_override = seed_finish
 modifiable.add_child(seed)
 var lens := trim(Vector3(20.6,1,-27.82),Vector3(1.6,1.6,0.26),BRASS,modifiable)
 indicator = StandardMaterial3D.new()
 indicator.emission_enabled = true
 indicator.roughness = 0.34
 lens.material_override = indicator

func transparent_tube(from: Vector3, to: Vector3) -> void:
 var cylinder := CylinderMesh.new()
 cylinder.top_radius = 1.15
 cylinder.bottom_radius = 1.15
 cylinder.height = from.distance_to(to)
 cylinder.radial_segments = 24
 cylinder.cap_top = false
 cylinder.cap_bottom = false
 var tint := StandardMaterial3D.new()
 tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
 tint.albedo_color = Color(0.6,0.82,0.76,0.24)
 tint.cull_mode = BaseMaterial3D.CULL_DISABLED
 tint.roughness = 0.12
 var pipe := MeshInstance3D.new()
 pipe.mesh = cylinder
 pipe.material_override = tint
 pipe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(pipe)
 pipe.position = (from+to)*0.5
 pipe.quaternion = Quaternion(Vector3.UP,(to-from).normalized())

func supports_landing(eye: Vector3, space: PhysicsDirectSpaceState3D) -> bool:
 var local := to_local(eye)-SPOON_TOP
 if absf(local.x)>2.3 or absf(local.z)>2.0 or local.y<0.0 or local.y>0.45: return false
 var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(eye,eye+Vector3.DOWN*0.45,1))
 return not hit.is_empty() and hit.collider==spoon_body and hit.normal.y>0.8

func show_landing_hint(eye: Vector3) -> bool:
 if returned or absf(eye.z-global_position.z)>12.0: return false
 var local := to_local(eye)-SPOON_TOP
 return absf(local.x)<1.8 and absf(local.z)<1.5 and local.y>=0.0 and local.y<=3.3

func signal_state(words: String, color: Color, energy: float) -> void:
 status.text = words
 status.modulate = color
 indicator.albedo_color = color
 indicator.emission = color
 indicator.emission_energy_multiplier = energy
 cradle_status.text = "IRIS READY" if visibly_ready else "EMPTY"
 cradle_status.modulate = color

func place_seed(part: float) -> void:
 var span := clampf(part,0.0,1.0)*2.0
 seed.position = SEED_PATH[0].lerp(SEED_PATH[1],span) if span<=1.0 else SEED_PATH[1].lerp(SEED_PATH[2],span-1.0)
 seed.rotation.z = deg_to_rad(20.0)+TAU*part
 rocker.rotation.z = -0.47*sin(part*PI)

func set_returned(completed: bool) -> void:
 if transfer!=null and transfer.is_valid(): transfer.kill()
 transfer = null
 returned = completed
 visibly_ready = completed
 place_seed(1.0 if completed else 0.0)
 signal_state("RETURN READY" if completed else "RETURN PENDING",Color("a6dbad") if completed else GOLD,0.72 if completed else 0.24)

func begin_return() -> void:
 if returned: return
 returned = true
 signal_state("RETURNING",GOLD,0.48)
 transfer = create_tween()
 transfer.tween_method(place_seed,0.0,1.0,TRANSFER_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
 transfer.tween_callback(finish_return)

func finish_return() -> void:
 visibly_ready = true
 place_seed(1)
 signal_state("RETURN READY",Color("a6dbad"),0.72)

func baffle_fill(z0: float, z1: float, x0: float, x1: float) -> void:
 panel(Vector3((x0+x1)*0.5,-5,(z0+z1)*0.5),Vector3(x1-x0,6,z1-z0),STEEL,false)

func material(color: Color, metal: bool) -> StandardMaterial3D:
 var key := str(color)+str(metal)
 if not finish.has(key):
  var mat := StandardMaterial3D.new()
  mat.albedo_color = color
  mat.roughness = 0.34 if metal else 0.64
  mat.metallic = 0.68 if metal else 0.0
  finish[key] = mat
 return finish[key]

func trim(point: Vector3, size: Vector3, color: Color, parent: Node3D = self) -> MeshInstance3D:
 var visual := MeshInstance3D.new()
 var mesh := BoxMesh.new()
 mesh.size = size
 visual.mesh = mesh
 visual.material_override = material(color,true)
 parent.add_child(visual)
 visual.position = point
 return visual

func panel(point: Vector3, size: Vector3, color: Color, metal: bool) -> MeshInstance3D:
 var visual := trim(point,size,color)
 visual.material_override = material(color,metal)
 var body := StaticBody3D.new()
 var collision := CollisionShape3D.new()
 var shape := BoxShape3D.new()
 shape.size = size
 collision.shape = shape
 visual.add_child(body)
 body.add_child(collision)
 return visual

func text_at(words: String, point: Vector3, pixel: float, color: Color, parent: Node3D = self) -> Label3D:
 var sign_label := Label3D.new()
 sign_label.font = preload("res://assets/Interface.ttf")
 sign_label.font_size = 32
 sign_label.pixel_size = pixel
 sign_label.text = words
 sign_label.modulate = color
 sign_label.outline_size = 1
 sign_label.rotation.y = PI
 parent.add_child(sign_label)
 sign_label.position = point
 return sign_label
