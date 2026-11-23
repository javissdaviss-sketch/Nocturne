#!/usr/bin/env python3
"""Publish a complete release only after verifying its assets; never replace a release."""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import subprocess
import zipfile
from build import VERSION, REPOSITORY, is_raw_reference

ASSETS = ["Nocturne-Windows.zip", "Nocturne-Setup-Windows.zip", "Nocturne-Source.zip", "update.json", "SHA256SUMS.txt"]

def verify(directory: Path, version: str, repository: str) -> None:
    if not VERSION.fullmatch(version) or not REPOSITORY.fullmatch(repository): raise ValueError("Invalid version or repository")
    manifest = json.loads((directory / "update.json").read_text())
    game = directory / "Nocturne-Windows.zip"
    if manifest != {"schema": 1, "version": version,
            "url": f"https://github.com/{repository}/releases/download/v{version}/Nocturne-Windows.zip",
            "sha256": hashlib.sha256(game.read_bytes()).hexdigest(), "bytes": game.stat().st_size}:
        raise ValueError("Manifest does not match the exact release artifact")
    sums = {}
    for line in (directory / "SHA256SUMS.txt").read_text().splitlines():
        checksum, name = line.split("  ", 1)
        if name not in ASSETS or name == "SHA256SUMS.txt": raise ValueError("Unexpected checksum entry")
        sums[name] = checksum
    for name in ASSETS:
        path = directory / name
        if not path.is_file(): raise ValueError(f"Missing release asset: {name}")
        if name != "SHA256SUMS.txt" and sums.get(name) != hashlib.sha256(path.read_bytes()).hexdigest():
            raise ValueError(f"Checksum mismatch: {name}")
    verify_source_archive(directory / "Nocturne-Source.zip")

def verify_source_archive(path: Path) -> None:
    try:
        with zipfile.ZipFile(path) as archive:
            members = archive.namelist()
            if (not members or len(members) != len(set(members)) or archive.testzip() is not None):
                raise ValueError("Invalid source archive")
            for name in members:
                relative = PurePosixPath(name)
                if (len(relative.parts) < 2 or relative.parts[0] != "night-train"
                        or ".." in relative.parts or "\\" in name
                        or is_raw_reference(PurePosixPath(*relative.parts[1:]))):
                    raise ValueError(f"Unpublishable source path: {name}")
    except zipfile.BadZipFile as error:
        raise ValueError("Invalid source archive") from error


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--directory", type=Path, required=True)
    p.add_argument("--version", required=True)
    p.add_argument("--repository", required=True)
    p.add_argument("--commit", required=True)
    a = p.parse_args()
    verify(a.directory, a.version, a.repository)
    tag = "v" + a.version
    # Publishing an existing tag is deliberately rejected; releases are immutable.
    existing = subprocess.run(["gh", "release", "view", tag, "--repo", a.repository], capture_output=True)
    if existing.returncode == 0: raise SystemExit("Release already exists; use a new version")
    subprocess.run(["gh", "release", "create", tag, "--repo", a.repository, "--target", a.commit,
        "--draft", "--title", "Fly Spy With My Little Eye " + a.version,
        "--notes", "Tested Windows build. Existing Nocturne desktop launchers update automatically on their next launch. New players: download Nocturne-Setup-Windows.zip."], check=True)
    subprocess.run(["gh", "release", "upload", tag, "--repo", a.repository] + [str(a.directory / name) for name in ASSETS], check=True)
    subprocess.run(["gh", "release", "edit", tag, "--repo", a.repository, "--draft=false", "--latest"], check=True)
    print(f"Published https://github.com/{a.repository}/releases/tag/{tag}")

if __name__ == "__main__": main()
