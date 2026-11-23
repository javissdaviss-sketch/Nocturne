# The Nocturne: one identity per room

The renderer and game use three playable carriages, fourteen actual rooms. A room's stable key is `car:side:lo`: carriage index starting at 0, physical X side, then room start Z in cm. This is an art plan, not a claim that all treatments have shipped. Doorways, original case props/flight routes, interactive guards and normal map labels must stay as authored.

| Key | Existing room (+ art subtitle) | Open door, cm | Material story | Signature silhouette and real detail | Keep undisturbed |
|---|---|---|---|---|---|
| 0:-1:0 | Sleeper Suite / Writing berth | z55, w92 | Walnut, muted oxblood velvet, warm linen | Pleated inner bunk frame and slender brass-held writing recess | Vale's actual note/desk and reading light |
| 0:1:0 | Sleeper Suite / Crew sleeper | z194, w84 | Pale oak, olive wool, brushed hardware | Open rounded shelf/flip-down joinery and hanging kit rail | Real radio face and fly approach |
| 0:-1:360 | Engineering Quarters / Coast berth | z740, w92 | Pale linen, woven slate, warm wood | Round porthole-style photo surround and stitched bunk bolster | Actual photo, book and route |
| 0:1:360 | Engineering Quarters / Maintenance | z740, w92 | Blackened steel, olive wool, cooler task tone | Nested instrument housing and distinctly vertical vent ribs | Working terminal and stamp |
| 1:-1:840 | Reception / Concierge | z889, w84 | Green lacquer, brass, dark mineral top | Stepped fascia and inset signage arch around the concierge surface | Clear foyer aperture and circulation |
| 1:1:840 | Reception / Cloakroom | z889, w84 | Navy ribbed liner, brushed steel, umber leather | Rounded rail and closed luggage bank | Existing doors and open approach |
| 1:-1:990 | Private Dining / Meridian saloon | z1150, w92 | Neutral walnut grain, burgundy upholstery, ivory porcelain | Modelled portal/dado; shallow stepped sunburst, curved chair shoulders | Cup, shroud, tables, coasters, case lighting and anchors |
| 1:1:990 | Private Dining / Tea salon | z1240, w92 | Teal mohair, satin cream, subdued nickel brass | Curved tea shelf fronts, individual softer furniture seams | Existing steward route and furniture |
| 1:-1:1390 | Galley & Service / Pantry | z1580, w92 | Warm ivory tiles, dark steel, subtle amber | Shaker counter fronts with a copper-backed shelf lip | Nothing added across the opening |
| 1:1:1390 | Galley & Service / Steward's store | z1588, w84 | Blue-grey enamel, patinated rail hardware | Rounded panel surround and full-height ventilation relief | Original cabinet, lever, small cable runway and bottle |
| 2:-1:1680 | Propagation Lab / Orchid display | z1750, w92 | Bronze, sage and pale ceramic | Shallow greenhouse ribs with visible cross-section; framed pedestal | Physical orchid, original geometry/routing |
| 2:1:1680 | Propagation Lab / Potting | z1750, w92 | Pale mottled tile, terracotta, galvanised steel | Deep work sink/board profile, smaller cloth reference | Actual shipment label and potting approach |
| 2:-1:2045 | Seed Archive / Heritage seed store | z2110, w92 | Quiet dark timber, brass and parchment | Rounded shelf mount and nested Seed Lift fascia | Both bends, opaque baffle, glass, balance spoon, real motion |
| 2:1:2045 | Seed Archive / Live reserve | z2400, w92 | Clean iron, opal/cream and quiet cyan | Slender greenhouse shelf arch and ribbed canopy | Original existing nursery indicator and front-side sensor |

## Build gates

- Shared Deco chapter: keep the established materials, build real rounded/profiled depth rather than laying gold lines on slabs. Highest-priority shots are fly height in the corridor, around the original cup, and an occupied room doorway. No new lights required.
- Distinct room chapters: local surface plus recognizable geometry, not colour changes alone. A low interior render can be useful, but no room is validated until its actual viewpoints and approaches have been checked.
- Dimensional contract: each pilot keeps the full original opening and its original broad structural backings, actual newly exposed detailing uses actual contact geometry, and no clue, pose or save shifts just for decor. New shadows and draws have separate budgets.
- Use native camera pairs with matched angles, settings and renderer for appearance. Headless physics and cloud GL visual workload are not Windows FPS or a human playthrough.
