"""Exercise Miracle-WM menu dispatch without changing the system."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "core/tabs/system-setup/desktop-environments.sh"


def run_menu(
    manager,
    distro="fedora",
    codename="resolute",
    id_like="",
    fail_install=False,
    fail_ldconfig=False,
):
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
  DTYPE=$TEST_DISTRO
  VERSION_CODENAME=$TEST_CODENAME
  ID_LIKE=$TEST_ID_LIKE
}
readMenuChoice() { read -r "$@"; }
command_exists() {
  [ "$1" = add-apt-repository ] || command -v "$1" >/dev/null 2>&1
}
mock_escalate() {
  printf 'INSTALL:%s\\n' "$*"
  if [ "$1" = cp ] && [ -f "$3/bin/linutil-miracle-wm-session" ]; then
    printf 'WRAPPER_CONTENT_BEGIN\\n'
    cat "$3/bin/linutil-miracle-wm-session"
    printf 'WRAPPER_CONTENT_END\\n'
  fi
  if [ "$1" = install ] && [ "$6" = /usr/share/wayland-sessions/linutil-miracle-wm.desktop ]; then
    printf 'SESSION_CONTENT_BEGIN\\n'
    cat "$5"
    printf 'SESSION_CONTENT_END\\n'
  fi
  if [ "$1" = install ] && [ "$6" = /var/lib/linutil/miracle-wm/source-install ]; then
    printf 'MARKER_CONTENT_BEGIN\\n'
    cat "$5"
    printf 'MARKER_CONTENT_END\\n'
  fi
  if [ "$1" = ldconfig ] && [ "$FAIL_LDCONFIG" = 1 ]; then
    FAIL_LDCONFIG=0
    return 1
  fi
  [ "$FAIL_INSTALL" = 0 ]
}
paru() { printf 'AUR:%s\\n' "$*"; }
git() {
  printf 'GIT:%s\\n' "$*"
  if [ "$1" = clone ]; then
    while [ "$#" -gt 0 ]; do
      destination=$1
      shift
    done
    mkdir -p "$destination"
  fi
}
cmake() {
  printf 'CMAKE:%s\\n' "$*"
  if [ "$1" = --install ]; then
    mkdir -p "$DESTDIR/opt/linutil/miracle-wm/lib/pkgconfig"
    mkdir -p "$DESTDIR/opt/linutil/miracle-wm/bin"
    mkdir -p "$DESTDIR/opt/linutil/miracle-wm/share/wayland-sessions"
    mkdir -p "$DESTDIR/opt/linutil/miracle-wm/lib/systemd/user"
    printf 'prefix=/opt/linutil/miracle-wm\\n' \
      > "$DESTDIR/opt/linutil/miracle-wm/lib/pkgconfig/miral.pc"
    : > "$DESTDIR/opt/linutil/miracle-wm/bin/miracle-wm-session"
    chmod +x "$DESTDIR/opt/linutil/miracle-wm/bin/miracle-wm-session"
    printf '[Desktop Entry]\\nExec=/opt/linutil/miracle-wm/bin/miracle-wm-session\\n' \
      > "$DESTDIR/opt/linutil/miracle-wm/share/wayland-sessions/miracle-wm.desktop"
    : > "$DESTDIR/opt/linutil/miracle-wm/lib/systemd/user/miracle-wm-session.target"
    : > "$DESTDIR/opt/linutil/miracle-wm/lib/systemd/user/miracle-wm-session-shutdown.target"
    : > "$DESTDIR/opt/linutil/miracle-wm/lib/systemd/user/miracle-wm-xdg-autostart.target"
  fi
}
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
                 "TEST_DISTRO": distro, "TEST_CODENAME": codename,
                 "TEST_ID_LIKE": id_like,
                 "FAIL_INSTALL": "1" if fail_install else "0",
                 "FAIL_LDCONFIG": "1" if fail_ldconfig else "0"},
        )


class MiracleWmInstallerTests(unittest.TestCase):
    def test_ubuntu_apt_routes_configure_upstream_repositories(self):
        for manager in ("apt-get", "nala"):
            with self.subTest(manager=manager):
                result = run_menu(manager, distro="ubuntu")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("add-apt-repository -y ppa:mir-team/release\n", result.stdout)
                self.assertIn("add-apt-repository -y ppa:matthew-kosarek/miracle-wm\n", result.stdout)
                self.assertIn(f"INSTALL:{manager} install -y miracle-wm\n", result.stdout)
                self.assertNotIn("Unsupported window manager", result.stdout)

    def test_debian_apt_routes_build_miracle_wm_without_ubuntu_ppas(self):
        for manager in ("apt-get", "nala"):
            with self.subTest(manager=manager):
                result = run_menu(manager, distro="debian", id_like="debian")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("GIT:clone --depth 1 --branch v2.21.0 https://github.com/canonical/mir.git", result.stdout)
                self.assertIn("GIT:clone --depth 1 --branch v0.11.2 https://github.com/miracle-wm-org/miracle-wm.git", result.stdout)
                self.assertIn(
                    "Miracle-WM source build v0.11.2 with Mir v2.21.0 (MirAL 5.4.0)",
                    result.stdout,
                )
                self.assertIn("apt-get build-dep -y ./", result.stdout)
                self.assertIn("without its optional WasmEdge plugin system", result.stdout)
                self.assertIn("-DSYSTEMD_INTEGRATION=ON", result.stdout)
                self.assertIn(
                    "Exec=/opt/linutil/miracle-wm/bin/linutil-miracle-wm-session",
                    result.stdout,
                )
                self.assertIn(
                    'PATH="/opt/linutil/miracle-wm/bin:$PATH"\n'
                    "export PATH\n"
                    'exec "/opt/linutil/miracle-wm/bin/miracle-wm-session" "$@"',
                    result.stdout,
                )
                self.assertNotIn("ppa:", result.stdout)

    def test_unsupported_ubuntu_release_fails_before_adding_a_ppa(self):
        result = run_menu("nala", distro="ubuntu", codename="noble")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("only supported on Ubuntu questing and resolute", result.stdout)
        self.assertNotIn("add-apt-repository", result.stdout)

    def test_native_routes_are_limited_to_documented_distributions(self):
        result = run_menu("dnf", distro="fedora")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("INSTALL:dnf install -y miracle-wm\n", result.stdout)

        result = run_menu("zypper", distro="opensuse")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Miracle-WM is unsupported", result.stdout)
        self.assertNotIn("install -y miracle-wm", result.stdout)

    def test_pacman_keeps_aur_route(self):
        result = run_menu("pacman", distro="arch")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("AUR:-S --needed --noconfirm miracle-wm\n", result.stdout)

    def test_package_failure_is_propagated(self):
        result = run_menu("dnf", distro="fedora", fail_install=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("INSTALL:dnf install -y miracle-wm\n", result.stdout)

    def test_ldconfig_failure_rolls_back_wrapper_before_removing_marker(self):
        result = run_menu("nala", distro="debian", id_like="debian", fail_ldconfig=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("WRAPPER_CONTENT_BEGIN", result.stdout)
        self.assertIn("INSTALL:rm -rf /opt/linutil/miracle-wm\n", result.stdout)

        cleanup_steps = (
            "INSTALL:rm -rf /opt/linutil/miracle-wm",
            "INSTALL:rm -f /etc/ld.so.conf.d/linutil-miracle-wm.conf",
            "INSTALL:ldconfig",
            "INSTALL:rm -rf /var/lib/linutil/miracle-wm",
        )
        positions = [result.stdout.rfind(step) for step in cleanup_steps]
        self.assertTrue(all(position >= 0 for position in positions), result.stdout)
        self.assertEqual(positions, sorted(positions), result.stdout)


if __name__ == "__main__":
    unittest.main()
