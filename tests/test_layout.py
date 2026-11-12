"""No third-party Python packages required for repository integrity tests."""

import json
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def read(self, name):
        return (ROOT / name).read_text(encoding="utf-8")

    def test_opencode_json_valid(self):
        cfg = json.loads(self.read("config/opencode.json"))
        self.assertEqual(cfg["$schema"], "https://opencode.ai/config.json")
        self.assertEqual(cfg["update"], "notify")

    def test_profiles_match_docker_targets(self):
        dockerfile = self.read("Dockerfile")
        for target in ("minimal", "web", "browser", "full"):
            self.assertRegex(dockerfile, rf"(?m)^FROM .+ AS {target}$")
        self.assertIn("ghcr.io/anomalyco/opencode:${OPENCODE_VERSION}", dockerfile)
        self.assertIn("USER devkit", dockerfile)

    def test_env_has_no_committed_password(self):
        env = self.read(".env.example")
        self.assertRegex(env, r"(?m)^OPENCODE_PASSWORD=$")
        self.assertIn("DEVKIT_PROFILE=browser", env)
        self.assertIn("OPENCODE_BIND=127.0.0.1", env)
        self.assertIn(".env", self.read(".gitignore"))

    def test_persistence_mount_targets_unique(self):
        compose = self.read("compose.yaml")
        mounts = re.findall(r"(?m)^\s+target:\s+(/[^\s]+)", compose)
        mounts += re.findall(r"(?m)^\s+-\s+devkit-[a-z]+:(/[^\s]+)", compose)
        self.assertEqual(len(mounts), len(set(mounts)), "duplicate bind/volume targets")
        for path in (
            "/workspace", "/home/devkit/.config", "/home/devkit/.local/share",
            "/home/devkit/.local/state", "/home/devkit/.cache",
            "/home/devkit/.npm", "/home/devkit/.agent-browser",
        ):
            self.assertIn(path, mounts)
        self.assertNotIn("/var/run/docker.sock", compose)
        self.assertIn("127.0.0.1", compose)

    def test_persistence_test_actually_recreates(self):
        script = self.read("scripts/persistence-test.sh")
        self.assertIn("--force-recreate", script)
        self.assertIn("/workspace/.devkit-recreate-test", script)
        self.assertIn("/.devkit-recreate-test", script)

    def test_referenced_docs_exist(self):
        readme = self.read("README.md")
        for link in re.findall(r"\]\(((?:docs/|CONTRIBUTING|SECURITY|LICENSE)[^)]+)\)", readme):
            self.assertTrue((ROOT / link).exists(), link)

    def test_scripts_present(self):
        for file in (
            "init.sh", "entrypoint.sh", "backup.sh", "restore.sh",
            "smoke.sh", "persistence-test.sh", "doctor.sh", "publish-github.sh",
        ):
            p = ROOT / "scripts" / file
            self.assertTrue(p.exists(), file)
            self.assertTrue(p.stat().st_mode & 0o111, f"{file} should be executable")


if __name__ == "__main__":
    unittest.main()
