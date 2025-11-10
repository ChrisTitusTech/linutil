#!/usr/bin/env bash
# script to extract KDE shortcuts and save them to /output/kde-shortcuts.md
set -euo pipefail
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/output"
OUTPUT_FILE="${OUTPUT_DIR}/kde-shortcuts.md"
CONFIG_FILE="${HOME}/.config/kglobalshortcutsrc"

mkdir -p "${OUTPUT_DIR}"

if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "KDE shortcuts file not found at ${CONFIG_FILE}" >&2
  exit 1
fi

TMP_FILE="$(mktemp)"

cleanup() {
	rm -f "${TMP_FILE}"
}

trap cleanup EXIT

export CONFIG_FILE

# Use Python to handle the slightly irregular INI structure produced by kglobalshortcutsrc.
python3 <<'PY' > "${TMP_FILE}"
import datetime
import os

config_path = os.environ["CONFIG_FILE"]
sections = {}
current_section = None

with open(config_path, "r", encoding="utf-8") as handle:
	for raw_line in handle:
		line = raw_line.strip()
		if not line or line.startswith("#"):
			continue
		if line.startswith("[") and line.endswith("]"):
			current_section = line[1:-1].strip()
			continue
		if current_section is None or "=" not in line:
			continue

		action, value = line.split("=", 1)
		action = action.strip()
		value = value.strip()
		if not value:
			continue

		if value.count(";") >= 2:
			parts = value.split(";")
		else:
			parts = value.split(",", 2)

		while len(parts) < 3:
			parts.append("")

		primary, alternate, component = parts[:3]
		remainder = parts[3:]

		def tidy(sequence: str) -> str:
			sequence = sequence.strip()
			if not sequence or sequence.lower() == "none":
				return ""
			sequence = sequence.replace("\\t", ", ")
			return sequence

		primary = tidy(primary)
		alternate = tidy(alternate)
		component = component.strip()

		extra_details = [item.strip() for item in remainder if item.strip()]
		if not primary and not alternate:
			continue

		sections.setdefault(current_section, []).append(
			{
				"action": action,
				"primary": primary,
				"alternate": alternate,
				"component": component,
				"details": extra_details,
			}
		)

timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")

def sanitize(value: str) -> str:
	if not value:
		return "-"
	return value.replace("|", "\\|")

print("# KDE Global Shortcuts")
print()
print(f"Exported at {timestamp}")
print()

if not sections:
	print(f"No shortcuts with active bindings were found in {config_path}.")
else:
	for section in sorted(sections):
		entries = sorted(sections[section], key=lambda item: item["action"].lower())
		print(f"## {section}")
		print()
		print("| Action | Primary | Alternate | Component | Notes |")
		print("| --- | --- | --- | --- | --- |")
		for entry in entries:
			notes = "; ".join(entry["details"]) if entry["details"] else ""
			print(
				"| {action} | {primary} | {alternate} | {component} | {notes} |".format(
					action=sanitize(entry["action"]),
					primary=sanitize(entry["primary"]),
					alternate=sanitize(entry["alternate"]),
					component=sanitize(entry["component"]),
					notes=sanitize(notes),
				)
			)
	print()
PY

mv "${TMP_FILE}" "${OUTPUT_FILE}"
trap - EXIT

echo "KDE shortcuts exported to ${OUTPUT_FILE}"
