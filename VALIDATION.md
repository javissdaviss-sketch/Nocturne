# Prototype validation — 3 November 2026

Godot 4.6.3, Linux x64. Windows x64 and Linux x64 release exports completed without export warnings or errors.

- **Passed:** authored case logic, valid/invalid culprit and motive, incomplete evidence, duplicate discoveries, physical versus overheard evidence counts.
- **Passed:** atomic save/reload, malformed JSON, unknown clue IDs, invalid saved positions, inconsistent locked evidence.
- **Passed:** uninterrupted traversal aisle across three carriages; real cable opening under the closed cabinet; cabinet blocks the bottle before release; all six clues have unobstructed nearby inspection approaches after puzzle completion.
- **Passed:** CharacterBody collision with a tabletop, landing and takeoff, window collision.
- **Passed:** source integration through evidence inspection, cabinet release, symbol lock, notebook, wrong deduction, correct deduction, ending, restored progress, pause, and settings.
- **Passed:** packaged Linux executable launches and renders the title, all three interiors, physical cup inspection, notebook, deduction, actual third-person fly view, and ending. Screenshots were captured using Xorg and Mesa llvmpipe software rendering.
- **Passed:** final packaged Linux executable runs the integration smoke flow headlessly.

Windows execution and performance on a real dedicated GPU remain **unverified**. The exported Windows executable has a valid Windows x64 PE format. The Linux software-rendered graphical run produced only a driver warning that changing V-Sync is unsupported; there were no script errors. No measured frame-rate guarantee is made.

The prototype uses stylized procedural scenery, synthesized audio, and subtitled conversations. Test playback used the Dummy audio driver, so actual speaker output was not auditioned in this environment.

See README.md for reproduction commands. Run the integration smoke with a separate user-data directory because it creates a case save.

## 0.1.1 hotfix and updater pipeline

The full-screen UI consumed mouse motion before the fly's unhandled-input callback. Mouse control now runs in `_input` before GUI filtering; noninteractive UI roots ignore mouse events. The graphical regression reproduced the old failure and passes after the fix, covering horizontal/vertical look, wheel zoom, pause/resume, inspection right-drag, and release. Existing case, geometry, and integration tests still pass.

The native Windows updater, offline installer, GitHub Actions pipeline, checksum manifest, and draft-first publisher are included. Local updater and release-package tests are recorded in the implementation output. Windows-specific tests must run in the repository workflow before a release is published; they are not claimed to have run in this Linux workspace.

Local updater validation passed nine Go test groups (including race detection), Go vet, Windows cross-compilation, and four Python publication/packaging test groups. Windows CI includes native updater tests, packaged game startup, quiet offline installation, installed-version verification, and desktop shortcut verification. Publishing remains gated on those jobs.

## Rain and neon atmosphere

Godot 4.6.3 GL Compatibility: graphical renders of the lounge, winter garden, and a close window show layered moving city buildings, housed neon signs and local halos, window beads/runoff, and exterior rain without shader or script errors. City geometry uses six MultiMesh batches; particles are bounded at 840 exterior rain streaks and 135 indoor dust motes. Distance fog starts 550 cm from the camera to keep nearby evidence clear. No Forward+ or volumetric-fog dependency is introduced.

Case/collision/save, jump, graphical mouse, and full investigation checks pass. The atmosphere regression uses a separate user-data directory and checks rain containment, old-settings migration, the real Settings toggle, saved preferences across restart, and re-enabling emission/rendering.

A fixed lounge view on Mesa llvmpipe software rendering measured median frame durations of 522 ms (on), 527 ms (off), and 485 ms (on again), twelve samples per state after warmup. The variation exceeds the observed effects delta; this is a comparison on software rendering, not a hardware frame-rate guarantee. Real GPU performance remains unmeasured. The Rain & atmosphere setting disables the added particles, window shader, halos, and haze.

## Interior identity and set dressing

Graphical GL Compatibility checks cover the lounge, residences, garden, close dining setting, and mounted twelve-carriage directory. The new runners, wood and upholstery shaders compile without errors. Travel/service/botanical props are batched into 39 MultiMeshes and the signage fixture geometry into three; decorative props add no collision geometry or interactions. The existing six clues, access duct, covered crime scene, and settings retain their behavior. Case/collision/save, jump, atmosphere persistence, graphical mouse, and complete investigation checks pass.

Palm midrib segments are merged into one mesh per frond while keeping the crown sway. In the same lounge camera, a render snapshot decreased from approximately 8,575 draw calls before this merge to 4,477 after it, including the new dressing. These counts describe this camera under Mesa software rendering; real GPU frame rate remains unmeasured.

## Additional carriage props

Residential, hospitality, and garden prop groups add 452 primitive components in 61 material/shape batches: luggage racks and carry-ons, hat/umbrella stand, chess and reading lamp, radio, a fully dressed two-shelf tea trolley, service utensils, watering can, nursery tray, propagation rack, hose reel, and a slatted garden crate. Shared mesh transforms now apply local dimensions before rotation, keeping angled rods, wheels, handles and book bindings correctly proportioned.

Graphical GL Compatibility previews of chess/lamp, residential furnishings, tea trolley, and garden equipment pass without script or shader errors. Case, jump, atmosphere persistence, graphical mouse, and full investigation tests pass. New physics checks verify the crate's slats are solid, their actual gaps are open to the fly, and the rim supports perching. The clue locations and central aisle are retained.

## Solid interior objects — 4 November 2026

Interior MeshInstance and MultiMesh geometry is compiled to collision: closed box/cylinder/sphere components use matching convex volumes; ring holes and custom leaf/merged geometry use backface-enabled triangle collision. Collision shapes follow local mesh transforms, including nonuniform scale, shear and reflection. Per-instance CPU transforms preserve the same physics under headless rendering. Existing door/drawer collider states are retained, and city/weather/particles/UI are excluded. Shared shape resources avoid repeating collision construction for identical geometry. The earlier visual-only prop descriptions above describe prior releases.

Regression tests that initially failed on decorative meshes now pass for trolley decks/legs, luggage, radio, chessboard, lamp, people, palm canes/fronds, torus handles and rims, actual full-speed flight, walking into raised objects, landing on a thin tray, and taking off beneath a thin ceiling. The crate gaps remain passable. The cable itself is now solid; the tested duct route passes above it at y12, below the door at y13, and ends within latch reach. Body-swept landing/takeoff replace the old position teleports.

Saved-position tests verify that a fly embedded in the radio is moved to nearby clear space and a valid position is preserved. All three speaker prompts work against their own bodies; a separate obstruction still blocks interaction. Geometry tests cover true holes, deep overlap detection, transforms, exclusions, existing disabled puzzle colliders, and idempotent compilation. The solid-object/controller regression also passes under graphical GL Compatibility, in addition to headless physics. Case, jump, atmosphere, smoke and graphical mouse checks pass. Graphical checks used Mesa software rendering; hardware frame rate remains unmeasured. Native Windows startup/install checks run in the release pipeline.

## Wide compartment train — 4 November 2026

Carriage floors and roofs are 1,020 cm wide, with exterior walls and sealed rain glass moved out by 340 cm on each side. Fourteen rooms have full-height longitudinal and transverse partitions, 92 cm open sliding-door portals, and human-sized furniture. Added room geometry participates in the existing solid-geometry compiler. Exterior rain and city layers move outward with the train; saves accept positions in the expanded interior.

The case regression checks each room's open corridor entrance, solid partition and floor, plus saving/reloading an outer-room position and flight-controller acceptance beyond the old width. Existing evidence approaches, cable duct, connected carriage aisle, window containment and garden-crate gaps still pass. Solid geometry, solid objects, jump, atmosphere persistence, graphical mouse and complete investigation checks pass. Graphical previews cover corridor, sleeper, dining and garden interiors under Mesa llvmpipe GL Compatibility. Native Windows execution and hardware GPU performance remain subject to release CI and hardware validation.


## Cyber-luxe art and static rendering — 4 November 2026

Original in-engine furnishings interpret the user's reference boards, including brocade wall panels, mahogany and brass joinery, curtains, buttoned velvet, softened cushions, bedside displays, travel trunks, filament lamps, pocket watches, dressed dining tables and botanical sensors. A notebook page establishes life aboard the residential night network and the botanical trust. The three-carriage mystery, fourteen portals, original evidence positions and existing saves are preserved.

Case/save/geometry, solid-object, jump, atmosphere and full investigation smoke checks pass using isolated test data. The case regression also checks that static batches reduce source mesh submissions and that cabinet/drawer visuals remain independently visible until their puzzle release. Graphical mouse input and the complete solid-object/controller regression pass under Xvfb and Mesa llvmpipe GL Compatibility. Title, world-notebook and cup-inspection UI captures were also reviewed for legibility and layout. Release packaging tests and Go updater race tests pass.

Graphical review captures cover the corridor, sleeper, salon, archive and close-up evidence. The sampled corridor draw count fell from 12,463 before static primitive batching to 6,746 after batching; the salon fell from 4,354 to 2,623. This measures renderer submissions, not hardware frame rate. The final scene batches 2,036 static primitive source meshes into 552 spatial/material groups. Original collision nodes remain in place; opening puzzle leaves, animated palm crowns, city, rain and particles are excluded from static batching.

Native Windows startup and installation are verified by the main-branch release workflow before publication. Hardware GPU performance remains unmeasured in the Linux software-rendered environment.

## Detailed model library and Forward+ — 5 November 2026

The expanded art brief replaces visible furniture and prop blockouts with separately authored reusable models. Twenty-eight standalone Godot scenes retain their render geometry and physical collision after disk reload. The library covers beds and bedside cabinets, wardrobes and service counters, tables and seating, luggage and books, radio/chess/tea service, investigation objects, botanical fixtures and plants, and clothed residents. Studio, side, rear and clay reviews led to corrected cloth folds, shaped joinery, inset panels, continuous vessel profiles, fitted luggage hardware, curved label typography and clearer instrument controls. The resulting assets remain original artwork; resident faces retain stylization.

The default renderer is Forward+. Room reflection probes, SSAO, SSIL, restrained glow, four-sample MSAA and soft shadows support the modeled surfaces. Textured timber replaces the conspicuous periodic relief; organic botanical brocade replaces the large angular wall repeat. City buildings now use human-scale floor/window dimensions, recessed facades and coherent train motion. Revised wet glass refracts scene colors rather than drawing bright independent dots. These rendering features are checked on an actual Vulkan display using Mesa lavapipe, not inferred from a headless launch.

The complete case, geometry, solid-object, jump, atmosphere, mouse and investigation smoke checks passed after the model integration, with no script/shader error or failed-assertion output. The real X11/GL mouse and collision checks use a fixed simulation rate and disabled repeated rasterization; the separate Forward+ check and visual captures render actual frames. Larger deterministic geometry construction required longer CI timeouts. Four release-package/publication tests also pass.

Starting a new investigation now frees the detached old world before constructing its replacement. The final complete smoke test passed with approximately 5,272 MiB peak resident memory in this environment; this measurement concerns test-process memory, not a graphics-performance claim. Custom convex rounded solids opt into convex collision so deeply embedded saves still recover; vessels, handles, cloth and plant surfaces retain triangle geometry and real openings. Nested puzzle hardware is excluded from static batching and its collision is disabled recursively when the corresponding cover/door opens.

Integrated views exposed and corrected a palm intersecting the chaise, obsolete facade panels in front of the new service cabinetry, and unfilled strips beside the locked service door. The fixed front has a physical sweep regression while the original under-door cable route remains open. Existing clue positions and case progression are retained.

The independent visual reviewer accepted the final ten-view release capture after darker city masonry and moving galley canisters clear of the data slate. Corridor, sleeper, salon, archive, evidence, chaise, galley, closed/open service cabinet and chemical close-up retain the reviewed geometry and readable labels. Texture mipmaps and anisotropic filtering preserve close detail while calming distant patterns.

A separate placement audit and seven targeted views corrected ceiling support for the luggage racks, floor support and luggage clearance for the reading console, specimen-pot contact with the actual soil surface, and planter/palm/side-table intersections with residents. Refreshed full-body and close-up views passed independent review. Clue and conversation targets remain in place. The dining roll also reuses the continuous scored-bread model instead of its original sphere assembly.

Final inspection review replaced the original violet spheres with thin irregular deposits adhered to the cup wall and sparse angular crystals. The complete evidence cup is exported with six render meshes and six collider bodies; all earlier model-file checksums remain unchanged. Case and solid-object checks pass again with the refined clue. An aligned dark strip now keeps the inspection orbit/zoom hint readable over bright objects, and the empty gameplay-prompt backdrop hides outside play mode.

Repeated opaque authored meshes now share spatial render batches without simplifying their geometry. Regression coverage checks original shadows and render layers, attached labels, transparent sorting, mirrored-mesh exclusion and independent puzzle leaves. A small real Forward+ probe confirmed that zero-layer source meshes do not submit duplicate shadows. Singleton meshes retain their original shadows; draw counts are therefore not presented as a direct performance improvement over the earlier primitive-only pass.

The actual Forward+ frame check passed, and final title, notebook and in-world inspection captures passed independent review after the UI correction and residue refinement. The source import and whitespace checks are clean. Publication remains gated on the hosted gameplay/rendering, package-build and native Windows installation jobs.

Forward+ shutdown reports seven Texture RID warnings with the six room reflection probes. A minimal cube-and-probes scene reproduces the same warning in Godot 4.6.3 on lavapipe; removing the probes eliminates it, and extra rendered cleanup frames/force-sync do not. Captures exit successfully. This observed engine/backend cleanup warning is documented rather than hidden with a gameplay workaround.
