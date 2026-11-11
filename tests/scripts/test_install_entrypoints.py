"""Entrypoint dispatch checks; installation and AI-removal functions are mocked."""
from pathlib import Path
import re
import subprocess
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


def main_function(path):
    source = (ROOT / path).read_text()
    return re.search(r"^main\(\) \{\n.*?^\}", source, re.M | re.S).group()


class InstallEntrypoints(unittest.TestCase):
    def test_installation_starts_without_menu_input(self):
        for path, install in ENTRYPOINTS.items():
            if path.endswith("google-chrome.sh"):
                continue
            with self.subTest(path=path):
                body = main_function(path) + "\n" + install + "() { echo INSTALL; }\n"
                body += "set_launcher() { :; }; set_tool() { :; }\nmain fixture\n"
                result = subprocess.run(["sh", "-e", "-c", body], input="",
                                        text=True, capture_output=True, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertEqual(result.stdout, "INSTALL\n")

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
