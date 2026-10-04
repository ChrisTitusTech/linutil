"""Run the CachyOS menu under its real /bin/sh -e shebang, without host changes.

Run with: python3 -B -m unittest discover -s tests -p 'test_cachyos_repos.py' -v
All system paths point into a temporary directory. PATH contains only read-only
text tools and local mocks for downloads, packages, privilege and boot changes.
"""

import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "core/tabs/system-setup/arch/cachyos-repos.sh"
)
CACHY_DEFAULT = (
    'GRUB_DEFAULT="Advanced options for Arch Linux>'
    'Arch Linux, with Linux linux-cachyos-lts"'
)

MOCK = r"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
root = Path(os.environ["TEST_ROOT"])
if name == "escalate":
    sys.exit(subprocess.run(args).returncode)

with (root / "commands.jsonl").open("a") as log:
    log.write(json.dumps([name, *args]) + "\n")
if name == os.environ.get("FAIL_COMMAND"):
    sys.exit(42)

if name == "curl":
    Path(args[args.index("-o") + 1]).write_text("mock archive")
elif name == "tar":
    repo = Path.cwd() / "cachyos-repo"
    repo.mkdir()
    installer = repo / "cachyos-repo.sh"
    installer.write_text('#!/bin/sh -e\nrepo-installer "$@"\n')
    installer.chmod(0o755)
elif name == "repo-installer":
    (root / "etc/pacman.conf").write_text(
        "[core]\n" if "--remove" in args else "[cachyos]\n"
    )
elif name == "sed":
    target = Path(args[-1]).resolve()
    if not target.is_relative_to(root):
        sys.exit("Refusing a non-fixture sed target")
    sys.exit(subprocess.run([os.environ["REAL_SED"], *args]).returncode)
elif name == "grub-mkconfig":
    target = Path(args[-1]).resolve()
    if not target.is_relative_to(root):
        sys.exit("Refusing a non-fixture GRUB target")
    target.write_text("mock regenerated config\n")
elif name == "rm":
    for argument in args:
        if argument.startswith("-"):
            continue
        target = Path(argument).resolve()
        if not target.is_relative_to(root):
            sys.exit("Refusing a non-fixture removal target")
        if target.is_dir():
            shutil.rmtree(target)
        elif target.exists():
            target.unlink()
elif name != "pacman":
    sys.exit("Unexpected mock command: " + name)
"""


def run_menu(choice, pacman="[core]\n", grub="GRUB_DEFAULT=0\n", fail=None,
             grub_command=True, grub_directory=True):
    with tempfile.TemporaryDirectory(prefix="linutil-cachyos-") as temporary:
        root = Path(temporary)
        directory = root / "tabs/system-setup/arch"
        directory.mkdir(parents=True)
        (root / "etc/default").mkdir(parents=True)
        pacman_path = root / "etc/pacman.conf"
        pacman_path.write_text(pacman)
        grub_path = root / "etc/default/grub"
        if grub is not None:
            grub_path.write_text(grub)
        if grub_directory:
            (root / "boot/grub").mkdir(parents=True)
        source = SCRIPT.read_text()
        assert source.startswith("#!/bin/sh -e\n")
        for path in ("/etc/pacman.conf", "/etc/default/grub", "/boot/grub"):
            source = source.replace(path, str(root / path.lstrip("/")))
        script = directory / SCRIPT.name
        script.write_text(source)
        script.chmod(0o755)
        notes = directory / "cachyos-repo-notes.txt"
        notes.write_text("unrelated file\n")
        (root / "tabs/common-script.sh").write_text(
            'checkEnv() { ESCALATION_TOOL=escalate; PACKAGER=pacman; '
            'printf checked > "$TEST_ROOT/environment-checked"; }\n'
            'command_exists() { command -v "$1" >/dev/null 2>&1; }\n'
        )
        binaries = root / "bin"
        binaries.mkdir()
        for command in ("grep", "awk", "cat"):
            (binaries / command).symlink_to(shutil.which(command))
        commands = ["escalate", "curl", "tar", "repo-installer", "rm", "pacman", "sed"]
        if grub_command:
            commands.append("grub-mkconfig")
        for command in commands:
            mock = binaries / command
            mock.write_text(f"#!{sys.executable}\n" + MOCK)
            mock.chmod(0o755)
        environment = {
            "PATH": str(binaries),
            "TEST_ROOT": str(root),
            "REAL_SED": shutil.which("sed"),
            "LC_ALL": "C",
        }
        if fail:
            environment["FAIL_COMMAND"] = fail
        completed = subprocess.run(
            [str(script)], cwd=directory, env=environment,
            input=f"{choice}\n", text=True, capture_output=True, timeout=10,
        )
        log = root / "commands.jsonl"
        events = [json.loads(line) for line in log.read_text().splitlines()] if log.exists() else []
        return {
            "status": completed.returncode,
            "output": completed.stdout + completed.stderr,
            "commands": [event[0] for event in events],
            "events": events,
            "pacman": pacman_path.read_text(),
            "grub": grub_path.read_text() if grub_path.exists() else None,
            "generated": (root / "boot/grub/grub.cfg").exists(),
            "script_exists": script.exists(),
            "notes_exist": notes.exists(),
            "environment_checked": (root / "environment-checked").exists(),
        }


class CachyosReposTests(unittest.TestCase):
    def assert_success(self, result):
        self.assertEqual(result["status"], 0, result["output"])
        self.assertTrue(result["environment_checked"])

    def test_repository_install_with_no_existing_repos_and_no_grub(self):
        result = run_menu(1, grub=None, grub_command=False, grub_directory=False)
        self.assert_success(result)
        self.assertEqual(result["commands"], ["curl", "tar", "repo-installer", "rm"])
        self.assertIn("[cachyos]", result["pacman"])
        self.assertTrue(result["script_exists"])
        self.assertTrue(result["notes_exist"])

    def test_existing_base_and_optimized_repos_are_not_reinstalled(self):
        for section in ("[cachyos]", "[cachyos-v3]", "[cachyos-core-v4]", "[cachyos-extra-znver4]"):
            with self.subTest(section=section):
                result = run_menu(1, pacman=section + "\n")
                self.assert_success(result)
                self.assertEqual(result["commands"], [])

    def test_commented_repos_can_be_enabled_but_cannot_directly_install_kernels(self):
        for section in ("#[cachyos]", "# [cachyos-v3]", "  # [cachyos-core-v3]"):
            with self.subTest(section=section):
                install = run_menu(1, pacman=section + "\n")
                self.assert_success(install)
                self.assertEqual(install["commands"], ["curl", "tar", "repo-installer", "rm"])
                self.assertIn("[cachyos]", install["pacman"])
                kernel = run_menu(2, pacman=section + "\n")
                self.assertNotEqual(kernel["status"], 0)
                self.assertIn("not enabled", kernel["output"])
                self.assertEqual(kernel["commands"], [])

    def test_unrelated_mentions_do_not_count_as_repository_sections(self):
        result = run_menu(1, pacman="# See [cachyos-v3] docs\nInclude = /etc/cachyos-mirrorlist\n")
        self.assert_success(result)
        self.assertIn("repo-installer", result["commands"])

    def test_active_base_and_v3_repos_install_and_regenerate_grub(self):
        for section in ("[cachyos]", "  [cachyos-v3] # enabled", "#[cachyos]\n[cachyos-core-v3]"):
            with self.subTest(section=section):
                result = run_menu(2, pacman=section + "\n")
                self.assert_success(result)
                self.assertEqual(result["commands"], ["pacman", "sed", "grub-mkconfig"])
                self.assertEqual(result["grub"], CACHY_DEFAULT + "\n")
                self.assertTrue(result["generated"])

    def test_missing_repositories_reject_kernel_install_without_mutations(self):
        result = run_menu(2)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("not enabled", result["output"])
        self.assertEqual(result["commands"], [])

    def test_all_default_kernel_actions_preflight_before_mutations(self):
        for choice in (2, 3, 4, 5):
            for missing in ({"grub": None}, {"grub_command": False}, {"grub_directory": False}):
                with self.subTest(choice=choice, missing=missing):
                    result = run_menu(choice, pacman="[cachyos]\n", **missing)
                    self.assertNotEqual(result["status"], 0)
                    self.assertIn("requires GRUB", result["output"])
                    self.assertEqual(result["commands"], [])
                    self.assertFalse(result["environment_checked"])

    def test_missing_grub_default_is_rejected_before_combined_install(self):
        result = run_menu(3, grub="#GRUB_DEFAULT=0\n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("No GRUB_DEFAULT", result["output"])
        self.assertEqual(result["commands"], [])
        self.assertFalse(result["environment_checked"])

    def test_combined_install_rechecks_repositories(self):
        for config in ("[core]\n", "# [cachyos-v3]\n"):
            with self.subTest(config=config):
                result = run_menu(3, pacman=config)
                self.assert_success(result)
                self.assertEqual(result["commands"], ["curl", "tar", "repo-installer", "rm", "pacman", "sed", "grub-mkconfig"])
                self.assertEqual(result["grub"], CACHY_DEFAULT + "\n")

    def test_reset_matches_active_setting_and_regenerates_grub(self):
        result = run_menu(5, grub="#GRUB_DEFAULT=0\n" + CACHY_DEFAULT + "\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], ["sed", "grub-mkconfig"])
        self.assertEqual(result["grub"], "#GRUB_DEFAULT=0\nGRUB_DEFAULT=0\n")
        self.assertTrue(result["generated"])

    def test_reset_does_not_change_another_default(self):
        result = run_menu(5, grub="GRUB_DEFAULT=saved\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], [])
        self.assertEqual(result["grub"], "GRUB_DEFAULT=saved\n")

    def test_combined_remove_handles_commented_repositories(self):
        result = run_menu(4, pacman="# [cachyos-v3]\n", grub=CACHY_DEFAULT + "\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], ["curl", "tar", "repo-installer", "rm", "sed", "grub-mkconfig"])
        self.assertIn(["repo-installer", "--remove"], result["events"])
        self.assertEqual(result["grub"], "GRUB_DEFAULT=0\n")
        self.assertTrue(result["script_exists"])
        self.assertTrue(result["notes_exist"])

    def test_download_or_extraction_failure_stops_before_running_helper(self):
        for choice, config in ((1, "[core]\n"), (4, "[cachyos-v3]\n")):
            for index, failure in enumerate(("curl", "tar")):
                with self.subTest(choice=choice, failure=failure):
                    result = run_menu(choice, pacman=config, fail=failure)
                    self.assertEqual(result["status"], 42, result["output"])
                    self.assertEqual(result["commands"], ["curl", "tar"][:index + 1])

    def test_failures_stop_and_propagate_under_shebang_errexit(self):
        for choice, initial in ((2, "GRUB_DEFAULT=0\n"), (5, CACHY_DEFAULT + "\n")):
            stages = ["pacman", "sed", "grub-mkconfig"] if choice == 2 else ["sed", "grub-mkconfig"]
            for index, failure in enumerate(stages):
                with self.subTest(choice=choice, failure=failure):
                    result = run_menu(choice, pacman="[cachyos]\n", grub=initial, fail=failure)
                    self.assertEqual(result["status"], 42, result["output"])
                    self.assertEqual(result["commands"], stages[:index + 1])
                    self.assertFalse(result["generated"])


if __name__ == "__main__":
    unittest.main()
