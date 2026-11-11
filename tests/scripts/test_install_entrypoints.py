"""Entrypoint dispatch checks; installation and AI-removal functions are mocked."""
from pathlib import Path
import re
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[2]
ENTRYPOINTS = {'core/tabs/applications-setup/browsers/brave-origin.sh': 'installBraveOrigin',
 'core/tabs/applications-setup/browsers/google-chrome.sh': 'installChrome',
 'core/tabs/applications-setup/browsers/helium-browser.sh': 'installHeliumBrowser',
 'core/tabs/applications-setup/dank-shell.sh': 'installDank',
 'core/tabs/applications-setup/design-tools/ardour.sh': 'installArdour',
 'core/tabs/applications-setup/design-tools/audacity.sh': 'installAudacity',
 'core/tabs/applications-setup/design-tools/blender.sh': 'installBlender',
 'core/tabs/applications-setup/design-tools/darktable.sh': 'installDarktable',
 'core/tabs/applications-setup/design-tools/gimp.sh': 'installGIMP',
 'core/tabs/applications-setup/design-tools/handbrake.sh': 'installHandbrake',
 'core/tabs/applications-setup/design-tools/inkscape.sh': 'installInkscape',
 'core/tabs/applications-setup/design-tools/krita.sh': 'installKrita',
 'core/tabs/applications-setup/design-tools/mypaint.sh': 'installMyPaint',
 'core/tabs/applications-setup/design-tools/natron.sh': 'installNatron',
 'core/tabs/applications-setup/design-tools/obs-studio.sh': 'installObsStudio',
 'core/tabs/applications-setup/design-tools/olive.sh': 'installOlive',
 'core/tabs/applications-setup/design-tools/openshot.sh': 'installOpenShot',
 'core/tabs/applications-setup/design-tools/pinta.sh': 'installPinta',
 'core/tabs/applications-setup/design-tools/scribus.sh': 'installScribus',
 'core/tabs/applications-setup/design-tools/synfigstudio.sh': 'installSynfigStudio',
 'core/tabs/applications-setup/design-tools/tenacity.sh': 'installTenacity',
 'core/tabs/applications-setup/noctalia-shell.sh': 'installNoctalia',
 'core/tabs/applications-setup/shelly-setup.sh': 'installShelly',
 'core/tabs/gaming/emulators/nintendo/bsnes.sh': 'installbsnes',
 'core/tabs/gaming/emulators/nintendo/dolphin-emu.sh': 'installDolphin',
 'core/tabs/gaming/emulators/nintendo/gopher64.sh': 'installgopher64',
 'core/tabs/gaming/emulators/nintendo/melonds.sh': 'installMelonDS',
 'core/tabs/gaming/emulators/nintendo/mesen2.sh': 'installMesen2',
 'core/tabs/gaming/emulators/nintendo/mgba.sh': 'installmGBA',
 'core/tabs/gaming/emulators/nintendo/mupen64plus.sh': 'installmupen64plus',
 'core/tabs/gaming/emulators/nintendo/ryujinx.sh': 'installRyujinx',
 'core/tabs/gaming/emulators/nintendo/snes9x.sh': 'installsnes9x',
 'core/tabs/gaming/emulators/playstation/pcsx.sh': 'installPCSX',
 'core/tabs/gaming/emulators/playstation/pcsx2.sh': 'installPCSX2',
 'core/tabs/gaming/emulators/playstation/play-emu.sh': 'installPlay',
 'core/tabs/gaming/emulators/playstation/rpcs3.sh': 'installrpcs3',
 'core/tabs/gaming/emulators/retroarch.sh': 'installRetroArch',
 'core/tabs/gaming/emulators/sega/blastem.sh': 'installblastem',
 'core/tabs/gaming/emulators/sega/flycast.sh': 'installflycast',
 'core/tabs/gaming/emulators/sega/kronos.sh': 'installkronos',
 'core/tabs/gaming/emulators/sega/yabause.sh': 'installyabause',
 'core/tabs/gaming/emulators/xbox/xemu.sh': 'installxemu',
 'core/tabs/gaming/emulators/xbox/xenia.sh': 'installxenia',
 'core/tabs/gaming/game-launchers.sh': 'install_launcher',
 'core/tabs/gaming/proton-tools.sh': 'install_tool',
 'core/tabs/utils/ramalama.sh': 'installramalama'}


def function(path, name):
    source = (ROOT / path).read_text()
    return re.search(r"^" + re.escape(name) + r"\(\) \{\n.*?^\}", source, re.M | re.S).group()


def main_function(path):
    return function(path, "main")


class InstallEntrypoints(unittest.TestCase):
    def test_installation_starts_without_menu_input(self):
        for path, install in ENTRYPOINTS.items():
            if path.endswith("google-chrome.sh"):
                continue
            with self.subTest(path=path):
                body = main_function(path) + "\n" + install + "() { echo INSTALL; }\n"
                argument = "" if path.endswith(("/retroarch.sh", "/ramalama.sh")) else "fixture"
                body += "set_launcher() { :; }; set_tool() { :; }\nmain " + argument + "\n"
                result = subprocess.run(["sh", "-e", "-c", body], input="",
                                        text=True, capture_output=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "INSTALL\n")

    def test_management_dispatch_preserves_install_only_defaults(self):
        cases = [
            ("core/tabs/gaming/emulators/retroarch.sh", "installRetroArch", "configureRetroArch", "--cores"),
            ("core/tabs/utils/ramalama.sh", "installramalama", "menu", "--manage"),
        ]
        for path, install, manage, option in cases:
            for action, expected in [(option, "MANAGE"), ("--uninstall", None)]:
                with self.subTest(path=path, action=action):
                    body = main_function(path) + "\n"
                    body += install + "() { echo UNEXPECTED_INSTALL; }; "
                    body += manage + "() { echo MANAGE; }; command_exists() { return 0; }\n"
                    result = subprocess.run(["sh", "-e", "-c", body + "main " + action],
                                            capture_output=True, text=True, timeout=5)
                    self.assertEqual(result.returncode, 0 if expected else 2, result.stderr)
                    self.assertEqual(result.stdout.strip(), expected or "")

    def test_ramalama_manager_requires_installation(self):
        body = main_function("core/tabs/utils/ramalama.sh") + """
command_exists() { return 1; }
installramalama() { echo UNEXPECTED_INSTALL; }
menu() { echo UNEXPECTED_MENU; }
main --manage
"""
        result = subprocess.run(["sh", "-e", "-c", body], capture_output=True, text=True, timeout=5)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.assertIn("Install Ramalama", result.stderr)

    def test_retroarch_core_setup_installs_only_supported_packages(self):
        body = function("core/tabs/gaming/emulators/retroarch.sh", "configureRetroArch")
        for manager in ["apt-get", "nala", "dnf", "zypper", "pacman", "apk"]:
            with self.subTest(manager=manager):
                mocks = """
command_exists() { return 0; }
mock_escalate() { printf 'PACKAGES: %s\n' "$*"; }
mock_aur() { printf 'PACKAGES: %s\n' "$*"; }
ESCALATION_TOOL=mock_escalate
AUR_HELPER=mock_aur
"""
                script = body + "\n" + mocks + "PACKAGER=" + manager + "\nconfigureRetroArch"
                result = subprocess.run(["sh", "-e", "-c", script], capture_output=True, text=True, timeout=5)
                self.assertNotIn("uninstall", result.stdout)
                self.assertEqual(result.returncode, 1 if manager == "apk" else 0, result.stderr)
                if manager == "apk":
                    self.assertNotIn("PACKAGES:", result.stdout)
                    self.assertIn("not supported", result.stdout)
                else:
                    self.assertIn("libretro-", result.stdout)

    def test_management_catalog_entries_invoke_the_right_actions(self):
        for catalog, name, wrapper, target, option in [
            ("gaming", "RetroArch Cores", "emulators/retroarch-cores.sh", "retroarch.sh", "--cores"),
            ("utils", "Ramalama Model Manager", "ramalama-models.sh", "ramalama.sh", "--manage"),
        ]:
            with self.subTest(entry=name):
                data = tomllib.loads((ROOT / "core/tabs" / catalog / "tab_data.toml").read_text())
                def entries(nodes):
                    for node in nodes:
                        yield node
                        yield from entries(node.get("entries", []))
                entry = next(node for node in entries(data["data"]) if node["name"] == name)
                self.assertEqual(entry["script"], wrapper)
                self.assertFalse(entry["multi_select"])
                # Run the real wrapper beside a harmless stand-in for its target.
                with tempfile.TemporaryDirectory() as directory:
                    Path(directory, target).write_text("printf '%s\n' \"$@\"\n")
                    result = subprocess.run(["sh", "-e", str(ROOT / "core/tabs" / catalog / wrapper)],
                                            cwd=directory, capture_output=True, text=True, timeout=5)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertEqual(result.stdout.strip(), option)

    def test_chrome_keeps_only_install_and_remove_ai(self):
        path = "core/tabs/applications-setup/browsers/google-chrome.sh"
        body = main_function(path) + """
installChrome() { printf '\\nINSTALL\\n'; }
removeLocalAI() { printf '\\nREMOVE_AI\\n'; }
uninstallChrome() { echo UNEXPECTED_UNINSTALL; exit 1; }
readMenuChoice() { read -r "$@"; }
invalidChoice() { exit 64; }
main
"""
        for choice, expected, status in [("1\n", "INSTALL", 0), ("2\n", "REMOVE_AI", 0),
                                          ("3\n", None, 64), ("", None, 1)]:
            with self.subTest(choice=choice):
                result = subprocess.run(["sh", "-e", "-c", body], input=choice,
                                        text=True, capture_output=True, timeout=5)
                self.assertEqual(result.returncode, status, result.stderr)
                self.assertNotIn("Uninstall", result.stdout)
                self.assertNotIn("UNEXPECTED_UNINSTALL", result.stdout)
                if expected:
                    self.assertIn(expected, result.stdout.splitlines())
                else:
                    self.assertNotIn("INSTALL", result.stdout.splitlines())
                    self.assertNotIn("REMOVE_AI", result.stdout.splitlines())


if __name__ == "__main__":
    unittest.main()
