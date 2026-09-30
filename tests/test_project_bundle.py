from __future__ import annotations

import hashlib
import json
from pathlib import Path
import tempfile
import unittest
import zipfile

from tools.maintenance import project_bundle as bundle


def _sha(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


class ProjectBundleSecurityTests(unittest.TestCase):
    def make_package_with_entry(self, package_dir: Path, entry_path: str, payload: bytes) -> None:
        project_zip = package_dir / "project.zip"
        history_bundle = package_dir / "history.bundle"
        manifest = package_dir / "manifest.json"

        history_bundle.write_bytes(b"fake-history")
        with zipfile.ZipFile(project_zip, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            archive.writestr(entry_path, payload)

        manifest.write_text(
            json.dumps(
                {
                    "entries": [
                        {
                            "path": entry_path,
                            "sha256": hashlib.sha256(payload).hexdigest(),
                            "size": len(payload),
                        }
                    ],
                    "project_zip_sha256": _sha(project_zip),
                    "history_bundle_sha256": _sha(history_bundle),
                    "directories": [],
                    "excluded": ["Git administration (.git)", "snapshot"],
                    "head": "deadbeef",
                }
            ),
            encoding="utf-8",
        )

    def test_verify_rejects_parent_traversal_archive_path(self):
        with tempfile.TemporaryDirectory() as folder:
            package_dir = Path(folder)
            self.make_package_with_entry(package_dir, "../escape.txt", b"payload")

            with self.assertRaisesRegex(ValueError, "Unsafe snapshot path"):
                bundle.verify(package_dir)

    def test_restore_refuses_existing_destination(self):
        with tempfile.TemporaryDirectory() as folder:
            package_dir = Path(folder) / "package"
            package_dir.mkdir()
            destination = Path(folder) / "existing"
            destination.mkdir()

            with self.assertRaises(FileExistsError):
                bundle.restore(package_dir, destination)


if __name__ == "__main__":
    unittest.main(verbosity=2)
