# Build, test, deploy, and automatic desktop updates

Repository: https://github.com/javissdaviss-sketch/Nocturne

## Player setup — once

Download **Nocturne-Setup-Windows.zip**, extract the entire ZIP, and double-click **Install-Nocturne.cmd**. It installs into `%LOCALAPPDATA%\Nocturne` and creates a **Nocturne** shortcut on the real Windows Desktop (including a redirected OneDrive Desktop). No administrator privileges are needed.

Open that shortcut thereafter. It checks the repository's latest release manifest, downloads a newer tested game, verifies SHA-256 and byte length, extracts into a new version directory, and switches the active version only after extraction succeeds. It then starts the game. A brief update console appears during checking/downloading and hides when play begins.

The setup includes an offline copy of the tested game with the mouse fix. Your existing Godot case saves remain in the same location. Running your previous standalone `Nocturne.exe` bypasses updates; use the new desktop shortcut.

Network failures, interrupted downloads, checksum mismatches, or unsafe archives leave the installed version available. The previous build is retained. A newly selected build that fails to start, or exits with an error within fifteen seconds, falls back to the previous build. This does not detect every possible gameplay bug: the release tests remain the main quality gate.

For manual recovery, run `%LOCALAPPDATA%\Nocturne\Nocturne-Launcher.exe --rollback`; it rolls back and skips updating for that launch. `--offline` skips the network without switching versions. Logs are in `%LOCALAPPDATA%\Nocturne\launcher.log`.

## Automatic publication

`.github/workflows/release.yml` runs on pushes to `main`, pull requests, and manual workflow dispatches:

1. Import the project; run case, collision, save, complete-investigation, and real graphical mouse regression tests.
2. Run the Go updater tests with the race detector, plus release-manifest and packaging tests.
3. For main pushes or manual runs, export the Windows game and build the native Windows launcher and offline setup.
4. On a Windows runner, test the updater natively, run the exact exported game headlessly, perform a quiet installation, and verify the created desktop shortcut and installed version.
5. On `main`, verify all artifact checksums, create a draft GitHub Release, upload every artifact, then publish it and move `latest`.

Pull requests test only; they never publish. The publish job has `contents: write`; other jobs have read access. No personal token is embedded in the game or launcher. GitHub supplies the job's short-lived publishing token.

Automated versions are `0.1.<workflow run number + 1>` so each successful pipeline can advance the update channel from the bundled 0.1.1. Failed runs may leave harmless gaps. Only published non-prerelease releases enter the channel. Releases are immutable: never replace the files behind an existing version. If upload fails, the incomplete release remains a draft and existing players retain the previous `latest`.

This repository is public, and both game source and release downloads will be public. Keep the configured repository public for unauthenticated desktop updates.

## Local development

Godot 4.6.3, Go 1.25.3, Python 3.11+, and matching Godot Windows export templates are required. The Go launcher uses only its standard library; Python build/publish scripts have no third-party dependencies.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/test_case.gd
xvfb-run -a godot --path . --audio-driver Dummy --script res://tests/test_mouse.gd
godot --headless --path . -- --smoke
(cd launcher && go test -race -v ./...)
python3 -m unittest discover -s pipeline -p 'test_*.py' -v
python3 pipeline/build.py --out .release --version 0.1.1
```

Use separate test user-data directories for integration tests. The mouse regression requires an actual graphical display or Xvfb: headless Godot intentionally cannot capture the mouse.

The build outputs `Nocturne-Windows.zip`, `Nocturne-Setup-Windows.zip`, `Nocturne-Source.zip`, `update.json`, and `SHA256SUMS.txt`. Build scripts stamp the exported version temporarily and restore the source configuration afterward.

To publish a reviewed local build after all tests pass, with an authenticated GitHub CLI:

```sh
python3 pipeline/publish.py --directory .release --version 0.1.1 \
  --repository javissdaviss-sketch/Nocturne --commit YOUR_COMMIT_SHA
```

Push fixes to `main` once repository access is connected; CI handles subsequent release builds and deployment. This does not push changes onto a PC while the game is running: it updates the next time the desktop launcher opens.

## Boundaries

The launcher updates game binaries and data. Its own executable and manifest format are deliberately stable in v1; a future incompatible launcher change would need a separate one-time launcher upgrade. Older installed versions are retained rather than silently deleted. The updater trusts this GitHub repository over HTTPS and checks artifact hashes; it does not use a separate publisher signing key.

Windows runtime tests are defined in CI but must actually run successfully before publication. A local Linux cross-build alone does not establish Windows installation or shortcut behavior.
