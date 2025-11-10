#!/usr/bin/env bash
# Script to get a list of installed Flatpaks for backup purposes
# Outputs a markdown file with Flatpak IDs grouped by remote

set -euo pipefail
# Outputs to /output/flatpaks.md
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_DIR="${REPO_ROOT}/output"
OUTPUT_FILE="${OUTPUT_DIR}/flatpaks.md"

mkdir -p "${OUTPUT_DIR}"

flatpak list --app --columns=application,origin | \
  awk 'NR>1 {apps[$2]=apps[$2]"\n- "$1} END {for (remote in apps) print "## "remote"\n"apps[remote]"\n"}' \
  > "${OUTPUT_FILE}"
echo "Flatpak list saved to ${OUTPUT_FILE}"
# End of script
#------------------------------------------------------------------------------