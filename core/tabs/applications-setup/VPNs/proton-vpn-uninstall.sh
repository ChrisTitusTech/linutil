#!/bin/sh

# Cross-distro Proton VPN uninstaller for Debian/Ubuntu, Fedora, and Arch-based systems.
# Removes the app, repository package, and conditionally cleans up NetworkManager kill switch profiles.

set -eu

. ../../common-script.sh

have_cmd() { command -v "$1" >/dev/null 2>&1; }

info() { printf '%s\n' "$*"; }
warn() { printf 'WARN: %s\n' "$*" 1>&2; }
err()  { printf 'ERROR: %s\n' "$*" 1>&2; }

checkDistro
echo "Detected distro ID: $DTYPE"

# Common function to remove NetworkManager kill switch profiles if active
cleanup_killswitch() {
	if have_cmd nmcli; then
		# List active connection names and filter for pvpn-* (killswitch / leak protection profiles)
		ACTIVE_PVPN_NAMES=$(nmcli -t -f NAME connection show --active 2>/dev/null | grep -E '^pvpn-' || true)

		if [ -n "${ACTIVE_PVPN_NAMES}" ]; then
			info "Active Proton VPN kill switch profiles detected. Removing..."
			# Delete each active pvpn-* connection
			# These are typically: pvpn-killswitch, pvpn-ipv6leak-protection, pvpn-routed-killswitch
			# Deleting requires privileges when connections are system-wide
			if have_cmd sudo; then SUDO=sudo; else SUDO=""; fi
			for name in ${ACTIVE_PVPN_NAMES}; do
				info "Deleting NetworkManager connection: ${name}"
				${SUDO} nmcli connection delete "${name}" || warn "Failed to delete ${name}"
			done

			# Show remaining active NM connections for confirmation
			info "Remaining active NetworkManager connections:"
			nmcli connection show --active || true
		else
			info "No active Proton VPN kill switch profiles found. Skipping kill switch cleanup."
		fi
	else
		warn "nmcli not found. Skipping kill switch check. If you used NetworkManager, you may need to remove pvpn-* connections manually."
	fi
}

uninstall_debian() {
	info "Uninstalling Proton VPN on Debian/Ubuntu..."
	if have_cmd sudo; then SUDO=sudo; else SUDO=""; fi

	# Autoremove the app (ok if already removed)
	${SUDO} apt autoremove -y proton-vpn-gnome-desktop || warn "proton-vpn-gnome-desktop not installed or removal failed"

	# Purge the ProtonVPN stable-release package (ok if already removed)
	${SUDO} apt purge -y protonvpn-stable-release || warn "protonvpn-stable-release not installed or purge failed"

	cleanup_killswitch
	info "Debian/Ubuntu Proton VPN uninstall complete."
}

uninstall_fedora() {
	info "Uninstalling Proton VPN on Fedora..."
	if have_cmd sudo; then SUDO=sudo; else SUDO=""; fi

	# Remove the app and repo package
	${SUDO} dnf remove -y proton-vpn-gnome-desktop protonvpn-stable-release || warn "Proton VPN packages not installed or removal failed"

	cleanup_killswitch
	info "Fedora Proton VPN uninstall complete."
}

uninstall_arch() {
	info "Uninstalling Proton VPN on Arch-based system..."
	if have_cmd sudo; then SUDO=sudo; else SUDO=""; fi

	# Remove ProtonVPN packages (try specific ones, fall back to meta)
	if have_cmd pacman; then
		${SUDO} pacman -Rns --noconfirm protonvpn-cli-ng protonvpn-gui protonvpn || warn "Proton VPN packages not installed or removal failed"
	else
		warn "pacman not found; cannot uninstall on Arch."
	fi

	cleanup_killswitch
	info "Arch-based Proton VPN uninstall complete."
}

case "$DTYPE" in
	debian|ubuntu|linuxmint|pop|elementary|zorin)
		uninstall_debian
		;;
	fedora|rhel|centos|almalinux|rocky)
		uninstall_fedora
		;;
	arch|manjaro|endeavouros|garuda|arcolinux)
		uninstall_arch
		;;
	*)
		err "Unsupported or unrecognized distro: $DTYPE"
		err "Supported IDs: debian/ubuntu*, fedora/rhel*, arch-based."
		exit 1
		;;
esac

info "Proton VPN uninstall routine completed."