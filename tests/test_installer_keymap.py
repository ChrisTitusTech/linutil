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
 list-x11-keymap-layouts) printf 'us\\n';;
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

if __name__ == "__main__":
    unittest.main()
