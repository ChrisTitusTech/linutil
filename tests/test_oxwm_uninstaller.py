"""Exercise OXWM uninstall dispatch without removing system files or packages."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "core/tabs/system-setup/desktop-environments-uninstall.sh"


def function(name):
    source = SCRIPT.read_text()
    return re.search(
        r"^" + re.escape(name) + r"\(\) \{\n.*?^\}",
        source,
        re.M | re.S,
    ).group()


def run_uninstaller(manager):
    harness = function("uninstall_desktop") + r"""
uninstall_packages() { printf 'PACKAGE_REMOVE:%s\n' "$*"; }
mock_escalate() { printf 'ESCALATE:%s\n' "$*"; }
ESCALATION_TOOL=mock_escalate
AUR_HELPER=mock_aur
uninstall_desktop "$MANAGER" OXWM
"""
    home = tempfile.TemporaryDirectory()
    result = subprocess.run(
        ["sh", "-e", "-c", harness],
        capture_output=True,
        text=True,
        timeout=5,
        env={"PATH": "/usr/bin:/bin", "MANAGER": manager, "HOME": home.name},
    )
    home.cleanup()
    return result


def run_source_miracle_uninstaller(marker):
    source = function("uninstall_desktop").replace(
        "/var/lib/linutil/miracle-wm/source-install",
        str(marker),
    )
    harness = source + r"""
uninstall_packages() { printf 'PACKAGE_REMOVE:%s\n' "$*"; }
mock_escalate() { printf 'ESCALATE:%s\n' "$*"; }
ESCALATION_TOOL=mock_escalate
AUR_HELPER=mock_aur
uninstall_desktop apt-get Miracle-WM
"""
    return subprocess.run(
        ["sh", "-e", "-c", harness],
        capture_output=True,
        text=True,
        timeout=5,
        env={"PATH": "/usr/bin:/bin", "HOME": str(marker.parent)},
    )


class OxwmUninstallerTests(unittest.TestCase):
    def test_source_installs_remove_only_oxwm_files(self):
        for manager in ("apt-get", "nala", "dnf", "zypper"):
            with self.subTest(manager=manager):
                result = run_uninstaller(manager)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("ESCALATE:rm -f /usr/bin/oxwm", result.stdout)
                self.assertIn(
                    "ESCALATE:rm -f /usr/share/xsessions/oxwm.desktop",
                    result.stdout,
                )
                self.assertNotIn("PACKAGE_REMOVE:", result.stdout)
                self.assertNotIn("autoremove", result.stdout)

    def test_arch_install_removes_the_aur_package(self):
        result = run_uninstaller("pacman")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("PACKAGE_REMOVE:pacman oxwm-git", result.stdout)
        self.assertNotIn("ESCALATE:rm -f /usr/bin/oxwm", result.stdout)

    def test_oxwm_is_detected_and_offered_by_the_menu(self):
        main = function("main")
        harness = main + r"""
is_installed() { [ "$3" = oxwm ]; }
readMenuChoice() { read -r "$1"; }
uninstall_desktop() { printf 'UNINSTALL:%s:%s\n' "$1" "$2"; }
PACKAGER=apt-get
main
"""
        result = subprocess.run(
            ["sh", "-e", "-c", harness],
            input="1\n",
            capture_output=True,
            text=True,
            timeout=5,
            env={"PATH": "/usr/bin:/bin"},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("1) OXWM", result.stdout)
        self.assertIn("UNINSTALL:apt-get:OXWM", result.stdout)

    def test_source_miracle_wm_installation_removes_only_its_files(self):
        with tempfile.TemporaryDirectory() as directory:
            marker = Path(directory) / "source-install"
            marker.touch()
            result = run_source_miracle_uninstaller(marker)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(
            "ESCALATE:rm -rf /opt/linutil/miracle-wm /var/lib/linutil/miracle-wm",
            result.stdout,
        )
        self.assertIn(
            "usr/local/lib/systemd/user/miracle-wm-session.target",
            result.stdout,
        )
        self.assertIn("ESCALATE:ldconfig", result.stdout)
        self.assertNotIn("PACKAGE_REMOVE:", result.stdout)


if __name__ == "__main__":
    unittest.main()
