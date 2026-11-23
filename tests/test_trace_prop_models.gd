extends SceneTree
const Hero = preload("res://scripts/hero_assets.gd")
const World = preload("res://scripts/world.gd")
var failures: Array[String] = []

func _initialize() -> void: call_deferred("run")
func check(value: bool, context: String) -> void:
 if not value: failures.append(context)

func trace_vertices(mesh: MeshInstance3D) -> PackedVector3Array:
 return mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func run() -> void:
 # Reuse actual prop construction methods without booting the 3-car world.
 var builder := World.new()
 var parent := Node3D.new()
 root.add_child(parent)
 var cup := Hero.evidence_cup(builder,parent,Vector3(-88,78,1250))
 var bottle_origin := Vector3(121,36.5,1460)
 Hero.chemical_bottle(builder,parent,bottle_origin)
 var bottle := parent.get_node("EvidenceBottleGlass") as MeshInstance3D
 var film := parent.get_node("BottleVioletFilm") as MeshInstance3D
 var shards := parent.get_node("BottleAngularVioletCrystals") as MeshInstance3D
 var cup_film := cup.get_node("AdheredVioletDeposit") as MeshInstance3D
 var cup_shards := cup.get_node("AngularVioletCrystals") as MeshInstance3D
 check(bottle.position==bottle_origin and film.position==bottle_origin and shards.position==bottle_origin,"The deposits actually share the bottle's original transform")
 check(cup_film.material_override.albedo_color==film.material_override.albedo_color and cup_shards.material_override.albedo_color==shards.material_override.albedo_color,"Both places use the same visible violet palette")
 var vertices := trace_vertices(film)
 var tips := trace_vertices(shards)
 check(vertices.size()>100 and tips.size()>50,"Real continuous surface and faceted mesh, not an illustration or label")
 var low := INF
 var high := -INF
 for point in vertices:
  var difference := Vector2(point.x,point.z).length()-Hero.bottle_radius(point.y)
  low = minf(low,difference)
  high = maxf(high,difference)
  check(point.y>12.6 and point.y<13.42 and point.z<-1.3,"Trace stays on the −Z outer neck, below the sealing ring")
 check(low>=0.011 and high<=0.038,"The film conforms to the true neck, less than 0.04cm above it")
 var high_tip := 0.0
 for point in tips: high_tip=maxf(high_tip,Vector2(point.x,point.z).length()-Hero.bottle_radius(point.y))
 check(high_tip>0.10 and high_tip<0.25,"The facets cast a real geometric profile without gross protrusions")
 check(film.get_meta("solid_geometry_exclude",false) and shards.get_meta("solid_geometry_exclude",false),"Tiny decorative traces do not alter original flight or bottle collision")
 var engraving := ""
 for child in parent.get_children():
  if child is Label3D and absf(child.position.y-(bottle_origin.y+5.3))<0.002:
   engraving += child.text
 check(engraving=="BATCH 206","The actual rendered bottle label is independent of orchid shipment serial")
 builder.free()
 parent.queue_free()
 await process_frame
 if failures.is_empty(): print("PASS: real matching violet geometry and neck contact, unchanged anchors, actual BATCH 206 glyphs")
 else: printerr(failures)
 quit(0 if failures.is_empty() else 1)
