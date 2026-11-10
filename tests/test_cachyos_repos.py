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

CACHY_ENTRY = 'GRUB_DEFAULT="gnulinux-advanced-test>gnulinux-linux-cachyos-lts-advanced-test"'
STOCK_ENTRY = 'GRUB_DEFAULT="gnulinux-advanced-test>gnulinux-linux-advanced-test"'

MOCK = r"""
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys

name = Path(sys.argv[0]).name
args = sys.argv[1:]
root = Path(os.environ["TEST_ROOT"])
if name == "escalate":
    sys.exit(subprocess.run(args).returncode)

if name != "pacman-conf" and (name != "rm" or not any(".linutil." in arg for arg in args)):
    with (root / "commands.jsonl").open("a") as log:
        log.write(json.dumps([name, *args]) + "\n")
if name == os.environ.get("FAIL_COMMAND"):
    sys.exit(42)

if name == "pacman-conf":
    for config in (root / "etc/pacman.conf", root / "etc/included-repos.conf"):
        if config.exists():
            for line in config.read_text().splitlines():
                header = line.split("#", 1)[0].strip()
                if header.startswith("[") and header.endswith("]"):
                    print(header[1:-1])
elif name == "curl":
    Path(args[args.index("-o") + 1]).write_text("mock archive")
elif name == "tar":
    repo = Path.cwd() / "cachyos-repo"
    repo.mkdir()
    installer = repo / "cachyos-repo.sh"
    installer.write_text('#!/bin/sh -e\nrepo-installer "$@"\n')
    installer.chmod(0o755)
elif name == "repo-installer":
    if os.environ.get("SKIP_REPO_EDIT") == "1":
        sys.exit(0)
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
    default = next(line for line in (root / "etc/default/grub").read_text().splitlines()
                   if line.startswith("GRUB_DEFAULT=")).split("=", 1)[1].strip('"')
    if os.environ.get("GRUB_INTERRUPT") == "1" and default.endswith(">gnulinux-linux-advanced-test"):
        os.killpg(os.getpgrp(), signal.SIGINT)
    if os.environ.get("GRUB_OVERRIDE") == "1":
        default = "saved"
    if os.environ.get("GRUB_CUSTOM_MENU") == "1":
        target.write_text("menuentry 'Custom' {\n    linux /vmlinuz-linux-cachyos-lts quiet\n}\n")
    else:
        target.write_text(
            f'   set default="{default}"\n'
            "### BEGIN /etc/grub.d/10_linux ###\n"
            "menuentry 'Arch Linux' $menuentry_id_option 'gnulinux-simple-test' {\n"
            "    linux /vmlinuz-linux-cachyos-lts quiet\n}\n"
            "submenu 'Advanced options for Arch Linux' $menuentry_id_option 'gnulinux-advanced-test' {\n"
            "    menuentry 'CachyOS LTS' $menuentry_id_option 'gnulinux-linux-cachyos-lts-advanced-test' {\n        linux /vmlinuz-linux-cachyos-lts quiet\n    }\n"
            "    menuentry 'Stock' $menuentry_id_option 'gnulinux-linux-advanced-test' {\n        linux /vmlinuz-linux quiet\n    }\n}\n"
            "### END /etc/grub.d/10_linux ###\n"
        )
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
             grub_command=True, grub_directory=True, skip_repo_edit=False,
             grub_custom_menu=False, included_repos=None, grub_override=False,
             grub_interrupt=False, confirm="y"):
    with tempfile.TemporaryDirectory(prefix="linutil-cachyos-") as temporary:
        root = Path(temporary)
        directory = root / "tabs/system-setup/arch"
        directory.mkdir(parents=True)
        (root / "etc/default").mkdir(parents=True)
        pacman_path = root / "etc/pacman.conf"
        pacman_path.write_text(pacman)
        if included_repos:
            (root / "etc/included-repos.conf").write_text(included_repos)
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
            'checkEnv() { [ "$AUR_HELPER_CHECKED" = true ] || return 99; '
            'ESCALATION_TOOL=escalate; PACKAGER=pacman; '
            'printf checked > "$TEST_ROOT/environment-checked"; }\n'
            'command_exists() { command -v "$1" >/dev/null 2>&1; }\n'
        )
        binaries = root / "bin"
        binaries.mkdir()
        for command in ("grep", "awk", "cat", "mktemp", "cp", "mv"):
            (binaries / command).symlink_to(shutil.which(command))
        commands = ["escalate", "curl", "tar", "repo-installer", "rm", "pacman", "pacman-conf", "sed"]
        if grub_command:
            commands.append("grub-mkconfig")
        for command in commands:
            mock = binaries / command
            mock.write_text(f"#!{sys.executable}\n" + MOCK)
            mock.chmod(0o755)
        environment = {
            "PATH": str(binaries),
            "TEST_ROOT": str(root),
            "TMPDIR": str(root),
            "REAL_SED": shutil.which("sed"),
            "LC_ALL": "C",
        }
        if grub_interrupt:
            environment["GRUB_INTERRUPT"] = "1"
        if grub_override:
            environment["GRUB_OVERRIDE"] = "1"
        if grub_custom_menu:
            environment["GRUB_CUSTOM_MENU"] = "1"
        if skip_repo_edit:
            environment["SKIP_REPO_EDIT"] = "1"
        if fail:
            environment["FAIL_COMMAND"] = fail
        completed = subprocess.run(
            [str(script)], cwd=directory, env=environment,
            input=f"{choice}\n{confirm}\n", text=True, capture_output=True, timeout=10, start_new_session=True,
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

    def test_commented_repos_require_manual_enablement(self):
        for section in ("#[cachyos]", "# [cachyos-v3]", "  # [cachyos-core-v3]"):
            with self.subTest(section=section):
                install = run_menu(1, pacman=section + "\n")
                self.assertNotEqual(install["status"], 0)
                self.assertIn("Enable the commented CachyOS repos", install["output"])
                self.assertEqual(install["commands"], [])
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
                self.assertEqual(result["commands"], ["pacman", "grub-mkconfig", "sed", "grub-mkconfig"])
                self.assertEqual(result["grub"], CACHY_ENTRY + "\n")
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
        result = run_menu(3)
        self.assert_success(result)
        self.assertEqual(result["commands"], ["curl", "tar", "repo-installer", "rm", "pacman", "grub-mkconfig", "sed", "grub-mkconfig"])
        self.assertEqual(result["grub"], CACHY_ENTRY + "\n")
        result = run_menu(3, skip_repo_edit=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("did not enable", result["output"])
        self.assertEqual(result["commands"], ["curl", "tar", "repo-installer", "rm"])

    def test_reset_matches_active_setting_and_regenerates_grub(self):
        result = run_menu(5, grub="#GRUB_DEFAULT=0\n" + CACHY_DEFAULT + "\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], ["grub-mkconfig", "sed", "grub-mkconfig"])
        self.assertEqual(result["grub"], "#GRUB_DEFAULT=0\n" + STOCK_ENTRY + "\n")
        self.assertTrue(result["generated"])

    def test_reset_does_not_change_another_default(self):
        result = run_menu(5, grub="GRUB_DEFAULT=saved\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], [])
        self.assertEqual(result["grub"], "GRUB_DEFAULT=saved\n")

    def test_combined_remove_handles_active_repositories(self):
        result = run_menu(4, pacman="[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n", grub=CACHY_DEFAULT + "\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], ["curl", "tar", "repo-installer", "rm", "grub-mkconfig", "sed", "grub-mkconfig"])
        self.assertIn(["repo-installer", "--remove"], result["events"])
        self.assertEqual(result["grub"], STOCK_ENTRY + "\n")
        self.assertTrue(result["script_exists"])
        self.assertTrue(result["notes_exist"])

    def test_repo_only_removal_works_without_grub_and_skips_comments(self):
        for config in ("[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n", "# [cachyos]\n"):
            with self.subTest(config=config):
                result = run_menu(6, pacman=config, grub=None, grub_command=False, grub_directory=False)
                self.assert_success(result)
                expected = [] if config.startswith("#") else ["curl", "tar", "repo-installer", "rm"]
                self.assertEqual(result["commands"], expected)

    def test_removal_refuses_repos_defined_in_included_files(self):
        result = run_menu(6, included_repos="[cachyos]\n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("Remove the cachyos repository manually", result["output"])
        self.assertEqual(result["commands"], [])

    def test_custom_grub_menu_preserves_original_default(self):
        for choice, initial in ((2, "GRUB_DEFAULT=0\n"), (5, CACHY_DEFAULT + "\n")):
            with self.subTest(choice=choice):
                result = run_menu(choice, pacman="[cachyos]\n", grub=initial, grub_custom_menu=True)
                self.assertNotEqual(result["status"], 0)
                self.assertIn("Could not find a GRUB entry", result["output"])
                self.assertEqual(result["grub"], initial)
                self.assertFalse(result["generated"])

    def test_grub_override_preserves_original_default(self):
        result = run_menu(5, grub=CACHY_ENTRY + "\n", grub_override=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("Could not verify", result["output"])
        self.assertEqual(result["grub"], CACHY_ENTRY + "\n")
        self.assertFalse(result["generated"])

    def test_grub_interrupt_restores_original_default(self):
        result = run_menu(5, grub=CACHY_ENTRY + "\n", grub_interrupt=True)
        self.assertNotEqual(result["status"], 0)
        self.assertEqual(result["grub"], CACHY_ENTRY + "\n")
        self.assertFalse(result["generated"])

    def test_removal_refuses_nonstandard_blocks_and_requires_confirmation(self):
        standard = "[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n"
        malformed = standard.replace("Include", "# Mirror\nInclude")
        result = run_menu(6, pacman=malformed)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("standard repository block", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard, confirm="n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("downgrade system packages", result["output"])
        self.assertEqual(result["commands"], [])

    def test_download_or_extraction_failure_stops_before_running_helper(self):
        for choice, config in ((1, "[core]\n"), (4, "[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n")):
            for index, failure in enumerate(("curl", "tar")):
                with self.subTest(choice=choice, failure=failure):
                    result = run_menu(choice, pacman=config, fail=failure)
                    self.assertEqual(result["status"], 42, result["output"])
                    self.assertEqual(result["commands"], ["curl", "tar"][:index + 1] + ["rm"])

    def test_failures_stop_and_propagate_under_shebang_errexit(self):
        for choice, initial in ((2, "GRUB_DEFAULT=0\n"), (5, CACHY_DEFAULT + "\n")):
            stages = ["pacman", "grub-mkconfig", "sed", "grub-mkconfig"] if choice == 2 else ["grub-mkconfig", "sed", "grub-mkconfig"]
            for failure in dict.fromkeys(stages):
                index = stages.index(failure)
                with self.subTest(choice=choice, failure=failure):
                    result = run_menu(choice, pacman="[cachyos]\n", grub=initial, fail=failure)
                    self.assertEqual(result["status"], 42, result["output"])
                    self.assertEqual(result["commands"], stages[:index + 1])
                    self.assertFalse(result["generated"])
                    self.assertEqual(result["grub"], initial)


if __name__ == "__main__":
    unittest.main()
