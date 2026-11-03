# Nocturne development

- Godot 4.6.3, GDScript, centimetre world units. The player is a life-size 6 mm housefly.
- Keep the existing three-carriage mystery and physical inspection flow working when fixing issues.
- Mouse camera input runs before GUI filtering. Mouse regression tests require a real display or Xvfb; headless Godot cannot capture the mouse.
- Game checks: import the project, run `tests/test_case.gd`, `tests/test_jump.gd`, `tests/test_atmosphere.gd`, graphical `tests/test_mouse.gd`, and the complete `--smoke` flow with separate test user data.
- Updater changes: run `go test -race ./...` and `go vet ./...` from `launcher/`; cross-compile for Windows. Release scripts: run Python unittest discovery in `pipeline/`.
- `.github/workflows/release.yml` tests, builds, validates on Windows, and publishes main-branch commits. The user wants tested fixes deployed through this pipeline so the installed launcher updates on its next launch.
- Never overwrite a published version or move latest before all release assets are uploaded. Preserve existing saves and leave a playable previous version on update failures.
- Build with `python3 pipeline/build.py`; publish with `pipeline/publish.py` or the main-branch workflow. See UPDATES.md.
- Verify actual GitHub access, CI results, and release publication before claiming a fix is deployed. Report connection failures honestly; do not put credentials in the repository or launcher.
