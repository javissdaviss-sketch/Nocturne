# Nocturne model library

These are standalone Godot PackedScenes with embedded modeled geometry and materials. Open a `.scn` in Godot 4.6.3 to inspect, place or reuse it. Coordinates are centimetres. Their meshes include physical collision; real handles, vessel interiors and furniture openings remain open. No runtime download is required.

The game uses the corresponding reusable builders so room dimensions and clue positions remain authored in code. Re-export a scene after changing its builder. Shared external shaders remain live; changed texture parameters require re-exporting.

| Collection | Models | Builder / exporter |
| --- | --- | --- |
| Furniture | Walnut table, parlour chair, chaise | `furniture_models.gd`, `world.gd`; `tests/export_furniture_models.gd` |
| Sleeping | Meridian sleeper bed, marquetry bedside cabinet | `sleeping_assets.gd`; `tests/export_sleeping_models.gd` |
| Cabinetry | Cyber-luxe wardrobe, service counter, framed service door | `cabinet_assets.gd`; `tests/export_cabinet_models.gd` |
| Investigation | Evidence cup with adhered crystalline residue, maintenance terminal, V9 reagent bottle, dispatch case and ledger, data slate, covered scene | `hero_assets.gd`; `tests/export_hero_models.gd` |
| Travel and hospitality | Leather trunk, radio, tea service, travel chess, bound books, folded linen | `lived_in_details.gd`, `residential_props.gd`, `hospitality_props.gd`; `tests/export_prop_models.gd` |
| Botanical and residents | Crafted planter, broadleaf, fern and palm collections, three clothed residents | `garden_fixture_geometry.gd`, `botanical_collection.gd`, `palm_geometry.gd`, `resident_assets.gd`; `tests/export_garden_resident_models.gd` |

The bed includes separate structural rails and feet, a curved headboard, mattress welt, lofted pillows and a continuous draped coverlet. Cabinets use frame-and-panel construction, raised mouldings, curved pulls, hinges and grilles. Tables have profiled edges, inlay, aprons and turned legs. Small props use hollow lathed vessels, continuous curved handles/spouts, formed leather cases, fitted metal caps, book bindings, woven baskets and cloth folds.

Rebuild only the evidence cup with `godot --headless --path . --script res://tests/export_hero_models.gd -- --only=evidence_cup`; other baked models remain untouched. The exporter checks reloaded mesh/collision counts and measures residue contact with the inner ceramic and clearance above the tea.

Model review uses neutral studio and clay renders, followed by in-world views. `tests/capture_assets.gd`, `capture_furniture_assets.gd`, `capture_art.gd` and `capture_coverage.gd` provide repeatable review cameras; set `NOCTURNE_ART_OUTPUT` for the output directory. The source models remain original procedural artwork, with some stylization in characters and surfaces.
