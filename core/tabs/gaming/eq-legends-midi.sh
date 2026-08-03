#!/bin/sh -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)
# shellcheck source=core/tabs/common-script.sh
. "$SCRIPT_DIR/../common-script.sh"

# Setup and SoundFont source: https://eqlwiki.com/Linux_Setup_Guide
SOUNDFONT_NAME="SC-55 Roland SOUNDCanvas Up.sf2"
SOUNDFONT_URL="https://archive.org/download/500-soundfonts-full-gm-sets/500_Soundfonts_Full_GM_Sets.zip/SC-55%20Roland%20SOUNDCanvas%20Up.sf2"
SOUNDFONT_SHA256="ce26d477924b95da58b1b00bfd11c6f8580bf7ecf0b2c64db10dbfe4a9927714"

DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
HOOK_DIR="$DATA_HOME/lutris/scripts"
SOUNDFONT_DIR="$DATA_HOME/sounds/sf2"
SOUNDFONT_PATH="$SOUNDFONT_DIR/$SOUNDFONT_NAME"
LUTRIS_GAMES_DIR="$CONFIG_HOME/lutris/games"
START_HOOK="$HOOK_DIR/eq-midi-start.sh"
STOP_HOOK="$HOOK_DIR/eq-midi-stop.sh"
MIDI_CLIENT_NAME="EQ-Legends"
MIDI_DEVICE_NAME="$MIDI_CLIENT_NAME - $MIDI_CLIENT_NAME"

CANDIDATES_FILE=""
DOWNLOAD_TMP=""
HOOK_TMP=""
CONFIG_PATH=""
PREFIX_PATH=""

cleanup() {
	[ -z "$CANDIDATES_FILE" ] || rm -f "$CANDIDATES_FILE"
	[ -z "$DOWNLOAD_TMP" ] || rm -f "$DOWNLOAD_TMP"
	[ -z "$HOOK_TMP" ] || rm -f "$HOOK_TMP"
}

trap cleanup 0
trap 'cleanup; exit 1' HUP INT TERM

fail() {
	printf "%b\n" "${RED}$*${RC}" >&2
	exit 1
}

check_requirements() {
	command_exists lutris || fail "Native Lutris is required. Flatpak Lutris is not supported by this fix."
	command_exists python3 || fail "Python 3 is required by the native Lutris installation."
	command_exists pgrep || fail "pgrep is required to ensure the Wine prefix is not in use."
	command_exists sha256sum || fail "sha256sum is required to verify the downloaded SoundFont."
	command_exists flock || fail "flock is required by the FluidSynth lifecycle hooks."
	command_exists ps || fail "ps is required by the FluidSynth lifecycle hooks."
	command_exists stat || fail "stat is required by the FluidSynth lifecycle hooks."
	command_exists curl || fail "curl is required to download the SoundFont."

	if ! python3 -c 'import yaml' >/dev/null 2>&1; then
		fail "The Python YAML module used by Lutris is missing. Reinstall native Lutris, then retry."
	fi

	if pgrep -u "$(id -u)" -f '(^|/)lutris([[:space:]]|$)' >/dev/null 2>&1; then
		fail "Close Lutris before applying the EverQuest Legends MIDI fix."
	fi

	[ -d "$LUTRIS_GAMES_DIR" ] || fail "No native Lutris game configuration directory was found at $LUTRIS_GAMES_DIR."
}

find_wine_prefix() {
	PREFIX_PATH=$(
		python3 - "$CONFIG_PATH" <<'PYTHON'
import os
import sys
from pathlib import Path

import yaml

config_path = Path(sys.argv[1])
try:
    with config_path.open("r", encoding="utf-8") as config_file:
        config = yaml.safe_load(config_file) or {}
except (OSError, yaml.YAMLError) as error:
    print(f"Unable to read Lutris configuration {config_path}: {error}", file=sys.stderr)
    raise SystemExit(1)

game = config.get("game")
prefix = game.get("prefix") if isinstance(game, dict) else None
if not isinstance(prefix, str) or not prefix:
    print(f"No Wine prefix is defined in {config_path}.", file=sys.stderr)
    raise SystemExit(1)

prefix_path = Path(os.path.expandvars(os.path.expanduser(prefix)))
if not prefix_path.is_absolute():
    print(f"The Wine prefix path is not absolute: {prefix_path}", file=sys.stderr)
    raise SystemExit(1)
if not prefix_path.is_dir():
    print(f"The Wine prefix does not exist: {prefix_path}", file=sys.stderr)
    raise SystemExit(1)

print(prefix_path)
PYTHON
	) || fail "Unable to locate the EverQuest Legends Wine prefix."

	printf "%b\n" "${CYAN}Using Wine prefix: $PREFIX_PATH${RC}"
}

check_wine_prefix_idle() {
	if pgrep -u "$(id -u)" -f '(^|[\\/])(wineserver(64)?|winedevice([.]exe)?|eqgame([.]exe)?)([[:space:]]|$)' >/dev/null 2>&1; then
		fail "Close all Wine applications before updating the EverQuest Legends MIDI mapper."
	fi
}

configure_midi_mapper() {
	python3 - "$PREFIX_PATH" "$MIDI_DEVICE_NAME" <<'PYTHON'
import os
import re
import shutil
import stat
import sys
import tempfile
import time
from pathlib import Path

prefix_path = Path(sys.argv[1])
device_name = sys.argv[2]
registry_path = prefix_path / "user.reg"
backup_path = registry_path.with_name(registry_path.name + ".linutil-eq-midi.bak")
target_key = r"Software\\Microsoft\\Windows\\CurrentVersion\\Multimedia\\MIDIMap"

if registry_path.is_symlink():
    print(f"Refusing symbolic-link Wine registry: {registry_path}", file=sys.stderr)
    raise SystemExit(1)
if not registry_path.is_file():
    print(f"Wine user registry not found: {registry_path}", file=sys.stderr)
    raise SystemExit(1)

try:
    registry_text = registry_path.read_text(encoding="utf-8")
except OSError as error:
    print(f"Unable to read {registry_path}: {error}", file=sys.stderr)
    raise SystemExit(1)

header_pattern = re.compile(r"^\[([^]]+)](?: [0-9]+)?$", re.MULTILINE)
headers = list(header_pattern.finditer(registry_text))
target_match = next((match for match in headers if match.group(1) == target_key), None)

desired_values = {
    "CurrentInstrument": f'"{device_name}"',
    "UseScheme": "dword:00000000",
    "szPname": f'"{device_name}"',
}

if target_match:
    section_start = target_match.start()
    next_header = next((match for match in headers if match.start() > section_start), None)
    section_end = next_header.start() if next_header else len(registry_text)
    section = registry_text[section_start:section_end]
    section_body = section.rstrip("\n")
    for value_name, encoded_value in desired_values.items():
        value_pattern = re.compile(rf'^"{re.escape(value_name)}"=.*$', re.MULTILINE)
        value_line = f'"{value_name}"={encoded_value}'
        if value_pattern.search(section_body):
            section_body = value_pattern.sub(value_line, section_body, count=1)
        else:
            section_body += "\n" + value_line
    updated_text = registry_text[:section_start] + section_body + "\n\n" + registry_text[section_end:].lstrip("\n")
else:
    now = time.time()
    unix_time = int(now)
    windows_filetime = int((now + 11644473600) * 10000000)
    value_lines = "\n".join(
        f'"{value_name}"={encoded_value}'
        for value_name, encoded_value in desired_values.items()
    )
    new_section = (
        f"[{target_key}] {unix_time}\n"
        f"#time={windows_filetime:x}\n"
        f"{value_lines}\n\n"
    )
    insertion_match = next((match for match in headers if match.group(1) > target_key), None)
    insertion_point = insertion_match.start() if insertion_match else len(registry_text)
    prefix = registry_text[:insertion_point].rstrip("\n") + "\n\n"
    suffix = registry_text[insertion_point:].lstrip("\n")
    updated_text = prefix + new_section + suffix

if updated_text == registry_text:
    print(f"Wine MIDI mapper already targets {device_name}.")
    raise SystemExit(0)

try:
    if not backup_path.exists():
        shutil.copy2(registry_path, backup_path)
    descriptor, temp_name = tempfile.mkstemp(
        prefix=registry_path.name + ".", suffix=".tmp", dir=registry_path.parent
    )
    try:
        with os.fdopen(descriptor, "w", encoding="utf-8") as temp_file:
            temp_file.write(updated_text)
        os.chmod(temp_name, stat.S_IMODE(registry_path.stat().st_mode))
        os.replace(temp_name, registry_path)
    except BaseException:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
        raise
except OSError as error:
    print(f"Unable to update {registry_path}: {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"Wine MIDI mapper set to {device_name}.")
print(f"Original Wine user registry: {backup_path}")
PYTHON
}

find_game_config() {
	CANDIDATES_FILE=$(mktemp)

	for config_file in "$LUTRIS_GAMES_DIR"/*.yml "$LUTRIS_GAMES_DIR"/*.yaml; do
		[ -f "$config_file" ] || continue
		if grep -qi "EverQuest Legends" "$config_file" && grep -q "LaunchPad.exe" "$config_file"; then
			printf "%s\n" "$config_file" >>"$CANDIDATES_FILE"
		fi
	done

	candidate_count=$(wc -l <"$CANDIDATES_FILE" | tr -d '[:space:]')
	case "$candidate_count" in
	0)
		fail "No EverQuest Legends configuration was found in native Lutris. Install the game first, then retry."
		;;
	1)
		CONFIG_PATH=$(sed -n '1p' "$CANDIDATES_FILE")
		;;
	*)
		printf "%b\n" "${YELLOW}Multiple EverQuest Legends configurations were found:${RC}"
		nl -b a "$CANDIDATES_FILE"
		printf "%s" "Select the configuration to update [1-$candidate_count]: "
		read -r selection
		case "$selection" in
		'' | *[!0-9]*) fail "Invalid configuration selection." ;;
		esac
		[ "$selection" -ge 1 ] && [ "$selection" -le "$candidate_count" ] || fail "Invalid configuration selection."
		CONFIG_PATH=$(sed -n "${selection}p" "$CANDIDATES_FILE")
		;;
	esac

	printf "%b\n" "${CYAN}Using Lutris configuration: $CONFIG_PATH${RC}"
}

edit_lutris_config() {
	action="$1"

	python3 - "$action" "$CONFIG_PATH" "$START_HOOK" "$STOP_HOOK" <<'PYTHON'
import os
import shutil
import stat
import sys
import tempfile
from pathlib import Path

import yaml

action, config_name, start_hook, stop_hook = sys.argv[1:]
config_path = Path(config_name)

try:
    with config_path.open("r", encoding="utf-8") as config_file:
        config = yaml.safe_load(config_file) or {}
except (OSError, yaml.YAMLError) as error:
    print(f"Unable to read Lutris configuration {config_path}: {error}", file=sys.stderr)
    raise SystemExit(1)

if not isinstance(config, dict):
    print(f"Lutris configuration {config_path} is not a YAML mapping.", file=sys.stderr)
    raise SystemExit(1)

system = config.get("system")
if system is None:
    system = {}
elif not isinstance(system, dict):
    print(f"The top-level system section in {config_path} is not a YAML mapping.", file=sys.stderr)
    raise SystemExit(1)

desired_hooks = {
    "prelaunch_command": start_hook,
    "postexit_command": stop_hook,
}
for key, desired_value in desired_hooks.items():
    current_value = system.get(key)
    if current_value not in (None, "", desired_value):
        print(
            f"Refusing to replace existing Lutris setting {key}: {current_value}",
            file=sys.stderr,
        )
        raise SystemExit(1)

if action == "check":
    raise SystemExit(0)
if action != "apply":
    print(f"Unknown configuration action: {action}", file=sys.stderr)
    raise SystemExit(1)

backup_path = config_path.with_name(config_path.name + ".linutil-eq-midi.bak")
if not backup_path.exists():
    try:
        shutil.copy2(config_path, backup_path)
    except OSError as error:
        print(f"Unable to back up {config_path}: {error}", file=sys.stderr)
        raise SystemExit(1)

system.update(desired_hooks)
system["prelaunch_wait"] = True
config["system"] = system

temp_name = None
try:
    descriptor, temp_name = tempfile.mkstemp(
        prefix=config_path.name + ".", suffix=".tmp", dir=config_path.parent
    )
    with os.fdopen(descriptor, "w", encoding="utf-8") as temp_file:
        yaml.safe_dump(
            config,
            temp_file,
            allow_unicode=True,
            default_flow_style=False,
            sort_keys=False,
        )
    os.chmod(temp_name, stat.S_IMODE(config_path.stat().st_mode))
    os.replace(temp_name, config_path)
except (OSError, yaml.YAMLError) as error:
    if temp_name:
        try:
            os.unlink(temp_name)
        except FileNotFoundError:
            pass
    print(f"Unable to update {config_path}: {error}", file=sys.stderr)
    raise SystemExit(1)
PYTHON
}

install_dependencies() {
	if command_exists fluidsynth aconnect; then
		printf "%b\n" "${GREEN}FluidSynth and ALSA MIDI tools are already installed.${RC}"
		return 0
	fi

	checkEnv
	printf "%b\n" "${YELLOW}Installing FluidSynth and ALSA MIDI tools...${RC}"
	case "$PACKAGER" in
	pacman)
		"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fluidsynth alsa-utils
		;;
	apt-get | nala)
		"$ESCALATION_TOOL" "$PACKAGER" install -y fluidsynth alsa-utils
		;;
	dnf)
		"$ESCALATION_TOOL" "$PACKAGER" install -y fluidsynth alsa-utils
		;;
	zypper)
		"$ESCALATION_TOOL" "$PACKAGER" -n install fluidsynth alsa-utils
		;;
	apk)
		"$ESCALATION_TOOL" "$PACKAGER" add fluidsynth alsa-utils
		;;
	xbps-install)
		"$ESCALATION_TOOL" "$PACKAGER" -Sy fluidsynth alsa-utils
		;;
	eopkg)
		"$ESCALATION_TOOL" "$PACKAGER" install -y fluidsynth alsa-utils
		;;
	*)
		fail "Unsupported package manager: $PACKAGER"
		;;
	esac

	command_exists fluidsynth aconnect || fail "FluidSynth or aconnect is still unavailable after package installation."
}

verify_soundfont() {
	soundfont_file="$1"
	actual_checksum=$(sha256sum "$soundfont_file" | awk '{print $1}')
	[ "$actual_checksum" = "$SOUNDFONT_SHA256" ]
}

install_soundfont() {
	if [ -f "$SOUNDFONT_PATH" ]; then
		if verify_soundfont "$SOUNDFONT_PATH"; then
			printf "%b\n" "${GREEN}The verified SC-55 SoundFont is already installed.${RC}"
			return 0
		fi
		fail "The existing SoundFont failed checksum verification: $SOUNDFONT_PATH"
	fi

	mkdir -p "$SOUNDFONT_DIR"
	DOWNLOAD_TMP=$(mktemp "$SOUNDFONT_DIR/.eq-legends-midi.XXXXXX")

	printf "%b\n" "${YELLOW}Downloading the 177 MiB SC-55 SoundFont...${RC}"
	curl --fail --location --retry 3 --output "$DOWNLOAD_TMP" "$SOUNDFONT_URL"

	verify_soundfont "$DOWNLOAD_TMP" || fail "The downloaded SC-55 SoundFont failed checksum verification."
	chmod 0644 "$DOWNLOAD_TMP"
	mv "$DOWNLOAD_TMP" "$SOUNDFONT_PATH"
	DOWNLOAD_TMP=""
	printf "%b\n" "${GREEN}SC-55 SoundFont installed and verified.${RC}"
}

copy_hook() {
	source_hook="$1"
	target_hook="$2"
	target_backup="$target_hook.linutil-eq-midi.bak"

	[ ! -L "$target_hook" ] || fail "Refusing symbolic-link hook path: $target_hook"
	if [ -e "$target_hook" ]; then
		[ -f "$target_hook" ] || fail "Refusing non-file hook path: $target_hook"
		source_checksum=$(sha256sum "$source_hook")
		source_checksum=${source_checksum%% *}
		target_checksum=$(sha256sum "$target_hook")
		target_checksum=${target_checksum%% *}
		if [ "$source_checksum" = "$target_checksum" ]; then
			chmod 0755 "$target_hook"
			return 0
		fi

		[ ! -L "$target_backup" ] || fail "Refusing symbolic-link hook backup path: $target_backup"
		if [ ! -e "$target_backup" ]; then
			cp -p "$target_hook" "$target_backup"
			printf "%b\n" "${CYAN}Original hook backup: $target_backup${RC}"
		elif [ ! -f "$target_backup" ]; then
			fail "Refusing non-file hook backup path: $target_backup"
		fi
	fi

	HOOK_TMP=$(mktemp "$HOOK_DIR/.eq-legends-midi-hook.XXXXXX")
	cp "$source_hook" "$HOOK_TMP"
	chmod 0755 "$HOOK_TMP"
	mv "$HOOK_TMP" "$target_hook"
	HOOK_TMP=""
}

install_hooks() {
	mkdir -p "$HOOK_DIR"
	copy_hook "$SCRIPT_DIR/eq-legends-midi-start.sh" "$START_HOOK"
	copy_hook "$SCRIPT_DIR/eq-legends-midi-stop.sh" "$STOP_HOOK"
}

main() {
	check_requirements
	find_game_config
	find_wine_prefix
	check_wine_prefix_idle
	edit_lutris_config check
	install_dependencies
	install_soundfont
	install_hooks
	check_wine_prefix_idle
	configure_midi_mapper
	edit_lutris_config apply

	printf "%b\n" "${GREEN}EverQuest Legends MIDI support is configured.${RC}"
	printf "%b\n" "${CYAN}FluidSynth will start as $MIDI_CLIENT_NAME before the game and stop after it exits.${RC}"
	printf "%b\n" "${CYAN}Wine MIDI output is mapped to $MIDI_DEVICE_NAME.${RC}"
	printf "%b\n" "${CYAN}Original Lutris configuration: ${CONFIG_PATH}.linutil-eq-midi.bak${RC}"
}

main "$@"
