#!/bin/bash
# Linutil Post-Install Orchestrator
#
# 1. Automatically runs: Basic tools + Build toolchain + Python + Node.js setup.
# 2. Then interactively lets the user select additional setup scripts to run.
#    Uses one of: gum | fzf | whiptail | dialog | select fallback.
# 3. Supports multi-selection and preserves ordering of user confirmation.
# 4. Creates a log file under $HOME/.local/share/linutil/postinstall-YYYYmmdd-HHMMSS.log
# 5. Skips scripts already executed in this session.
# 6. Idempotent best-effort: each sub-script should handle re-runs itself.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

LOG_DIR="$HOME/.local/share/linutil"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/postinstall-$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

run_and_log() {
	local name="$1"; shift
	printf "\n==> Running %s\n" "$name" | tee -a "$LOG_FILE"
	if "$@" >>"$LOG_FILE" 2>&1; then
		printf "[OK] %s\n" "$name" | tee -a "$LOG_FILE"
	else
		printf "[FAIL] %s (see log: %s)\n" "$name" "$LOG_FILE" | tee -a "$LOG_FILE"
		return 1
	fi
}

printf "\n[basic] Installing baseline packages...\n"
run_and_log "Basic Tools" "$SCRIPT_DIR/system-setup/basic-tools.sh" || true
printf "\n[build] Installing build toolchain...\n"
run_and_log "Build Tools" "$SCRIPT_DIR/system-setup/build-tools.sh" || true

printf "\nInitial mandatory setup complete.\n" | tee -a "$LOG_FILE"

# --- Candidate optional scripts (relative paths under current directory) ---
# Add new items here as needed.
declare -A OPTIONAL_SCRIPTS=(
	["My Shell Setup"]="applications-setup/myshell-setup.sh"
	["Flatpak / Flathub"]="applications-setup/setup-flatpak.sh"
	["Rofi"]="DE-Scripts/rofi-setup.sh"
	["Docker"]="applications-setup/docker-setup.sh"
	["Podman"]="applications-setup/podman-setup.sh"
	["Podman Compose"]="applications-setup/podman-compose-setup.sh"
	["Ghostty Terminal"]="applications-setup/ghostty-setup.sh"
	["Kitty Terminal"]="applications-setup/kitty-setup.sh"
	["Fastfetch"]="applications-setup/fastfetch-setup.sh"
	["Neovim Config"]="applications-setup/developer-tools/neovim.sh"
	["Alacritty Terminal"]="applications-setup/alacritty-setup.sh"
	["Waydroid (Android Layer)"]="applications-setup/waydroid-setup.sh"
	["Linutil Installer"]="applications-setup/linutil-installer.sh"
	["Linutil Updater"]="applications-setup/linutil-updater.sh"
)

selection_menu() {
	local items=()
	for key in "${!OPTIONAL_SCRIPTS[@]}"; do
		items+=("$key")
	done
	# Sort the list for deterministic order
	# Stable sorted order without word-splitting issues
	mapfile -t items < <(printf '%s\n' "${items[@]}" | sort)

	# Auto-detect a multi-select tool
	if command -v gum >/dev/null 2>&1; then
		gum choose --no-limit "${items[@]}"
	elif command -v fzf >/dev/null 2>&1; then
		printf '%s\n' "${items[@]}" | fzf --multi --prompt "Select additional setups > "
	elif command -v whiptail >/dev/null 2>&1; then
		local opts=()
		for item in "${items[@]}"; do opts+=("$item" "" OFF); done
		whiptail --title "Linutil Postinstall" --checklist "Select optional setup scripts" 25 78 15 "${opts[@]}" 3>&1 1>&2 2>&3 | sed 's/\"//g'
	elif command -v dialog >/dev/null 2>&1; then
		local opts=()
		for item in "${items[@]}"; do opts+=("$item" "" off); done
	dialog --separate-output --checklist "Select optional setup scripts" 25 78 15 "${opts[@]}" 3>&1 1>&2 2>&3
	else
		printf "\nNo advanced UI tool found. Using simple numbered selection.\n"
		printf "Enter numbers separated by spaces (or press Enter to skip):\n"
		local i=1
		for item in "${items[@]}"; do
			printf "%2d) %s\n" "$i" "$item"
			i=$((i+1))
		done
		printf "Selection: "
		read -r nums || true
		local chosen=()
		for n in $nums; do
			if [[ $n =~ ^[0-9]+$ ]] && (( n>=1 && n<=${#items[@]} )); then
				chosen+=("${items[$((n-1))]}")
			fi
		done
		printf '%s\n' "${chosen[@]}"
	fi
}

printf "\nSelect additional setup scripts to run (multi-select).\n"
SELECTED=$(selection_menu || true)

if [[ -z ${SELECTED// /} ]]; then
	printf "No optional scripts selected. Exiting.\n" | tee -a "$LOG_FILE"
	exit 0
fi

printf "\nChosen scripts:\n%s\n" "$SELECTED" | tee -a "$LOG_FILE"

declare -A RUN_ONCE
FAILURES=0

while IFS= read -r line; do
	[[ -z $line ]] && continue
	[[ -n ${RUN_ONCE[$line]:-} ]] && { printf "Skipping duplicate: %s\n" "$line" | tee -a "$LOG_FILE"; continue; }
	RUN_ONCE[$line]=1
	script_rel="${OPTIONAL_SCRIPTS[$line]}"
	if [[ -z $script_rel ]]; then
		printf "Unknown mapping for '%s'\n" "$line" | tee -a "$LOG_FILE"
		continue
	fi
	script_path="$SCRIPT_DIR/$script_rel"
	if [[ ! -f $script_path ]]; then
		printf "Missing script: %s\n" "$script_path" | tee -a "$LOG_FILE"
		((FAILURES++))
		continue
	fi
	if [[ ! -x $script_path ]]; then
		chmod +x "$script_path" || true
	fi
	printf "\n--- Executing %s (%s) ---\n" "$line" "$script_rel" | tee -a "$LOG_FILE"
	if "$script_path" >>"$LOG_FILE" 2>&1; then
		printf "[OK] %s\n" "$line" | tee -a "$LOG_FILE"
	else
		printf "[FAIL] %s (see log)\n" "$line" | tee -a "$LOG_FILE"
		((FAILURES++))
	fi
done <<<"$SELECTED"

printf "\nPostinstall complete. Log: %s\n" "$LOG_FILE"
if (( FAILURES > 0 )); then
	printf "%d script(s) failed. Review the log for details.\n" "$FAILURES"
	exit 1
fi
exit 0