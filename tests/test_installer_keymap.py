"""Exercise only the extracted keymap function; never source the installer."""
import pathlib
import subprocess
import unittest

SCRIPT = pathlib.Path(__file__).resolve().parents[1] / "core/tabs/system-setup/arch/server-setup.sh"

class KeymapTests(unittest.TestCase):
    def test_application_and_confirmation_boundaries(self):
        source = SCRIPT.read_text().split("keymap () {", 1)[1].split("\n}", 1)[0]
        for failure, answer, success in (("", "y\n", True), ("", "Y\n", True), ("", "n\n", False), ("", "\n", False), ("", "", False), ("stored", "y\n", False), ("active", "y\n", False)):
            with self.subTest(failure=failure, answer=answer):
                harness = """select_option() { return 0; }
localectl() {
 case "$1" in
 list-keymaps) printf 'us\\n';;
 set-keymap) printf 'STORED\\n'; [ "$FAILURE" != stored ];;
 esac
}
loadkeys() { printf 'ACTIVE\\n'; [ "$FAILURE" != active ]; }
keymap() {""" + source + "\n}\nkeymap\nprintf 'PASSWORD_BOUNDARY:%s\\n' \"$KEYMAP\"\n"
                result = subprocess.run(["bash", "-e", "-c", harness], input=answer, text=True, capture_output=True, env={"FAILURE": failure, "PATH": "/usr/bin:/bin"})
                self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
                self.assertEqual("PASSWORD_BOUNDARY:us" in result.stdout, success)
                if failure == "stored":
                    self.assertNotIn("ACTIVE", result.stdout)

    def test_console_aliases_are_separate_from_layout_identifiers(self):
        source = SCRIPT.read_text().split("keymap () {", 1)[1].split("\n}", 1)[0]
        for layout, keymap, x11 in (("ca", "cf", "ca"), ("si", "slovene", "si"),
                                   ("tr", "trq", "tr"), ("cf", "cf", "ca"),
                                   ("uk", "uk", "gb")):
            with self.subTest(layout=layout):
                harness = r"""select_option() {
 local index=0 option
 for option; do
  [ "$option" = "$LAYOUT" ] && return "$index"
  index=$((index + 1))
 done
 return 99
}
localectl() {
 case "$1" in
 list-keymaps) printf 'us\ncf\nslovene\ntrq\nuk\n';;
 set-keymap) [ "$2" = "$EXPECTED_MAP" ] || return 1; printf 'STORED:%s\n' "$2";;
 esac
}
loadkeys() { [ "$1" = "$EXPECTED_MAP" ] || return 1; printf 'ACTIVE:%s\n' "$1"; }
keymap() {""" + source + "\n}\nkeymap\nprintf 'BOUNDARY:%s:%s:%s\\n' \"$KEYBOARD_LAYOUT\" \"$KEYMAP\" \"$XKBLAYOUT\"\n"
                result = subprocess.run(["bash", "-e", "-c", harness], input="y\n", text=True,
                                        capture_output=True, env={"LAYOUT": layout, "EXPECTED_MAP": keymap, "PATH": "/usr/bin:/bin"})
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn(f"BOUNDARY:{layout}:{keymap}:{x11}", result.stdout)
                self.assertIn(f"STORED:{keymap}", result.stdout)
                self.assertIn(f"ACTIVE:{keymap}", result.stdout)

    def test_unavailable_keymaps_stop_before_mutations(self):
        source = SCRIPT.read_text().split("keymap () {", 1)[1].split("\n}", 1)[0]
        for listing in ("return 1", "printf ''", "printf 'unsupported-map\\n'"):
            harness = "localectl() { " + listing + "; }\nselect_option() { printf 'MENU'; }\nloadkeys() { printf 'ACTIVE'; }\nkeymap() {" + source + "\n}\nkeymap\nprintf 'PASSWORD_BOUNDARY'\n"
            result = subprocess.run(["bash", "-e", "-c", harness], input="y\n", text=True, capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertNotIn("MENU", result.stdout)
            self.assertNotIn("ACTIVE", result.stdout)
            self.assertNotIn("PASSWORD_BOUNDARY", result.stdout)

if __name__ == "__main__":
    unittest.main()
