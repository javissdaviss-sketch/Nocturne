# Fly Spy With My Little Eye

A playable, original 3D murder-mystery prototype. You are a six-millimetre housefly aboard the Nocturne, a twelve-carriage residential train. Three connected carriages are open: the residences, dining lounge, and tropical winter garden. Explore, inspect physical evidence, overhear residents, and solve Elias Vale’s murder.

## Automatic updates

For a one-time desktop install and future automatic updates, use **Nocturne-Setup-Windows.zip**, extract it, and run **Install-Nocturne.cmd**. Then launch from the **Fly Spy With My Little Eye** desktop shortcut. See [UPDATES.md](UPDATES.md) for the build/test/deploy pipeline, rollback, and setup details.

## Play on Windows

Extract **Nocturne-Windows.zip**, then double-click **Nocturne.exe**. No installation, network connection, account, or Godot installation is required. Keep the included notices with the game. The unsigned executable may trigger Windows’ normal downloaded-app warning.

Windows 10/11 x64, keyboard and mouse, and a modern dedicated GPU with Vulkan support are the high-quality target. The default renderer is Forward+; OpenGL Compatibility remains available through `--rendering-method gl_compatibility`. Actual Windows performance has not been measured in the Linux development environment. Defaults: 1280 × 800, 60 FPS cap, shadows enabled. Settings allow other resolutions, frame limits, shadows, sensitivity, and separate ambience/wing volume. Rain & atmosphere can be disabled in Settings to turn off window droplets, exterior precipitation, cabin dust, distance haze, and neon halos.

A Linux x64 export preset is included for development. After exporting, use `chmod +x Nocturne.x86_64` and run it on an X11-capable desktop with Vulkan support. The Compatibility override requires OpenGL 3.3.

## Controls

| Control | Action |
| --- | --- |
| WASD | Fly relative to the camera’s horizontal heading |
| Mouse | Look around |
| Space / Ctrl | Rise / descend |
| Shift | Slow precision flight |
| Scroll wheel | Adjust third-person camera distance |
| E | Inspect or listen; land if no object is nearby |
| L | Land / take off, including beside evidence |
| Space (landed) | Tap to jump; double-tap within 0.3 seconds to take off |
| J | Notebook, field photographs, and carriage guide |
| Tab | Final deduction |
| Esc | Pause or close the current screen |
| H | Flight and investigation guide |
| Right mouse + drag | Orbit the object during inspection |

You can hover freely and land on horizontal surfaces. You cannot carry human-sized objects or crawl on ceilings. If disoriented, scroll out and use the central aisle. Pause → **Return to a safe perch** resets your position without losing evidence.

## Investigating

Diamond markers show nearby objects. Approach until the E prompt appears. Clues exist as physical props: the cup, chemical bottle, handwritten note, shipment label, maintenance terminal, and ledger. Examine them where they lie; observations and photographs are saved in your notebook. Subtitled conversations can be replayed near three suspects. The covered crime scene is non-graphic.

Start with the cup on Vale’s dining table. The notebook’s carriage guide helps you find the rest. The service cabinet has a tiny cable opening below its door. The conservatory’s dispatch drawer uses a three-symbol lock. Essential evidence is never consumed, and an incorrect deduction does not end the investigation.

Progress saves automatically every twelve seconds and after discoveries and puzzle completion. **Begin investigation** starts over; **Continue** restores the saved case. Settings are stored separately. On Windows, saves live in `%APPDATA%/Godot/app_userdata/A Fly on the Night Train/`.

## Open the source

Use **Godot 4.6.3** (4.6 series recommended), import `project.godot`, then press F6/F5 or run:

```sh
godot --path .
```

The carriages carry a shared Deco identity: mounted twelve-carriage directories and service plaques, patterned runners, walnut flooring, woven seating, travel luggage and reading shelves, laid dining settings, and botanical work supplies. Additional props include overhead luggage racks, a hat-and-umbrella stand, a tabletop radio, a travel chess set and reading lamp, a wheeled tea trolley, and a garden watering can, propagation rack, seedling tray, hose reel, and slatted crate. Interior furniture, props, people, palm trunks and fronds now have collision that follows their visible geometry. Handles, rack openings and crate gaps remain open. Flight, walking, landing and takeoff use body sweeps; older saves embedded in formerly decorative props recover to nearby clear space. The six physical clues retain their original positions and inspection flow.

The passing city uses layered parallax, housed neon signs with soft shader halos, rain on the sealed windows, exterior precipitation, and sparse lamplit dust. These effects work in Forward+ and GL Compatibility. Forward+ additionally provides room reflections, ambient occlusion, indirect screen-space lighting and restrained glow.

The scenery is generated deterministically from original procedural geometry. World coordinates use one engine unit per centimetre. `world.gd` builds modular carriages and physical props; `fly.gd` handles centimetre-scale flight and cameras; `case_data.gd` contains the authored mystery; `case_state.gd` stores progress; `game.gd` owns interaction and UI. No external libraries, paid assets, API keys, or online services are needed.

### Verification

The mouse-look regression requires a graphical display (or Xvfb), because headless Godot does not capture the mouse. Run `xvfb-run -a godot --path . --rendering-method gl_compatibility --disable-render-loop --fixed-fps 60 --audio-driver Dummy --script res://tests/test_mouse.gd` in addition to the checks below. The input and physics checks keep the real display/backend while avoiding repeated software rasterization. Validate actual rendered output separately with `xvfb-run -a godot --path . --rendering-method forward_plus --rendering-driver vulkan --audio-driver Dummy --script res://tests/test_rendering.gd`.


```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_case.gd
godot --headless --path . --script res://tests/test_solid_geometry.gd
godot --headless --path . --script res://tests/test_render_batches.gd
XDG_DATA_HOME=/tmp/nocturne-solid-tests godot --headless --path . --script res://tests/test_solid_objects.gd
godot --headless --path . --script res://tests/test_jump.gd
XDG_DATA_HOME=/tmp/nocturne-atmosphere-tests godot --headless --path . --script res://tests/test_atmosphere.gd
godot --headless --path . -- --smoke
```

Run tests with a separate `XDG_DATA_HOME` on Linux because `--smoke` starts and completes a case in that runtime’s save directory. Geometry/state tests cover every physical clue’s approach, the fly-sized duct, the locked cabinet, connected carriage aisles, landing, window collision, malformed saves, and valid/invalid deductions. The integration smoke exercises the notebook, settings, inspection, ending, and save/reload.

Export presets target Windows x64 and Linux x64. Install the matching Godot export templates, then:

```sh
godot --headless --path . --export-release "Windows Desktop" ../builds/windows/Nocturne.exe
godot --headless --path . --export-release "Linux Desktop" ../builds/linux/Nocturne.x86_64
```

## Prototype boundaries

Three playable carriages; the other nine are established by the setting and locked end doors. Single-player, one authored case, stylized procedural art, text conversations, and simple puzzles. No combat, ceiling crawling, voiced dialogue, full train simulation, or gamepad support. This is a prototype, not a finished commercial game.

## Cyber-luxe interiors

The supplied Agatha cyber-luxe reference boards inform original in-engine furniture and finishes: botanical brocade, mahogany wainscoting, brass panel frames, ivory corridor ceilings, fluted lamps, folded teal curtains, and velvet upholstery. Sleeper suites have buttoned headboards, softened mattresses and pillows, bedside controls, travel trunks, data slates, filament lamps, and pocket watches. The dining salon has dressed tables and Deco wall medallions; the living archive has brass-trimmed planters and specimen sensors. The boards are visual references rather than production-ready individual models or seamless textures; their collages are not pasted into the game.

The notebook's **Life aboard the Nocturne** page introduces the residential night network, the train's tradition of repair and craftsmanship, and the botanical trust's conservation work. New details preserve the six evidence positions, fourteen open compartment entrances, cabinet duct, and dispatch puzzle.

Repeated static meshes use spatially grouped MultiMeshes after collision compilation, preserving the authored geometry and material detail. Original physics nodes and attached labels remain in place, and the opening cabinet, dispatch drawer, moving palms, city, rain, and particles retain independent behavior. Transparent and mirrored authored meshes retain their individual rendering. Botanical brocade and timber textures provide close-range surface detail, with no runtime asset downloads. `tests/capture_art.gd` produces repeatable corridor, sleeper, salon, archive, and fly-scale evidence views for graphical review.

The detailed model pass replaces furniture blockouts with constructed beds, draped bedding, framed cabinetry, profiled tables, upholstered seating and shaped botanical fixtures. Small props have leather seams and fittings, book bindings, open ceramics, continuous spouts, folded linen and woven basketry. Investigation objects retain their original positions while gaining modeled enclosures, labels, hardware and joinery. The [standalone model library](assets/models/README.md) contains reusable Godot scenes; the world uses the same builders. Separate studio, clay, rear and in-world reviews guide refinements.

## Credits and notices

Original story, geometry, UI, and synthesized audio created for this project. No Agatha Christie characters or plots are used. Godot is distributed under the MIT license. The two bundled fonts are DejaVu Serif and DejaVu Sans, renamed for project use; their license is included in `THIRD_PARTY_NOTICES.txt`.

## Compartment train expansion

The three investigation carriages are now 10.2 m wide (three times their original 3.4 m), with a continuous 1.1 m central corridor and fourteen rooms behind full-height partitions. Retracted sliding doors provide open physical entrances. Residential suites have beds, wardrobes and sitting areas; hospitality has reception, private dining and service rooms; the winter garden has propagation and archive compartments. Steel bulkheads, exposed overhead utilities and brass wayfinding take inspiration from Snowpiercer while retaining Nocturne's night-train setting.

Furniture and the 6 mm fly keep their original scale. The six clues, conversations, cabinet duct and symbol puzzle stay in place. Window glass, outside rain, city clearance, flight recovery limits and saved-position validation follow the expanded width.


## Design review and realism pass

An independent visual reviewer assessed unchanged corridor, suite, salon, archive and evidence camera views across successive design/build/review cycles. Feedback drove quieter walnut and brocade, complete salon emblems, motivated pendant lighting, fewer competing brass dividers, and varied broadleaf/fern planting. The later realism pass adds shared rounded upholstery with modeled tuft recesses, shaped chair frames and tapered legs, smooth lathed ceramic profiles, subtle material relief and varnish, four-sample antialiasing, and Forward+ contact shading and reflections. Room shadow lights obey the existing Shadows setting.

The art remains an original procedural prototype with stylized architecture and characters; these changes move its material response and forms toward realism. Hardware frame rate has not been measured on the player's laptop. Set resolution and frame limit in Settings. The standard regression flow uses GL Compatibility for input/physics checks and a separate actual Vulkan Forward+ frame test for high-quality rendering.


The game is now titled **Fly Spy With My Little Eye**. The Nocturne remains the name of the train. Existing update URLs, launcher storage and the original Godot save profile remain compatible. Existing Nocturne desktop shortcuts targeting the installed updater are renamed on first launch; unrelated shortcuts are left alone.

Fourteen room portals now have reserved approach volumes. Wall rails stop at the jambs, door leaves park within their own wall bays, and nonessential furnishings have been moved clear of the openings. Door clearance is checked with full-height overlap volumes and two-way fly-body sweeps. Clue positions and the cable route stay fixed.
