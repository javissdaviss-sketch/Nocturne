# A Fly on the Night Train

A playable, original 3D murder-mystery prototype. You are a six-millimetre housefly aboard the Nocturne, a twelve-carriage residential train. Three connected carriages are open: the residences, dining lounge, and tropical winter garden. Explore, inspect physical evidence, overhear residents, and solve Elias Vale’s murder.

## Automatic updates

For a one-time desktop install and future automatic updates, use **Nocturne-Setup-Windows.zip**, extract it, and run **Install-Nocturne.cmd**. Then launch from the **Nocturne** desktop shortcut. See [UPDATES.md](UPDATES.md) for the build/test/deploy pipeline, rollback, and setup details.

## Play on Windows

Extract **Nocturne-Windows.zip**, then double-click **Nocturne.exe**. No installation, network connection, account, or Godot installation is required. Keep the included notices with the game. The unsigned executable may trigger Windows’ normal downloaded-app warning.

Windows 10/11 x64, keyboard and mouse, and a dedicated GPU with OpenGL 3.3 support are the initial target. Actual Windows performance has not been measured in the Linux development environment. Defaults: 1280 × 800, 60 FPS cap, shadows enabled. Settings allow other resolutions, frame limits, shadows, sensitivity, and separate ambience/wing volume. Rain & atmosphere can be disabled in Settings to turn off window droplets, exterior precipitation, cabin dust, distance haze, and neon halos.

A Linux x64 build is also included as a development convenience: `chmod +x Nocturne.x86_64` and run it on an X11-capable desktop with OpenGL 3.3 support.

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

The passing city uses layered parallax, housed neon signs with soft shader halos, rain on the sealed windows, exterior precipitation, and sparse lamplit dust. These effects run on the existing GL Compatibility renderer.

The scenery is generated deterministically from original procedural geometry. World coordinates use one engine unit per centimetre. `world.gd` builds modular carriages and physical props; `fly.gd` handles centimetre-scale flight and cameras; `case_data.gd` contains the authored mystery; `case_state.gd` stores progress; `game.gd` owns interaction and UI. No external libraries, paid assets, API keys, or online services are needed.

### Verification

The mouse-look regression requires a graphical display (or Xvfb), because headless Godot does not capture the mouse. Run `xvfb-run -a godot --path . --audio-driver Dummy --script res://tests/test_mouse.gd` in addition to the checks below.


```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_case.gd
godot --headless --path . --script res://tests/test_solid_geometry.gd
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

## Credits and notices

Original story, geometry, UI, and synthesized audio created for this project. No Agatha Christie characters or plots are used. Godot is distributed under the MIT license. The two bundled fonts are DejaVu Serif and DejaVu Sans, renamed for project use; their license is included in `THIRD_PARTY_NOTICES.txt`.
