"""Exercise the OXWM installer with package and system commands mocked."""
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "core/tabs/system-setup/desktop-environments.sh"


def installer_function():
    source = SCRIPT.read_text()
    return re.search(
        r"^installOxwmFromSource\(\) \{\n.*?^\}",
        source,
        re.M | re.S,
    ).group()


def run_installer(manager="apt-get", version="0.16.0", has_zig=True, fail_build=False):
    harness = installer_function() + r"""
install_packages() { printf 'PACKAGES:%s\n' "$*"; }
command_exists() { [ "$HAS_ZIG" = 1 ] && [ "$1" = zig ]; }
zig() {
  if [ "$1" = version ]; then
    printf '%s\n' "$ZIG_VERSION"
    return 0
  fi
  [ "$FAIL_BUILD" = 0 ] || return 1
  while [ "$#" -gt 0 ]; do
    if [ "$1" = --prefix ]; then
      shift
      mkdir -p "$1/bin"
      : > "$1/bin/oxwm"
      chmod +x "$1/bin/oxwm"
      return 0
    fi
    shift
  done
  return 2
}
git() { mkdir -p "$7"; }
mock_escalate() {
  printf 'INSTALL:%s\n' "$*"
  if [ "$6" = /usr/share/xsessions/oxwm.desktop ]; then
    printf 'SESSION_CONTENT_BEGIN\n'
    cat "$5"
    printf 'SESSION_CONTENT_END\n'
  fi
}
PACKAGER=$MANAGER
ESCALATION_TOOL=mock_escalate
installOxwmFromSource
"""
    return subprocess.run(
        ["sh", "-e", "-c", harness],
        capture_output=True,
        text=True,
        timeout=5,
        env={
            "PATH": "/usr/bin:/bin",
            "MANAGER": manager,
            "ZIG_VERSION": version,
            "HAS_ZIG": "1" if has_zig else "0",
            "FAIL_BUILD": "1" if fail_build else "0",
        },
    )


class OxwmInstallerTests(unittest.TestCase):
    def test_dispatches_build_dependencies_without_requiring_a_zig_package(self):
        packages = {
            "apt-get": "libx11-dev",
            "nala": "libx11-dev",
            "dnf": "libX11-devel",
            "zypper": "libX11-devel",
        }
        for manager, package in packages.items():
            with self.subTest(manager=manager):
                result = run_installer(manager=manager)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn(f"PACKAGES:{manager}", result.stdout)
                self.assertIn(package, result.stdout)
                self.assertNotRegex(result.stdout, r"(?<!\S)zig(?!\S)")

    def test_requires_a_suitable_preinstalled_zig_before_package_changes(self):
        for options, message in (
            ({"has_zig": False}, "requires Zig 0.16.0 or newer"),
            ({"version": "0.15.2"}, "found 0.15.2"),
        ):
            with self.subTest(options=options):
                result = run_installer(**options)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(message, result.stdout)
                self.assertNotIn("PACKAGES:", result.stdout)
                self.assertNotIn("INSTALL:", result.stdout)

    def test_build_failure_does_not_install_system_files(self):
        result = run_installer(fail_build=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("INSTALL:", result.stdout)

    def test_success_installs_the_binary_and_desktop_session(self):
        result = run_installer()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertRegex(result.stdout, r"INSTALL:install -D -m 755 .*/bin/oxwm /usr/bin/oxwm")
        self.assertRegex(result.stdout, r"INSTALL:install -D -m 644 .*/oxwm\.desktop /usr/share/xsessions/oxwm\.desktop")
        self.assertIn("SESSION_CONTENT_BEGIN\n[Desktop Entry]\nName=OXWM\nComment=OXWM window manager\nExec=oxwm\nType=Application\nSESSION_CONTENT_END", result.stdout)


if __name__ == "__main__":
    unittest.main()
