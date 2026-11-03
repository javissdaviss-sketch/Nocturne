#!/usr/bin/env python3
"""Build reproducible Windows game/update/setup artifacts with no Python dependencies."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = re.compile(r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\Z")
REPOSITORY = re.compile(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+\Z")
NOTICES = ["README.md", "THIRD_PARTY_NOTICES.txt", "GODOT_COPYRIGHT.txt", "GO_LICENSE.txt", "VALIDATION.md", "UPDATES.md"]


def archive(destination: Path, files: list[tuple[Path, str]]) -> None:
    with zipfile.ZipFile(destination, "w", zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        for source, name in sorted(files, key=lambda pair: pair[1]):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            z.writestr(info, source.read_bytes())
    with zipfile.ZipFile(destination) as z:
        if z.testzip() is not None:
            raise RuntimeError(f"ZIP validation failed: {destination.name}")


def manifest_for(game: Path, version: str, repository: str) -> dict:
    if not VERSION.fullmatch(version) or not REPOSITORY.fullmatch(repository):
        raise ValueError("Expected a numeric x.y.z version and owner/repository")
    return {"schema": 1, "version": version,
            "url": f"https://github.com/{repository}/releases/download/v{version}/Nocturne-Windows.zip",
            "sha256": hashlib.sha256(game.read_bytes()).hexdigest(), "bytes": game.stat().st_size}


def build(out: Path, version: str, repository: str, godot: str, go: str) -> None:
    if not VERSION.fullmatch(version) or not REPOSITORY.fullmatch(repository):
        raise ValueError("Invalid version or repository")
    out = out.resolve()
    out.mkdir(parents=True, exist_ok=True)
    staging = out / "staging"
    if staging.exists():
        shutil.rmtree(staging)
    (staging / "windows").mkdir(parents=True)
    project_path = ROOT / "project.godot"
    presets_path = ROOT / "export_presets.cfg"
    original_project, original_presets = project_path.read_text(), presets_path.read_text()
    try:
        project_path.write_text(re.sub(r'config/version="[^"]+"', f'config/version="{version}"', original_project))
        presets_path.write_text(re.sub(r'application/(file|product)_version="[^"]+"',
            lambda m: f'application/{m.group(1)}_version="{version}.0"', original_presets))
        subprocess.run([godot, "--headless", "--path", str(ROOT), "--editor", "--import", "--quit"], check=True)
        subprocess.run([godot, "--headless", "--path", str(ROOT), "--export-release", "Windows Desktop", str(staging / "windows" / "Nocturne.exe")], check=True)
    finally:
        project_path.write_text(original_project)
        presets_path.write_text(original_presets)
    exe = staging / "windows" / "Nocturne.exe"
    if not exe.exists() or exe.open("rb").read(2) != b"MZ":
        raise RuntimeError("Windows export is missing or invalid")
    game = out / "Nocturne-Windows.zip"
    files = [(exe, "Nocturne/Nocturne.exe")]
    files += [(ROOT / name, "Nocturne/" + name) for name in NOTICES if (ROOT / name).exists()]
    archive(game, files)
    manifest = manifest_for(game, version, repository)
    (out / "update.json").write_text(json.dumps(manifest, indent=2) + "\n")
    setup = staging / "setup"
    (setup / "payload").mkdir(parents=True)
    shutil.copy2(game, setup / "payload" / game.name)
    shutil.copy2(out / "update.json", setup / "payload" / "update.json")
    (setup / "launcher.json").write_text(json.dumps({"schema": 1,
        "manifest_url": f"https://github.com/{repository}/releases/latest/download/update.json"}, indent=2) + "\n")
    environment = dict(os.environ, GOOS="windows", GOARCH="amd64", CGO_ENABLED="0", GOTOOLCHAIN="local")
    subprocess.run([go, "build", "-buildvcs=false", "-trimpath", "-ldflags=-s -w", "-o", str(setup / "Nocturne-Launcher.exe"), "."], cwd=ROOT / "launcher", env=environment, check=True)
    (setup / "Install-Nocturne.cmd").write_text('@echo off\r\ncd /d "%~dp0"\r\n"%~dp0Nocturne-Launcher.exe" --install\r\nif errorlevel 1 pause\r\n')
    shutil.copy2(ROOT / "pipeline" / "INSTALL.txt", setup / "READ-ME-FIRST.txt")
    for name in NOTICES:
        if (ROOT / name).exists(): shutil.copy2(ROOT / name, setup / name)
    archive(out / "Nocturne-Setup-Windows.zip", [(p, "Nocturne-Setup/" + p.relative_to(setup).as_posix()) for p in setup.rglob("*") if p.is_file()])
    # Source includes workflow and launcher, but never build output or local state.
    ignored = {".git", ".godot", ".release", "__pycache__"}
    source_files = []
    for p in ROOT.rglob("*"):
        rel = p.relative_to(ROOT)
        if p.is_file() and not any(part in ignored for part in rel.parts) and not p.is_relative_to(out):
            source_files.append((p, "night-train/" + rel.as_posix()))
    archive(out / "Nocturne-Source.zip", source_files)
    names = ["Nocturne-Windows.zip", "Nocturne-Setup-Windows.zip", "Nocturne-Source.zip", "update.json"]
    (out / "SHA256SUMS.txt").write_text("".join(hashlib.sha256((out / name).read_bytes()).hexdigest() + "  " + name + "\n" for name in names))
    print(f"Built Nocturne {version}: " + ", ".join(names))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=ROOT / ".release")
    parser.add_argument("--version", default="0.1.1")
    parser.add_argument("--repository", default="javissdaviss-sketch/Nocturne")
    parser.add_argument("--godot", default=os.environ.get("GODOT", "godot"))
    parser.add_argument("--go", default=os.environ.get("GO", "go"))
    args = parser.parse_args()
    build(args.out, args.version, args.repository, args.godot, args.go)

if __name__ == "__main__": main()
