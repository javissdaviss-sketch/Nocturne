import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from build import manifest_for, archive, source_entries
from publish import verify

class ReleaseTests(unittest.TestCase):
    def fixture(self, directory):
        files = {"Nocturne-Windows.zip": b"game bytes", "Nocturne-Setup-Windows.zip": b"setup bytes", "Nocturne-Source.zip": b"source bytes"}
        for name, data in files.items():
            (directory / name).write_bytes(data)
        source = directory / "source.gd"
        source.write_text("extends Node")
        archive(directory / "Nocturne-Source.zip", [(source, "night-train/scripts/source.gd")])
        manifest = manifest_for(directory / "Nocturne-Windows.zip", "0.1.2", "owner/Nocturne")
        (directory / "update.json").write_text(json.dumps(manifest))
        names = list(files) + ["update.json"]
        (directory / "SHA256SUMS.txt").write_text("".join(hashlib.sha256((directory / n).read_bytes()).hexdigest() + "  " + n + "\n" for n in names))

    def test_release_verifies(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); self.fixture(root)
            verify(root, "0.1.2", "owner/Nocturne")

    def test_manifest_and_artifact_tampering_rejected(self):
        for name in ["Nocturne-Windows.zip", "Nocturne-Setup-Windows.zip", "Nocturne-Source.zip", "update.json"]:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as d:
                root = Path(d); self.fixture(root)
                (root / name).write_bytes(b"corrupt")
                with self.assertRaises((ValueError, json.JSONDecodeError)):
                    verify(root, "0.1.2", "owner/Nocturne")

    def test_wrong_repository_and_version_rejected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); self.fixture(root)
            for version, repo in [("0.1.3", "owner/Nocturne"), ("0.1.2", "other/Nocturne"), ("../oops", "owner/Nocturne")]:
                with self.assertRaises(ValueError): verify(root, version, repo)

    def test_source_references_not_collected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            out = root / "dist"
            hidden = ["art/references/board.jpg", "art/references/board.jpg.import",
                      "art/reference/nested/board.jpg", ".godot/imported/board.ctex", "dist/build.exe"]
            kept = ["art/ROOM_DIRECTION.md", "assets/textures/atlas.png", "scripts/entry.gd"]
            for rel in hidden + kept:
                path = root / rel
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b"fixture")
            self.assertEqual({name for _, name in source_entries(root, out)}, {"night-train/"+rel for rel in kept})

    def test_publication_rejects_reference_even_with_valid_checksums(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); self.fixture(root)
            source_zip = root / "Nocturne-Source.zip"
            archive(source_zip, [(root / "source.gd", "night-train/art/references/board.jpg")])
            sums = root / "SHA256SUMS.txt"
            rows = [line for line in sums.read_text().splitlines() if not line.endswith("  Nocturne-Source.zip")]
            rows.append(hashlib.sha256(source_zip.read_bytes()).hexdigest() + "  Nocturne-Source.zip")
            sums.write_text("\n".join(rows)+"\n")
            with self.assertRaisesRegex(ValueError, "Unpublishable source path"):
                verify(root, "0.1.2", "owner/Nocturne")

    def test_archive_reproducible(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); source = root / "game.exe"; source.write_bytes(b"MZ game")
            archive(root / "a.zip", [(source, "Nocturne/Nocturne.exe")])
            archive(root / "b.zip", [(source, "Nocturne/Nocturne.exe")])
            self.assertEqual((root / "a.zip").read_bytes(), (root / "b.zip").read_bytes())

if __name__ == "__main__": unittest.main()
