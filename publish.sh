#!/bin/bash

set -euo pipefail

# Enforce date-based versioning (YY.MM.DD) before publishing.
# Remove leading zeros from month and day to comply with cargo fmt requirements
year=$(date +%y)
month=$(date +%-m)
day=$(date +%-d)
today_raw="${year}-${month}-${day}"
expected_version=${today_raw//-/.}

read_versions=$(python - <<'PY'
import sys


def load_toml(path: str):
		try:
				import tomllib  # Python 3.11+
		except ModuleNotFoundError:  # Fallback for older Python
				import tomli as tomllib  # type: ignore
		with open(path, "rb") as f:
				return tomllib.load(f)


workspace = load_toml("Cargo.toml")
core = load_toml("core/Cargo.toml")
tui = load_toml("tui/Cargo.toml")

workspace_version = workspace.get("workspace", {}).get("package", {}).get("version")

core_pkg = core.get("package", {})
core_version = core_pkg.get("version") or workspace_version
if isinstance(core_version, dict) and core_version.get("workspace"):
	core_version = workspace_version

linutil_core_dep = tui.get("dependencies", {}).get("linutil_core")
linutil_core_dep_version = None
if isinstance(linutil_core_dep, dict):
		linutil_core_dep_version = linutil_core_dep.get("version")

print(workspace_version or "")
print(core_version or "")
print(linutil_core_dep_version or "")
PY
)

workspace_version=$(echo "$read_versions" | sed -n '1p')
core_version=$(echo "$read_versions" | sed -n '2p')
tui_dep_version=$(echo "$read_versions" | sed -n '3p')

if [[ -z "$workspace_version" || -z "$core_version" || -z "$tui_dep_version" ]]; then
	echo "Unable to determine required versions from Cargo manifests." >&2
	exit 1
fi

if [[ "$workspace_version" != "$expected_version" ]]; then
	echo "Workspace version $workspace_version does not match today's expected $expected_version." >&2
	exit 1
fi

if [[ "$core_version" != "$expected_version" ]]; then
	echo "linutil_core package version $core_version does not match today's expected $expected_version." >&2
	exit 1
fi

if [[ "$tui_dep_version" != "$expected_version" ]]; then
	echo "linutil_tui depends on linutil_core $tui_dep_version but expected $expected_version." >&2
	exit 1
fi

echo "Version check passed: $expected_version"

echo "Running sort and format checks..."
if ! cargo sort --check --workspace; then
	echo "cargo sort check failed. Please run 'cargo sort --workspace' to fix." >&2
	exit 1
fi

if ! cargo fmt --check; then
	echo "cargo fmt check failed. Please run 'cargo fmt' to fix." >&2
	exit 1
fi

bash sort-tomlfiles.sh
cargo test --no-fail-fast --package linutil_core
cargo build --release
echo "Checks passed."

read -r -p "Publish to crates.io? [y/N]: " answer
case "$answer" in
	[Yy]*)
		cargo publish -p linutil_core
		cargo publish -p linutil_tui
		;;
	*)
		echo "Publish skipped."
		;;
esac
