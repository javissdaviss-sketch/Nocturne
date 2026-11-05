extends RefCounted
## Shared physical finishes derived from the four Agatha reference boards.
## Atlas order, physical repeat, response and provenance: assets/textures/MATERIALS.md.
const ATLAS = preload("res://assets/textures/cyber_luxe_material_atlas.png")
const SHADER = preload("res://shaders/crafted_surfaces.gdshader")
enum Finish {MAHOGANY,WALNUT,BRASS,STEEL,VELVET,LEATHER,LINEN,DAMASK,RUG,PLASTER,CERAMIC,MARBLE,TERRACOTTA,PAPER,LEAF,SKIN}
const MEANS = [0.0574,0.0403,0.2406,0.2785,0.0128,0.0767,0.5311,0.0766,0.1089,0.5911,0.6813,0.5157,0.1998,0.6424,0.1303,0.3769]
const SCALES = [Vector2(48,140),Vector2(48,140),Vector2(24,24),Vector2(18,18),Vector2(5,5),Vector2(6,6),Vector2(2.8,2.8),Vector2(58,58),Vector2(90,90),Vector2(26,26),Vector2(8,8),Vector2(90,90),Vector2(6,6),Vector2(4,4),Vector2(3,3),Vector2(2.5,2.5)]
const ROUGHNESS = [0.38,0.43,0.35,0.39,0.89,0.54,0.91,0.78,0.95,0.89,0.23,0.30,0.86,0.93,0.64,0.66]
const RELIEF = [0.014,0.014,0.003,0.002,0.0008,0.009,0.0015,0.012,0.018,0.008,0.001,0.003,0.008,0.002,0.004,0.001]
static var cache: Dictionary = {}

static func make(kind: int, color: Color, floorboards: bool = false, border: bool = false, painted: bool = false) -> ShaderMaterial:
 var key := str(kind)+str(color)+str(floorboards)+str(border)+str(painted)
 if cache.has(key): return cache[key]
 var material := ShaderMaterial.new()
 material.shader = SHADER
 material.resource_name = Finish.keys()[kind].capitalize()+" / reference finish"
 material.set_meta("crafted_finish",kind)
 material.set_shader_parameter("material_atlas",ATLAS)
 material.set_shader_parameter("surface_kind",kind)
 material.set_shader_parameter("tint",color)
 material.set_shader_parameter("tile_cm",SCALES[kind])
 material.set_shader_parameter("mean_luminance",MEANS[kind])
 material.set_shader_parameter("base_roughness",0.61 if painted else ROUGHNESS[kind])
 material.set_shader_parameter("relief_cm",RELIEF[kind])
 material.set_shader_parameter("metalness",0.82 if not painted and kind in [Finish.BRASS,Finish.STEEL] else 0.0)
 material.set_shader_parameter("varnish",0.30 if kind in [Finish.MAHOGANY,Finish.WALNUT,Finish.CERAMIC] else 0.0)
 material.set_shader_parameter("floor_planks",floorboards)
 material.set_shader_parameter("carpet_border",border)
 cache[key] = material
 return material

static func cabin(kind: int, color: Color) -> ShaderMaterial:
 match kind:
  0: return make(Finish.MAHOGANY,color,true)
  1: return make(Finish.VELVET,color)
  2: return make(Finish.WALNUT,color)
  3: return make(Finish.DAMASK,color)
  4: return make(Finish.PLASTER,color)
  _: return make(Finish.MAHOGANY,Color("77503a"))

static func prop(kind: int, color: Color) -> ShaderMaterial:
 return make([Finish.LEATHER,Finish.PAPER,Finish.LINEN,Finish.MAHOGANY,Finish.TERRACOTTA][clampi(kind,0,4)],color)

static func classify(material: StandardMaterial3D, context: String) -> int:
 var color := material.albedo_color
 if color in [Color("bda374"),Color("b6925e"),Color("c6a46c"),Color("88734d"),Color("bca172"),Color("b5a077")]: return Finish.BRASS
 if material.metallic>0.3:
  return Finish.BRASS if color.r>color.b*1.12 else Finish.STEEL
 if context.contains("tailoredresident") or context.contains("/resident"):
  if color.is_equal_approx(Color("b99377")) or (color.r>color.g*1.12 and color.g>color.b*1.10 and color.get_luminance()>0.15): return Finish.SKIN
  if color.r>color.g*1.08 and color.get_luminance()<0.15: return Finish.LEATHER
  return Finish.LINEN
 if context.contains("pot") or context.contains("palm") or context.contains("livingcollection"):
  if color.g>color.r*1.15: return Finish.LEAF
  if color.r>color.g*1.2: return Finish.TERRACOTTA
 if context.contains("luggage") or context.contains("trunk") or context.contains("bag") or (context.contains("book") and not context.contains("bookcase")):
  return Finish.LEATHER
 if context.contains("paper") or context.contains("note") or context.contains("document") or context.contains("tag"):
  return Finish.PAPER
 if color.r>0.65 and color.g>0.60 and color.b>0.45:
  return Finish.CERAMIC
 if color.r>color.g*1.10 and color.g>color.b*1.10:
  return Finish.WALNUT
 return Finish.STEEL # coated metal retains its authored paint color

static func apply(root: Node, exclusions: Array[Node] = []) -> Dictionary:
 var coverage: Dictionary = {}
 _visit(root,"",exclusions,coverage)
 return coverage

static func _visit(node: Node, context: String, exclusions: Array[Node], coverage: Dictionary) -> void:
 if node in exclusions: return
 context += "/"+str(node.name).to_lower()
 if node is MeshInstance3D or node is MultiMeshInstance3D:
  var original: Material = node.material_override
  if original is StandardMaterial3D:
   # Preserve authored leaf photos, clue deposits, transparent glass, liquid,
   # light emitters and vertex-color data. Never texture labels or scenery.
   if original.albedo_texture == null and not original.vertex_color_use_as_albedo and not original.emission_enabled and original.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not context.contains("teasurface") and not (context.contains("eyeoptics") and original.roughness<0.4):
    var kind := classify(original,context)
    node.material_override = make(kind,original.albedo_color,false,false,kind == Finish.STEEL and original.metallic<=0.3)
  elif original is ShaderMaterial and not original.has_meta("crafted_finish"):
   var path: String = original.shader.resource_path
   if path.ends_with("prop_surfaces.gdshader"):
    var kind: int = original.get_shader_parameter("finish")
    if kind != 4: node.material_override = prop(kind,original.get_shader_parameter("color"))
   elif path.ends_with("cabin_surfaces.gdshader"):
    node.material_override = cabin(original.get_shader_parameter("finish"),original.get_shader_parameter("finish_color"))
  var current: Material = node.material_override
  if current != null and current.has_meta("crafted_finish"):
   var finish: int = current.get_meta("crafted_finish")
   coverage[finish] = int(coverage.get(finish,0))+1
 for child in node.get_children(): _visit(child,context,exclusions,coverage)
