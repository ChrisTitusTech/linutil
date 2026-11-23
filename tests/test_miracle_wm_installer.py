"""Exercise Miracle-WM menu dispatch without changing the system."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "core/tabs/system-setup/desktop-environments.sh"


def run_menu(manager, fail_install=False):
    with tempfile.TemporaryDirectory() as directory:
        tabs = Path(directory)
        script_dir = tabs / "system-setup"
        script_dir.mkdir()
        script = script_dir / SCRIPT.name
        shutil.copyfile(SCRIPT, script)
        (tabs / "common-script.sh").write_text(
            """\
checkEnv() {
  PACKAGER=$TEST_PACKAGER
  ESCALATION_TOOL=mock_escalate
  AUR_HELPER=paru
}
readMenuChoice() { read -r "$@"; }
mock_escalate() {
  printf 'INSTALL:%s\\n' "$*"
  [ "$FAIL_INSTALL" = 0 ]
}
paru() { printf 'AUR:%s\\n' "$*"; }
"""
        )
        return subprocess.run(
            ["sh", "-e", str(script)],
            cwd=script_dir,
            input="2\n10\n",
            capture_output=True,
            text=True,
            timeout=5,
            env={**os.environ, "TEST_PACKAGER": manager,
                 "FAIL_INSTALL": "1" if fail_install else "0"},
        )


class MiracleWmInstallerTests(unittest.TestCase):
    def test_native_package_routes(self):
        for manager in ("apt-get", "nala", "dnf", "zypper"):
            with self.subTest(manager=manager):
                result = run_menu(manager)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"INSTALL:{manager} install -y miracle-wm\n", result.stdout)
                self.assertNotIn("Unsupported window manager", result.stdout)

    def test_pacman_keeps_aur_route(self):
        result = run_menu("pacman")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("AUR:-S --needed --noconfirm miracle-wm\n", result.stdout)

    def test_package_failure_is_propagated(self):
        result = run_menu("dnf", fail_install=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("INSTALL:dnf install -y miracle-wm\n", result.stdout)


if __name__ == "__main__":
    unittest.main()
