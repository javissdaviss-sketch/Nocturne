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
