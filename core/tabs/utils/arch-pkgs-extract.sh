#!/usr/bin/env bash

# Script to extract installed Arch packages from pacman & AUR and save them to arch-packages.md
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
OUTPUT_FILE="${REPO_ROOT}/output/arch-packages.md"

if ! command -v pacman >/dev/null 2>&1; then
	printf 'Error: pacman command not found in PATH\n' >&2
	exit 1
fi

mkdir -p "${REPO_ROOT}/output"

explicit_list="$(pacman -Qqe 2>/dev/null || true)"
aur_list="$(pacman -Qqm 2>/dev/null || true)"

official_sorted=""
if [[ -n ${explicit_list} ]]; then
	if [[ -n ${aur_list} ]]; then
		official_sorted="$(comm -23 <(printf '%s\n' "${explicit_list}" | sort -u) <(printf '%s\n' "${aur_list}" | sort -u))"
	else
		official_sorted="$(printf '%s\n' "${explicit_list}" | sort -u)"
	fi
fi

aur_sorted=""
if [[ -n ${aur_list} ]]; then
	aur_sorted="$(printf '%s\n' "${aur_list}" | sort -u)"
fi

official=()
aur=()

if [[ -n ${official_sorted} ]]; then
	mapfile -t official < <(printf '%s\n' "${official_sorted}")
fi

if [[ -n ${aur_sorted} ]]; then
	mapfile -t aur < <(printf '%s\n' "${aur_sorted}")
fi

{
	printf '# Arch Packages\n\n'
	printf 'Generated on %s\n\n' "$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
	printf '## Official (pacman)\n\n'
	if [[ ${#official[@]} -eq 0 ]]; then
		printf '_No explicit repo packages found._\n\n'
	else
		for pkg in "${official[@]}"; do
			echo "- ${pkg}"
		done
		echo ""
	fi
	printf '## AUR (foreign)\n\n'
	if [[ ${#aur[@]} -eq 0 ]]; then
		printf '_No foreign packages found._\n'
	else
		for pkg in "${aur[@]}"; do
			echo "- ${pkg}"
		done
		echo ""
	fi
} >"${OUTPUT_FILE}"

printf 'Wrote %d official and %d AUR packages to %s\n' "${#official[@]}" "${#aur[@]}" "${OUTPUT_FILE}"