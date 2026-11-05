# Reference material set

The four user-supplied Agatha cyber-luxe boards are archived under `art/references/`. They are concept references, not UV texture sheets. `cyber_luxe_material_atlas.png` is an original generated albedo atlas made from those references, with sixteen photographed-style material swatches arranged in four equal rows. No labels, scene lighting, furniture pictures or board text are projected into the game.

| Row | Left to right | Physical repeat in centimetres |
| --- | --- | --- |
| 1 | Mahogany, walnut, tarnished brass, brushed steel | 48×140, 48×140, 24×24, 18×18 |
| 2 | Emerald velvet, cognac leather, ivory linen, botanical damask | 5×5, 6×6, 2.8×2.8, 58×58 |
| 3 | Persian wool rug, plaster, ivory ceramic, beige marble | 90×90, 26×26, 8×8, 90×90 |
| 4 | Terracotta, paper fibers, leaf tissue, skin pores | 6×6, 4×4, 3×3, 2.5×2.5 |

`material_library.gd` shares the maps and materials across furniture, architecture, props, residents and reusable asset scenes. `crafted_surfaces.gdshader` mirrors and insets each tile to avoid visible joins and adjacent-cell bleed. Physical triplanar mapping works on authored meshes and normalized MultiMesh primitives. Roughness, metallic response, coat and subtle derivative-based relief differ by material. The relief is derived from the image; it is not a scanned PBR normal/roughness set. Texture motion is disabled: surfaces remain anchored to the model or world.

Glass, liquids, emissive screens, vertex-colored evidence residue and the already-authored palm leaf photograph retain their original material data. Weather and distant city scenery are excluded from the interior material pass. Opaque painted metal keeps a dielectric paint response rather than becoming bare chrome. Floor joints are shading only; collision and doorway clearances remain unchanged.

Validation includes actual Forward+ frames, coverage of all sixteen families, close inspection views, standalone asset views, a pixel comparison across authored/batched wood, clue/display preservation, and the existing movement and investigation suite. Visual quality is still limited by the authored geometry and lighting; the concept boards are an art target rather than a claim that the game exactly reproduces their rendered scenes.
