extends Node3D
## Mounted Nocturne wayfinding and Deco panelling; decoration has no collisions.
const GOLD := Color("c6a46c")
const CREAM := Color("e0d3b7")
const MUTED := Color("8a9d95")
const FONT = preload("res://assets/Interface.ttf")
var batches: Dictionary = {}
var surfaces: Dictionary = {}

func build() -> void:
 var brass := StandardMaterial3D.new()
 brass.albedo_color = GOLD
 brass.metallic = 0.7
 brass.roughness = 0.28
 surfaces["brass"] = brass
 var enamel := StandardMaterial3D.new()
 enamel.albedo_color = Color("142d2c")
 enamel.roughness = 0.33
 surfaces["enamel"] = enamel
 var inset := StandardMaterial3D.new()
 inset.albedo_color = Color("29433d")
 inset.roughness = 0.6
 surfaces["inset"] = inset
 var names := ["THE RESIDENCES", "THE NIGHT LOUNGE", "THE WINTER GARDEN"]
 var services := ["RESIDENT LOUNGE", "DINING & HOSPITALITY", "LIVING COLLECTION"]
 var courtesies := ["PLEASE KEEP VOICES LOW", "TABLE SERVICE ABOARD", "PLEASE DO NOT PICK"]
 for car in range(3):
  for end in [0,1]:
   var z := float(car)*840.0+(6.0 if end == 0 else 794.0)
   var basis := Basis(Vector3.UP,0.0 if end == 0 else PI)
   for side in [-1,1]:
    var mount := Transform3D(basis,Vector3(side*112,193,z))
    if side == -1:
     route_board(mount,car+6)
    else:
     identity_board(mount,car+6,services[car],courtesies[car])
    # Recessed rectangular lower panelling, entirely inside solid end walls.
    for bay in range(3):
     var local_x: float = side*(74+bay*37)
     var panel := Transform3D(basis,Vector3(local_x,52,z))
     rectangle(panel,Vector2(29,67),0.55)
     var diamond := Transform3D(basis*Basis(Vector3.FORWARD,PI*0.25),Vector3(local_x,53,z+basis.z.z*0.2))
     piece(diamond,Vector3.ZERO,Vector3(2.8,2.8,0.35),"brass")
   # A mounted carriage-number plate over each portal, clear of the doorway.
   var header := Transform3D(basis,Vector3(0,248,z))
   board(header,Vector2(132,26))
   text(header,"%02d  /  %s" % [car+6,names[car]],Vector3(0,0,0.9),0.108,GOLD)
   # Symmetric stepped Deco caps, leaving all door and aisle geometry untouched.
   for side in [-1,1]:
    for step in range(3):
     piece(header,Vector3(side*(69+step*3),0,0),Vector3(1.0,20-step*4,0.6),"brass")
 for key in batches:
  var transforms: Array = batches[key]
  var mesh := BoxMesh.new()
  mesh.size = Vector3.ONE
  var multi := MultiMesh.new()
  multi.transform_format = MultiMesh.TRANSFORM_3D
  multi.mesh = mesh
  multi.instance_count = transforms.size()
  for i in range(transforms.size()): multi.set_instance_transform(i,transforms[i])
  var instance := MultiMeshInstance3D.new()
  instance.name = "NocturneFixtures_"+key
  instance.multimesh = multi
  instance.material_override = surfaces[key]
  instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  add_child(instance)

func piece(mount: Transform3D, p: Vector3, size: Vector3, finish: String) -> void:
 if not batches.has(finish): batches[finish] = []
 batches[finish].append(mount*Transform3D(Basis.from_scale(size),p))

func rectangle(mount: Transform3D, size: Vector2, thickness: float = 0.65) -> void:
 for side in [-1,1]:
  piece(mount,Vector3(side*size.x*0.5,0,0.25),Vector3(thickness,size.y,0.5),"brass")
  piece(mount,Vector3(0,side*size.y*0.5,0.25),Vector3(size.x,thickness,0.5),"brass")

func board(mount: Transform3D, size: Vector2) -> void:
 piece(mount,Vector3(0,0,-0.05),Vector3(size.x+2.4,size.y+2.4,0.8),"brass")
 piece(mount,Vector3(0,0,0.45),Vector3(size.x,size.y,0.45),"enamel")
 # Second thin border is cut into the enamel, rather than floating typography.
 rectangle(mount*Transform3D(Basis.IDENTITY,Vector3(0,0,0.5)),size-Vector2(4,4),0.28)

func text(mount: Transform3D, content: String, p: Vector3, pixel: float, tint: Color = CREAM) -> void:
 var label := Label3D.new()
 label.font = FONT
 label.font_size = 48
 label.pixel_size = pixel
 label.text = content
 label.modulate = tint
 label.outline_size = 0
 label.double_sided = false
 label.no_depth_test = false
 label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
 add_child(label)
 label.transform = mount*Transform3D(Basis.IDENTITY,p)

func route_board(mount: Transform3D, current: int) -> void:
 board(mount,Vector2(91,82))
 text(mount,"NOCTURNE",Vector3(0,29,0.95),0.155,GOLD)
 text(mount,"TWELVE CARRIAGES · ONE HOME",Vector3(0,19,0.95),0.067)
 piece(mount,Vector3(0,10,0.9),Vector3(76,0.35,0.2),"brass")
 # Twelve numbered carriages; only the existing investigation area is named.
 for i in range(12):
  var x := -36.3+float(i)*6.6
  var active := i+1 == current
  var accessible := i+1 in [6,7,8]
  var marker := Vector3(3.0,3.0,0.35) if active else Vector3(1.5,1.5,0.3)
  piece(mount,Vector3(x,2,0.9),marker,"brass" if accessible else "inset")
  text(mount,"%02d" % [i+1],Vector3(x,7.0,1.0),0.043,GOLD if accessible else MUTED)
 text(mount,"YOU ARE IN CARRIAGE  %02d" % current,Vector3(0,-6,0.95),0.075,GOLD)
 text(mount,"06   RESIDENCES",Vector3(0,-16,0.95),0.084)
 text(mount,"07   DINING LOUNGE",Vector3(0,-24,0.95),0.084)
 text(mount,"08   WINTER GARDEN",Vector3(0,-32,0.95),0.084)

func identity_board(mount: Transform3D, carriage: int, service: String, courtesy: String) -> void:
 board(mount,Vector2(91,82))
 text(mount,"N / N",Vector3(0,19,0.95),0.40,GOLD)
 text(mount,"THE NOCTURNE",Vector3(0,-1,0.95),0.12)
 for side in [-1,1]:
  piece(mount,Vector3(side*22,-12,0.9),Vector3(23,0.35,0.25),"brass")
 var diamond := mount*Transform3D(Basis(Vector3.FORWARD,PI*0.25),Vector3(0,-12,0.95))
 piece(diamond,Vector3.ZERO,Vector3(2.5,2.5,0.25),"brass")
 text(mount,"%02d  ·  %s" % [carriage,service],Vector3(0,-22,0.95),0.078,GOLD)
 text(mount,courtesy,Vector3(0,-32,0.95),0.065)
