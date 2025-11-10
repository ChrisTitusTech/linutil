#!/usr/bin/env bash

# install-flatpaks.sh
#
# Parse the markdown inventory at output/flatpaks.md and install (or list) the
# Flatpak applications it documents. Automatically groups app IDs by their
# configured remotes (e.g. flathub, newelle-origin) so we don't have to type
# each one manually.
#
# Features:
#  - Idempotent: skips apps already installed (unless --force provided)
#  - --dry-run: show what would be installed (grouped per remote)
#  - --list: just list IDs grouped by remote
#  - Custom file path via argument or FLATPAKS_MD env var
#  - Graceful handling of parsing anomalies
#
# Requirements: bash >= 4 (associative arrays), flatpak CLI

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

DEFAULT_FILE="${REPO_ROOT}/output/flatpaks.md"
MARKDOWN_FILE="${FLATPAKS_MD:-$DEFAULT_FILE}"

DRY_RUN=0
LIST_ONLY=0
FORCE=0

usage() {
  cat <<EOF
Usage: $0 [options] [path/to/flatpaks.md]

Options:
  -n, --dry-run    Show the flatpak install commands that would run
  -l, --list       List app IDs grouped by remote; do not install
  -f, --force      Attempt install even if already present
  -h, --help       Show this help

Environment:
  FLATPAKS_MD  Override location of markdown file (default: ${DEFAULT_FILE})

Exit codes:
  0 success | 1 general error | 2 parse error | 3 missing file
EOF
}

log() { printf '\e[1;32m[install-flatpaks]\e[0m %s\n' "$*"; }
warn() { printf '\e[1;33m[warn]\e[0m %s\n' "$*" >&2; }
err() { printf '\e[1;31m[error]\e[0m %s\n' "$*" >&2; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run) DRY_RUN=1; shift;;
    -l|--list) LIST_ONLY=1; shift;;
    -f|--force) FORCE=1; shift;;
    -h|--help) usage; exit 0;;
    -*) err "Unknown option: $1"; usage; exit 1;;
    *) MARKDOWN_FILE="$1"; shift;;
  esac
done

if [[ ! -f "$MARKDOWN_FILE" ]]; then
  err "Markdown file not found: $MARKDOWN_FILE"
  exit 3
fi

if ! command -v flatpak >/dev/null 2>&1; then
  err "flatpak command not found in PATH"
  exit 1
fi

declare -A APP_REMOTE

# Use awk to pair each app id with its remote.
mapfile -t parsed < <(awk '
  BEGIN { pending="" }
  /^- \*\*/ {
     # Extract text inside (`...`)
     if (match($0, /\(`[^`]+`\)/)) {
        raw=substr($0, RSTART+2, RLENGTH-4); pending=raw; next
     }
  }
  /- Remote:/ {
     if (pending != "") {
        if (match($0, /- Remote: [A-Za-z0-9_.:-]+/)) {
          rem=$0; sub(/.*- Remote: /, "", rem); printf "%s %s\n", pending, rem; pending="";
        }
     }
  }
' "$MARKDOWN_FILE")

for row in "${parsed[@]}"; do
  app="${row%% *}"; remote="${row##* }"
  [[ -n $app && -n $remote ]] || continue
  APP_REMOTE["$app"]="$remote"
done

if [[ ${#APP_REMOTE[@]} -eq 0 ]]; then
  err "No applications parsed. Check file format."
  exit 2
fi

# Group by remote
declare -A REMOTE_GROUPS
for id in "${!APP_REMOTE[@]}"; do
  remote=${APP_REMOTE[$id]}
  if [[ -z ${REMOTE_GROUPS[$remote]:-} ]]; then
    REMOTE_GROUPS[$remote]="$id"
  else
    REMOTE_GROUPS[$remote]+=" $id"
  fi
done

is_installed() {
  local app_id="$1"
  flatpak info "$app_id" >/dev/null 2>&1
}

print_groups() {
  for remote in "${!REMOTE_GROUPS[@]}"; do
    printf '\nRemote: %s\n' "$remote"
    for id in ${REMOTE_GROUPS[$remote]}; do
      printf '  %s' "$id"
      if is_installed "$id"; then
        printf ' (installed)'
      fi
      printf '\n'
    done
  done | sort
}

if (( LIST_ONLY )); then
  print_groups
  exit 0
fi

# Build install commands per remote, filtering already installed unless --force
INSTALL_COMMANDS=()
for remote in "${!REMOTE_GROUPS[@]}"; do
  ids_to_install=()
  for id in ${REMOTE_GROUPS[$remote]}; do
    if (( FORCE )) || ! is_installed "$id"; then
      ids_to_install+=("$id")
    fi
  done
  if [[ ${#ids_to_install[@]} -gt 0 ]]; then
    INSTALL_COMMANDS+=("flatpak install -y ${remote} ${ids_to_install[*]}")
  else
    log "All apps already installed for remote ${remote} (use --force to reinstall)"
  fi
done

if (( DRY_RUN )); then
  log "Dry-run mode: showing commands only"
  for cmd in "${INSTALL_COMMANDS[@]}"; do
    echo "$cmd"
  done
  exit 0
fi

if [[ ${#INSTALL_COMMANDS[@]} -eq 0 ]]; then
  log "Nothing to install."
  exit 0
fi

log "Installing ${#INSTALL_COMMANDS[@]} remote group(s)..."
for cmd in "${INSTALL_COMMANDS[@]}"; do
  log "Running: $cmd"
  # shellcheck disable=SC2086
  if ! eval "$cmd"; then
    err "Failed: $cmd"
    exit 1
  fi
done

log "Done."
