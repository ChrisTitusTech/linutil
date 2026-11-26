"""Exercise SomeWM package selection without installing packages or building."""
from pathlib import Path
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "core/tabs/system-setup/desktop-environments.sh"


def installer_function():
    source = SCRIPT.read_text()
    return re.search(
        r"^installSomewmFromSource\(\) \{\n.*?^\}",
        source,
        re.M | re.S,
    ).group()


class SomewmInstallerTests(unittest.TestCase):
    def test_fedora_installs_lua_lgi_compatible_with_luajit(self):
        harness = installer_function() + r"""
install_packages() { printf 'PACKAGES:%s\n' "$*"; }
git() {
  while [ "$#" -gt 0 ]; do
    destination=$1
    shift
  done
  mkdir -p "$destination"
}
make() { :; }
mock_escalate() { :; }
PACKAGER=dnf
ESCALATION_TOOL=mock_escalate
installSomewmFromSource
"""
        result = subprocess.run(
            ["sh", "-e", "-c", harness],
            capture_output=True,
            text=True,
            timeout=5,
            env={"PATH": "/usr/bin:/bin"},
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        packages = next(line for line in result.stdout.splitlines() if line.startswith("PACKAGES:"))
        self.assertIn("lua-lgi-compat", packages.split())
        self.assertNotIn("lua-lgi", packages.split())


if __name__ == "__main__":
    unittest.main()
