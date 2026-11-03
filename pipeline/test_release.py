import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from build import manifest_for, archive
from publish import verify

class ReleaseTests(unittest.TestCase):
    def fixture(self, directory):
        files = {"Nocturne-Windows.zip": b"game bytes", "Nocturne-Setup-Windows.zip": b"setup bytes", "Nocturne-Source.zip": b"source bytes"}
        for name, data in files.items(): (directory / name).write_bytes(data)
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

    def test_archive_reproducible(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d); source = root / "game.exe"; source.write_bytes(b"MZ game")
            archive(root / "a.zip", [(source, "Nocturne/Nocturne.exe")])
            archive(root / "b.zip", [(source, "Nocturne/Nocturne.exe")])
            self.assertEqual((root / "a.zip").read_bytes(), (root / "b.zip").read_bytes())

if __name__ == "__main__": unittest.main()
