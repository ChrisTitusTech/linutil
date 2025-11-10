#!/bin/sh
# Purpose: Add Kali Linux APT repositories and keys, then install Kali packages
# Supports: Kali, Debian, Ubuntu (mixing repos is risky; requires explicit opt-in)
# Usage:
#   sudo sh kali-all-install.sh [-y] [-s SUITE] [-p "pkg1 pkg2"] [--force-mix]
# Env:
#   KALI_SUITE           Suite name: kali-rolling (default) or kali-last-snapshot
#   KALI_PACKAGES        Space-separated packages to install (default sensible set)
#   KALI_ALLOW_MIX=1     Allow adding Kali repo on non-Kali systems
#   KALI_NON_INTERACTIVE=1  Assume yes to prompts (same as -y)

set -eu

# Try to source pretty output helpers if available
SCRIPT_DIR=$(dirname -- "$0")
if [ -f "$SCRIPT_DIR/pretty-output.sh" ]; then
	# shellcheck disable=SC1090
	. "$SCRIPT_DIR/pretty-output.sh"
else
	GREEN=''
	YELLOW=''
	RED=''
	BLUE=''
	NC=''
	CHECK=''
	INFO=''
	ERROR=''
fi

say() { printf "%s\n" "$*"; }
info() { printf "%s%s%s %s\n" "$BLUE" "$INFO" "$NC" "$*"; }
ok() { printf "%s%s%s %s\n" "$GREEN" "${CHECK:-✓}" "$NC" "$*"; }
warn() { printf "%s⚠%s %s\n" "$YELLOW" "$NC" "$*"; }
err() { printf "%s%s%s %s\n" "$RED" "${ERROR:-✗}" "$NC" "$*" 1>&2; }

require_root() {
	if [ "$(id -u)" != 0 ]; then
		err "This script must be run as root. Try: sudo sh $0 ..."
		exit 1
	fi
}

have_cmd() { command -v "$1" >/dev/null 2>&1; }

detect_apt() {
	if ! have_cmd apt-get; then
		err "This script currently supports only APT-based systems (Debian/Ubuntu/Kali)."
		exit 1
	fi
}

read_os_release() {
	# Initialize values; sourced file may override. VERSION_* and NAME kept for potential future logic.
	OS_ID=""; VERSION_ID=""; VERSION_CODENAME=""; UBUNTU_CODENAME=""; NAME=""
	# shellcheck disable=SC2034 # (VERSION_ID VERSION_CODENAME UBUNTU_CODENAME NAME may be used later)
	if [ -r /etc/os-release ]; then
		# shellcheck disable=SC1091
		. /etc/os-release
	fi
}

confirm() {
	if [ "${ASSUME_YES:-0}" = "1" ]; then
		return 0
	fi
	printf "%sProceed? [y/N]%s " "$YELLOW" "$NC"
	read -r ans || true
	case "$ans" in
		y|Y|yes|YES) return 0 ;;
		*) return 1 ;;
	esac
}

ensure_keyring() {
	# Prefer the packaged keyring on Kali; otherwise fetch and install GPG key
	if [ "${OS_ID}" = "kali" ]; then
		if dpkg -s kali-archive-keyring >/dev/null 2>&1; then
			ok "kali-archive-keyring already installed."
		else
			info "Installing kali-archive-keyring..."
			apt-get update -y
			apt-get install -y --no-install-recommends kali-archive-keyring
			ok "Installed kali-archive-keyring."
		fi
		KEYRING_PATH="/usr/share/keyrings/kali-archive-keyring.gpg"
	else
		KEYRING_PATH="/usr/share/keyrings/kali-archive-keyring.gpg"
		if [ -f "$KEYRING_PATH" ]; then
			ok "Kali keyring already present at $KEYRING_PATH."
		else
			info "Fetching Kali archive signing key..."
			if have_cmd curl; then
				curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor > "$KEYRING_PATH"
			elif have_cmd wget; then
				wget -qO- https://archive.kali.org/archive-key.asc | gpg --dearmor > "$KEYRING_PATH"
			else
				err "Need curl or wget to download the Kali key."
				exit 1
			fi
			chmod 0644 "$KEYRING_PATH"
			ok "Installed keyring at $KEYRING_PATH."
		fi
	fi
}

ensure_sources_list() {
	SUITE=${KALI_SUITE:-${CLI_SUITE:-kali-rolling}}
	case "$SUITE" in
		kali-rolling|kali-last-snapshot) ;;
		*)
			warn "Unsupported suite '$SUITE'. Falling back to 'kali-rolling'."
			SUITE="kali-rolling"
			;;
	esac

	MIRROR=${KALI_MIRROR:-http://http.kali.org/kali}
	LIST_FILE=/etc/apt/sources.list.d/kali.list
	LINE="deb [signed-by=/usr/share/keyrings/kali-archive-keyring.gpg] $MIRROR $SUITE main contrib non-free non-free-firmware"

	if [ -f "$LIST_FILE" ] && grep -q "$MIRROR" "$LIST_FILE" 2>/dev/null; then
		ok "Kali APT source already configured in $LIST_FILE."
	else
		info "Adding Kali APT source to $LIST_FILE (suite: $SUITE)"
		umask 022
		printf "%s\n" "$LINE" > "$LIST_FILE"
		ok "Wrote $LIST_FILE."
	fi
}

apt_update() {
	info "Running apt-get update..."
	apt-get update -y
}

install_kali_packages() {
	# Default set aims to be useful but not enormous
	DEFAULT_PKGS="kali-linux-default kali-tools-top10"
	PKGS=${KALI_PACKAGES:-${CLI_PACKAGES:-$DEFAULT_PKGS}}
	info "Installing Kali packages: $PKGS"
	# Avoid recommended to keep install lean; adjust if you want the full set
	apt-get install -y --no-install-recommends $PKGS
	ok "Kali packages installed."
}

main() {
	require_root
	detect_apt
	read_os_release

	ASSUME_YES=${ASSUME_YES:-0}
	# Parse simple CLI flags (-y, -s, -p, --force-mix)
	CLI_SUITE=""; CLI_PACKAGES=""; FORCE_MIX=0
	while [ $# -gt 0 ]; do
		case "$1" in
			-y|--yes)
				ASSUME_YES=1
				;;
			-s|--suite)
				shift || true
				CLI_SUITE=${1:-}
				;;
			-p|--packages)
				shift || true
				CLI_PACKAGES=${1:-}
				;;
			--force-mix)
				FORCE_MIX=1
				;;
			--)
				shift; break ;;
			-h|--help)
				say "Usage: sudo sh $0 [-y] [-s SUITE] [-p \"pkg1 pkg2\"] [--force-mix]"
				exit 0
				;;
			*)
				warn "Ignoring unknown argument: $1"
				;;
		esac
		shift || true
	done

	# Non-interactive env var support
	if [ "${KALI_NON_INTERACTIVE:-}" = "1" ]; then ASSUME_YES=1; fi

	# Safety prompt for non-Kali systems
	if [ "${OS_ID}" != "kali" ]; then
		warn "You are running on '$OS_ID'. Adding Kali repositories to non-Kali systems can cause instability."
		if [ "${KALI_ALLOW_MIX:-0}" = "1" ] || [ "$FORCE_MIX" = "1" ]; then
			info "Proceeding due to explicit opt-in (KALI_ALLOW_MIX/--force-mix)."
		else
			say "Set KALI_ALLOW_MIX=1 or pass --force-mix to proceed."
			exit 2
		fi
	fi

	ensure_keyring
	ensure_sources_list
	apt_update

	if [ "${SKIP_KALI_INSTALL:-0}" = "1" ]; then
		info "SKIP_KALI_INSTALL=1 set; skipping package installation."
		exit 0
	fi

	if confirm; then
		install_kali_packages
	else
		warn "User declined to install packages. Re-run with -y to auto-confirm."
	fi
}

main "$@"

