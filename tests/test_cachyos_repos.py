"""Run the CachyOS menu under its real /bin/sh -e shebang, without host changes.

Run with: python3 -B -m unittest discover -s tests -p 'test_cachyos_repos.py' -v
All system paths point into a temporary directory. PATH contains only read-only
text tools and local mocks for downloads, packages, privilege and boot changes.
"""

import hashlib
import json
from pathlib import Path
import re
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
preflight = name == "grub-mkconfig" and args and ".preflight." in args[-1]
if preflight and os.environ.get("GRUB_PREFLIGHT_FAILURE") == "1":
    sys.exit(42)

if not preflight and name not in ("pacman-conf", "ld-linux-x86-64.so.2", "findmnt") and not (name == "pacman" and args[0] in ("-Q", "-Qq")) and (name != "rm" or not any(".linutil." in arg for arg in args)):
    with (root / "commands.jsonl").open("a") as log:
        log.write(json.dumps([name, *args]) + "\n")
if not preflight and name == os.environ.get("FAIL_COMMAND"):
    sys.exit(42)

if name == "ld-linux-x86-64.so.2":
    if os.environ.get("UNSUPPORTED_CPU") != "1":
        print("  x86-64-v3 (supported, searched)")
elif name == "findmnt":
    print(os.environ.get("ROOT_FS", "ext4"))
elif name == "pacman-conf":
    if args[0] == "--repo":
        if args[-1] == "Usage":
            print("All")
        elif os.environ.get("STOCK_NO_SERVERS") != "1":
            print("https://example.invalid/arch")
        sys.exit(0)
    for config in (root / "etc/pacman.conf", root / "etc/included-repos.conf"):
        if config.exists():
            for line in config.read_text().splitlines():
                header = line.split("#", 1)[0].strip()
                if header.startswith("[") and header.endswith("]"):
                    print(header[1:-1])
elif name == "curl":
    Path(args[args.index("-o") + 1]).write_text("corrupt archive" if os.environ.get("CORRUPT_ARCHIVE") == "1" else "mock archive")
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
        generated = (
            "### BEGIN /etc/grub.d/00_header ###\n"
            'if [ "${next_entry}" ]; then\n'
            '   set default="${next_entry}"\n'
            "else\n"
            f'   set default="{default}"\n'
            "fi\n"
            "### END /etc/grub.d/00_header ###\n"
            "### BEGIN /etc/grub.d/10_linux ###\n"
            "menuentry 'Arch Linux' $menuentry_id_option 'gnulinux-simple-test' {\n"
            "    linux /vmlinuz-linux-cachyos-lts quiet\n}\n"
            "submenu 'Advanced options for Arch Linux' $menuentry_id_option 'gnulinux-advanced-test' {\n"
            "    menuentry 'CachyOS LTS' $menuentry_id_option 'gnulinux-linux-cachyos-lts-advanced-test' {\n        linux /vmlinuz-linux-cachyos-lts quiet\n        initrd /initramfs-linux-cachyos-lts.img\n    }\n"
            "    menuentry 'Stock' $menuentry_id_option 'gnulinux-linux-advanced-test' {\n        linux /vmlinuz-linux quiet\n        initrd /initramfs-linux.img\n    }\n}\n"
            "### END /etc/grub.d/10_linux ###\n"
        )
        if os.environ.get("GRUB_DEVICE_ID") == "1":
            generated = generated.replace("-test'", "-/dev/sda2'")
        if os.environ.get("GRUB_MISSING_INITRAMFS") == "1":
            generated = generated.replace("initrd /initramfs-linux.img", "initrd /intel-ucode.img")
        if os.environ.get("GRUB_LATE_OVERRIDE") == "1":
            generated += 'set timeout=5; set default=0\n'
        if os.environ.get("GRUB_LATE_OVERRIDE") == "bare":
            generated += 'default=0\n'
        target.write_text(generated)
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
elif name == "pacman" and args[0] == "-Qq":
    if os.environ.get("LIB32_INSTALLED") == "1":
        print("lib32-mesa")
elif name == "pacman" and args[0] == "-Q":
    if len(args) > 2:
        sys.exit(1 if os.environ.get("MISSING_MIGRATION_PACKAGES") == "1" else 0)
    sys.exit(0 if os.environ.get("KEYRING_INSTALLED") == "1" else 1)
elif name != "pacman":
    sys.exit("Unexpected mock command: " + name)
"""


def run_menu(choice, pacman="[core]\n", grub="GRUB_DEFAULT=0\n", fail=None,
             grub_command=True, grub_directory=True, skip_repo_edit=False,
             grub_custom_menu=False, included_repos=None, grub_override=False,
             grub_interrupt=False, keyring_installed=False, confirm="y",
             grub_missing_initramfs=False, grub_late_override=False,
             grub_confirm="y", grub_symlink=False, unsupported_cpu=False, grub_drop_in=None, grub_custom_config=False, root_fs="ext4", stock_no_servers=False, grub_generator=True,
             missing_migration_packages=False, grub_device_id=False, grub_unmanaged=False, lib32_installed=False, grub_preflight_failure=False, corrupt_archive=False):
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
        if grub_drop_in:
            drop_in = root / "etc/default/grub.d/custom.cfg"
            drop_in.parent.mkdir()
            drop_in.write_text(grub_drop_in)
        if grub is not None:
            if grub_symlink:
                managed = root / "etc/default/grub-managed"
                managed.write_text(grub)
                grub_path.symlink_to(managed)
            else:
                grub_path.write_text(grub)
        if grub_directory:
            (root / "boot/grub").mkdir(parents=True)
            if grub_unmanaged:
                (root / "boot/grub/grub.cfg").write_text("# hand-maintained config\n")
            if grub_custom_config:
                (root / "boot/grub/custom.cfg").write_text('set default="0"\n')
        if grub_generator:
            generator = root / "etc/grub.d/10_linux"
            generator.parent.mkdir()
            generator.touch(mode=0o755)
        source = SCRIPT.read_text()
        # Verify fixture bytes with the real checksum tool, never a success mock.
        source = re.sub(r"helperSha256='[0-9a-f]{64}'",
                        f"helperSha256='{hashlib.sha256(b'mock archive').hexdigest()}'", source)
        assert source.startswith("#!/bin/sh -e\n")
        for path in ("/etc/pacman.conf", "/etc/default", "/etc/grub.d", "/boot/grub", "/lib/ld-linux-x86-64.so.2"):
            source = source.replace(path, str(root / path.lstrip("/")))
        script = directory / SCRIPT.name
        script.write_text(source)
        script.chmod(0o755)
        notes = directory / "cachyos-repo-notes.txt"
        notes.write_text("unrelated file\n")
        common_source = (SCRIPT.parents[2] / "common-script.sh").read_text()
        menu_reader = "readMenuChoice() {" + common_source.split("readMenuChoice() {", 1)[1].split("\n}", 1)[0] + "\n}\n"
        (root / "tabs/common-script.sh").write_text(
            menu_reader +
            'checkEnv() { [ "$AUR_HELPER_CHECKED" = true ] || return 99; '
            'ESCALATION_TOOL=escalate; PACKAGER=pacman; '
            'printf checked > "$TEST_ROOT/environment-checked"; }\n'
            'command_exists() { command -v "$1" >/dev/null 2>&1; }\n'
            'checkEscalationTool() { ESCALATION_TOOL=escalate; }\n'
        )
        binaries = root / "bin"
        binaries.mkdir()
        for command in ("grep", "awk", "cat", "mktemp", "cp", "mv", "test", "sh", "sha256sum"):
            (binaries / command).symlink_to(shutil.which(command))
        commands = ["escalate", "curl", "tar", "repo-installer", "rm", "pacman", "pacman-conf", "sed", "findmnt"]
        if grub_command:
            commands.append("grub-mkconfig")
        loader = root / "lib/ld-linux-x86-64.so.2"
        loader.parent.mkdir()
        loader.write_text(f"#!{sys.executable}\n" + MOCK)
        loader.chmod(0o755)
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
        environment["ROOT_FS"] = root_fs
        if corrupt_archive:
            environment["CORRUPT_ARCHIVE"] = "1"
        if missing_migration_packages:
            environment["MISSING_MIGRATION_PACKAGES"] = "1"
        if grub_preflight_failure:
            environment["GRUB_PREFLIGHT_FAILURE"] = "1"
        if lib32_installed:
            environment["LIB32_INSTALLED"] = "1"
        if grub_device_id:
            environment["GRUB_DEVICE_ID"] = "1"
        if stock_no_servers:
            environment["STOCK_NO_SERVERS"] = "1"
        if unsupported_cpu:
            environment["UNSUPPORTED_CPU"] = "1"
        if grub_missing_initramfs:
            environment["GRUB_MISSING_INITRAMFS"] = "1"
        if grub_late_override:
            environment["GRUB_LATE_OVERRIDE"] = "bare" if grub_late_override == "bare" else "1"
        if keyring_installed:
            environment["KEYRING_INSTALLED"] = "1"
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
        answers = [str(choice)]
        if choice in (2, 3, 4, 5):
            answers.append(grub_confirm)
        answers.append(confirm)
        completed = subprocess.run(
            [str(script)], cwd=directory, env=environment,
            input="\n".join(answers) + "\n", text=True, capture_output=True, timeout=10, start_new_session=True,
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

    def test_changed_helper_archive_aborts_before_extraction(self):
        for choice, config in ((1, "[core]\n"),
                               (6, "[core]\n\n[extra]\n\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n")):
            with self.subTest(choice=choice):
                result = run_menu(choice, pacman=config, corrupt_archive=True)
                self.assertNotEqual(result["status"], 0)
                self.assertEqual(result["commands"], ["curl", "rm"])
                self.assertEqual(result["pacman"], config)
                self.assertIn("helper verification failed", result["output"])

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
        for config in ("# See [cachyos-v3] docs\nInclude = /etc/cachyos-mirrorlist\n", "[cachyos-local]\n"):
            with self.subTest(config=config):
                result = run_menu(1, pacman=config)
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

    def test_grub_preflight_preserves_managed_settings_and_requires_confirmation(self):
        for settings in ({"grub_confirm": "n"}, {"grub_symlink": True}, {"grub_drop_in": "export GRUB_DEFAULT=saved\n"}, {"grub_custom_config": True}, {"root_fs": "zfs"}, {"grub_generator": False}, {"grub_unmanaged": True}, {"grub": "GRUB_DEFAULT=0; GRUB_DISABLE_OS_PROBER=false\n"}, {"grub": 'GRUB_DEFAULT=0 GRUB_CMDLINE_LINUX="cryptdevice=foo"\n'}, {"grub": "GRUB_DEFAULT=0\nif true; then\n    GRUB_DEFAULT=0\nfi\n"}, {"grub_preflight_failure": True}, {"grub_late_override": "bare"}):
            with self.subTest(settings=settings):
                result = run_menu(3, **settings)
                self.assertNotEqual(result["status"], 0)
                self.assertEqual(result["commands"], [])
                self.assertFalse(result["environment_checked"])

    def test_inline_default_overrides_abort_before_mutations(self):
        for override in ('if true; then GRUB_DEFAULT=saved; fi', 'true; GRUB_DEFAULT=saved', 'export GRUB_DEFAULT=saved'):
            with self.subTest(override=override):
                initial = 'GRUB_DEFAULT=0\n' + override + '\n'
                result = run_menu(3, grub=initial)
                self.assertNotEqual(result["status"], 0)
                self.assertEqual(result["commands"], [])
                self.assertEqual(result["grub"], initial)
                self.assertFalse(result["environment_checked"])

    def test_install_requires_confirmation_before_upgrading_packages(self):
        result = run_menu(1, confirm="n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("replaces pacman, and upgrades system packages", result["output"])
        self.assertEqual(result["commands"], [])

    def test_unsupported_cpu_rejects_install_before_package_changes(self):
        result = run_menu(1, unsupported_cpu=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("x86-64-v3 compatible CPU", result["output"])
        self.assertEqual(result["commands"], [])

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

    def test_reset_selects_stock_when_the_previous_default_is_saved(self):
        result = run_menu(5, grub="GRUB_DEFAULT=saved\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], ["grub-mkconfig", "sed", "grub-mkconfig"])
        self.assertEqual(result["grub"], STOCK_ENTRY + "\n")

    def test_combined_remove_handles_active_repositories(self):
        result = run_menu(4, pacman="[core]\n\n[extra]\n\n[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n", grub=CACHY_DEFAULT + "\n")
        self.assert_success(result)
        self.assertEqual(result["commands"], ["curl", "tar", "grub-mkconfig", "sed", "grub-mkconfig", "repo-installer", "rm", "grub-mkconfig", "sed", "grub-mkconfig"])
        self.assertIn(["repo-installer", "--remove"], result["events"])
        self.assertEqual(result["grub"], STOCK_ENTRY + "\n")
        self.assertTrue(result["script_exists"])
        self.assertTrue(result["notes_exist"])

    def test_repo_only_removal_works_without_grub_and_skips_comments(self):
        for config in ("[core]\n\n[extra]\n\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n", "# [cachyos]\n"):
            with self.subTest(config=config):
                result = run_menu(6, pacman=config, grub=None, grub_command=False, grub_directory=False)
                self.assert_success(result)
                expected = [] if config.startswith("#") else ["curl", "tar", "repo-installer", "rm"]
                self.assertEqual(result["commands"], expected)

    def test_removal_refuses_repos_defined_in_included_files(self):
        result = run_menu(6, pacman="[core]\n[extra]\n", included_repos="[cachyos]\n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("Remove the cachyos repository manually", result["output"])
        self.assertEqual(result["commands"], [])

    def test_custom_grub_menu_preserves_original_default(self):
        for choice, initial in ((2, "GRUB_DEFAULT=0\n"), (5, CACHY_DEFAULT + "\n")):
            with self.subTest(choice=choice):
                result = run_menu(choice, pacman="[cachyos]\n", grub=initial, grub_custom_menu=True)
                self.assertNotEqual(result["status"], 0)
                diagnostic = "ambiguous boot defaults" if choice == 2 else "Could not find a GRUB entry"
                self.assertIn(diagnostic, result["output"])
                self.assertEqual(result["grub"], initial)
                self.assertFalse(result["generated"])

    def test_grub_accepts_device_path_entry_ids(self):
        result = run_menu(5, grub_device_id=True)
        self.assert_success(result)
        self.assertEqual(result["grub"], STOCK_ENTRY.replace("-test", "-/dev/sda2") + "\n")

    def test_grub_override_preserves_original_default(self):
        for override in ({"grub_override": True}, {"grub_late_override": True}, {"grub_late_override": "bare"}):
            with self.subTest(override=override):
                result = run_menu(5, grub=CACHY_ENTRY + "\n", **override)
                self.assertNotEqual(result["status"], 0)
                self.assertIn("Could not verify", result["output"])
                self.assertEqual(result["grub"], CACHY_ENTRY + "\n")
                self.assertFalse(result["generated"])

    def test_grub_interrupt_restores_original_default(self):
        result = run_menu(5, grub=CACHY_ENTRY + "\n", grub_interrupt=True)
        self.assertNotEqual(result["status"], 0)
        self.assertEqual(result["grub"], CACHY_ENTRY + "\n")
        self.assertFalse(result["generated"])

    def test_combined_removal_checks_stock_entry_before_package_changes(self):
        config = "[core]\n\n[extra]\n\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n"
        for settings in ({"grub_custom_menu": True}, {"grub_missing_initramfs": True}):
            with self.subTest(settings=settings):
                result = run_menu(4, pacman=config, **settings)
                self.assertNotEqual(result["status"], 0)
                self.assertEqual(result["pacman"], config)
                self.assertEqual(result["commands"], ["curl", "tar", "grub-mkconfig", "rm"])
                self.assertEqual(result["grub"], "GRUB_DEFAULT=0\n")

    def test_removal_reports_possible_incomplete_migration(self):
        result = run_menu(6, keyring_installed=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("package migration needs recovery", result["output"])
        self.assertEqual(result["commands"], [])

    def test_removal_refuses_nonstandard_blocks_and_requires_confirmation(self):
        standard = "[core]\n\n[extra]\n\n[cachyos]\nInclude = /etc/pacman.d/cachyos-mirrorlist\n"
        malformed = standard.replace("Include", "# Mirror\nInclude")
        duplicate = standard + "\n[cachyos] # override\nServer = https://example.invalid\n"
        for config, diagnostic in ((malformed, "standard repository block"), (duplicate, "duplicate CachyOS")):
            with self.subTest(config=config):
                result = run_menu(6, pacman=config)
                self.assertNotEqual(result["status"], 0)
                self.assertIn(diagnostic, result["output"])
                self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard, included_repos="[cachyos]\n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("duplicate CachyOS", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard, stock_no_servers=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("usable stock [core] repository", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard.replace("[core]\n\n", ""))
        self.assertNotEqual(result["status"], 0)
        self.assertIn("Enable the stock [core] repository", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard.replace("[extra]\n\n", ""))
        self.assertNotEqual(result["status"], 0)
        self.assertIn("Enable the stock [extra] repository", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard, lib32_installed=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("Enable the stock [multilib] repository", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard, missing_migration_packages=True)
        self.assertNotEqual(result["status"], 0)
        self.assertIn("keyring and mirrorlist packages are required", result["output"])
        self.assertEqual(result["commands"], [])
        result = run_menu(6, pacman=standard, confirm="n")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("downgrade system packages", result["output"])
        self.assertEqual(result["commands"], [])

    def test_download_or_extraction_failure_stops_before_running_helper(self):
        for choice, config in ((1, "[core]\n"), (4, "[core]\n\n[extra]\n\n[cachyos-v3]\nInclude = /etc/pacman.d/cachyos-v3-mirrorlist\n")):
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
