"""Local build parity tests, no GitHub Actions required."""
import json
import tempfile
import unittest
from pathlib import Path
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/"scripts"))
from build_variants import build

class Variants(unittest.TestCase):
    def test_byte_identical_core_and_dev_only_extras(self):
        with tempfile.TemporaryDirectory() as tmp:
            root=Path(tmp)
            for addon in ("KordRotation","KordRotationDevTools"):
                (root/addon).mkdir()
                (root/addon/(addon+".toc")).write_bytes(b"## Interface: 16001\n")
            (root/"KordRotation"/"Core.lua").write_bytes(b"a\r\nb\x00")
            (root/"KordRotationDevTools"/"Trace.lua").write_bytes(b"diagnostic")
            manifest=build(root,root/"dist")
            from zipfile import ZipFile
            with ZipFile(root/"dist/KordRotation-user.zip") as user, ZipFile(root/"dist/KordRotation-dev.zip") as dev:
                self.assertEqual(user.read("KordRotation/Core.lua"),dev.read("KordRotation/Core.lua"))
                self.assertNotIn("KordRotationDevTools/Trace.lua",user.namelist())
                self.assertIn("KordRotationDevTools/Trace.lua",dev.namelist())
            self.assertEqual(manifest["core_files"],2)
            saved=json.loads((root/"dist/build-manifest.json").read_text(encoding="utf-8"))
            self.assertEqual(len(saved["core_sha256"]),2)

if __name__=="__main__":
    unittest.main()
