#!/bin/sh

# Cross-distro Proton VPN installer for Debian/Ubuntu, Fedora, and Arch-based systems.
# For Debian/Ubuntu: dynamically discovers latest protonvpn-stable-release .deb.
# For Fedora: installs the latest known stable-release RPM (simple approach).
# For Arch: installs ProtonVPN CLI/GUI from AUR using yay/paru if available.

set -eu

. ../../common-script.sh

have_cmd() { command -v "$1" >/dev/null 2>&1; }
need_cmd() { have_cmd "$1" || { echo "Missing required command: $1" >&2; exit 1; }; }

checkDistro
echo "Detected distro ID: $DTYPE"

install_debian() {
	BASE_URL="https://repo.protonvpn.com/debian"
	DIST_PATH="dists/stable/main/binary-all"
	PKG_NAME="protonvpn-stable-release"
	FALLBACK_DEB_URL="$BASE_URL/$DIST_PATH/${PKG_NAME}_1.0.8_all.deb"

	fetch_url() {
		if have_cmd curl; then curl -fsSL "$1"; elif have_cmd wget; then wget -qO - "$1"; else echo "Error: curl or wget required" >&2; return 127; fi
	}
	download_file() {
		url="$1"; out="$2"
		if have_cmd curl; then curl -fLo "$out" "$url"; elif have_cmd wget; then wget -O "$out" "$url"; else echo "Error: curl or wget required" >&2; return 127; fi
	}

	echo "Discovering latest $PKG_NAME package from repository metadata..."
	PACKAGES_GZ_URL="$BASE_URL/$DIST_PATH/Packages.gz"
	PACKAGES_URL="$BASE_URL/$DIST_PATH/Packages"
	extract_field_from_packages() {
		field="$1"
		if out=$(fetch_url "$PACKAGES_GZ_URL" 2>/dev/null | gzip -cd 2>/dev/null | awk -v pkg="$PKG_NAME" -v fld="$field" 'BEGIN{RS=""; FS="\n"} $0 ~ "^Package: " pkg { for(i=1;i<=NF;i++){ if($i ~ ("^" fld ":")){ sub(("^" fld ": "),"",$i); print $i; exit } } }'); then
			[ -n "${out:-}" ] && printf '%s' "$out" && return 0
		fi
		out=$(fetch_url "$PACKAGES_URL" 2>/dev/null | awk -v pkg="$PKG_NAME" -v fld="$field" 'BEGIN{RS=""; FS="\n"} $0 ~ "^Package: " pkg { for(i=1;i<=NF;i++){ if($i ~ ("^" fld ":")){ sub(("^" fld ": "),"",$i); print $i; exit } } }') || true
		printf '%s' "${out:-}"
	}

	FILENAME=$(extract_field_from_packages Filename)
	SHA256=$(extract_field_from_packages SHA256)
	VERSION=$(extract_field_from_packages Version)
	DOWNLOAD_URL=""; OUTPUT_DEB=""
	if [ -n "$FILENAME" ]; then
		DOWNLOAD_URL="$BASE_URL/$FILENAME"; OUTPUT_DEB=$(basename "$FILENAME")
	elif [ -n "${VERSION:-}" ]; then
		OUTPUT_DEB="${PKG_NAME}_${VERSION}_all.deb"; DOWNLOAD_URL="$BASE_URL/$DIST_PATH/$OUTPUT_DEB"
	else
		OUTPUT_DEB="${PKG_NAME}_1.0.8_all.deb"; DOWNLOAD_URL="$FALLBACK_DEB_URL"
	fi
	echo "Downloading repo package: $DOWNLOAD_URL"
	download_file "$DOWNLOAD_URL" "$OUTPUT_DEB"
	if [ -n "$SHA256" ]; then
		printf '%s  %s\n' "$SHA256" "$OUTPUT_DEB" | sha256sum --check - || { echo "Checksum failed" >&2; exit 1; }
	else
		echo "Warning: SHA256 not found; skipping verification"
	fi
	need_cmd sudo
	sudo dpkg -i "./$OUTPUT_DEB" && sudo apt update
	sudo apt install -y proton-vpn-gnome-desktop
	# Optional GNOME tray support
	if have_cmd apt; then
		sudo apt install -y libayatana-appindicator3-1 gir1.2-ayatanaappindicator3-0.1 gnome-shell-extension-appindicator || echo "Tray extension install skipped"
	fi
	echo "Debian/Ubuntu Proton VPN installation complete."
}

install_fedora() {
	need_cmd sudo; need_cmd dnf
	BASE_URL="https://repo.protonvpn.com/fedora"
	echo "Discovering latest protonvpn-stable-release RPM from Fedora repo metadata..."

	# We attempt to parse the primary.xml.gz from repodata. Pattern similar to standard yum/dnf repos.
	# 1. Fetch repomd.xml to discover the location of primary.xml.gz
	repomd_url="$BASE_URL/repodata/repomd.xml"
	fetch() { if have_cmd curl; then curl -fsSL "$1"; elif have_cmd wget; then wget -qO - "$1"; else echo "Need curl or wget" >&2; return 1; fi }

	repomd_content=$(fetch "$repomd_url" 2>/dev/null || true)
	PRIMARY_PATH=""
	if [ -n "$repomd_content" ]; then
		# Extract the location of primary.xml.gz (location href="...")
		PRIMARY_PATH=$(printf '%s' "$repomd_content" | awk -F 'href="' '/primary.xml.gz/{print $2}' | awk -F '"' '{print $1}' | head -n1)
	fi

	RPM_FILE=""; RPM_CHECKSUM=""; RPM_ALGO=""
	if [ -n "$PRIMARY_PATH" ]; then
		primary_url="$BASE_URL/$PRIMARY_PATH"
		echo "Fetching primary metadata: $primary_url"
		primary_xml=$(fetch "$primary_url" 2>/dev/null | gzip -cd 2>/dev/null || true)
		if [ -n "$primary_xml" ]; then
			# Parse for package name protonvpn-stable-release, get location href and checksum
			# Primary XML uses <package><name>...</name><version .../><checksum type="sha256">...</checksum><location href="..."/></package>
			RPM_FILE=$(printf '%s' "$primary_xml" | awk 'BEGIN{RS="</package>"} /<name>protonvpn-stable-release<\/name>/{ if(match($0,/<location href=\"([^\"]+)\"/ ,a)){print a[1]} }' | head -n1)
			RPM_CHECKSUM=$(printf '%s' "$primary_xml" | awk 'BEGIN{RS="</package>"} /<name>protonvpn-stable-release<\/name>/{ if(match($0,/<checksum type=\"([a-z0-9]+)\">([0-9a-f]+)<\/checksum>/,a)){print a[2]" "a[1]} }' | head -n1)
			if [ -n "$RPM_CHECKSUM" ]; then
				RPM_ALGO=$(printf '%s' "$RPM_CHECKSUM" | awk '{print $2}')
				RPM_CHECKSUM=$(printf '%s' "$RPM_CHECKSUM" | awk '{print $1}')
			fi
		fi
	fi

	if [ -z "$RPM_FILE" ]; then
		echo "Warning: Could not parse primary metadata for latest RPM; falling back to hardcoded version." >&2
		RPM_FILE="protonvpn-stable-release-1.0.3-1.noarch.rpm"
	fi

	RPM_URL="$BASE_URL/$RPM_FILE"
	echo "Downloading RPM: $RPM_URL"
	TMP_RPM="/tmp/$(basename "$RPM_FILE")"
	if have_cmd curl; then curl -fLo "$TMP_RPM" "$RPM_URL"; elif have_cmd wget; then wget -O "$TMP_RPM" "$RPM_URL"; else echo "Need curl or wget to download RPM" >&2; exit 1; fi

	if [ -n "$RPM_CHECKSUM" ] && [ "$RPM_ALGO" = "sha256" ]; then
		printf '%s  %s\n' "$RPM_CHECKSUM" "$TMP_RPM" | sha256sum --check - || { echo "RPM checksum verification failed" >&2; exit 1; }
	else
		echo "Warning: Missing checksum information; skipping verification"
	fi

	echo "Installing stable-release RPM to add ProtonVPN repository..."
	sudo dnf install -y "$TMP_RPM"
	sudo dnf clean all || true
	echo "Installing Proton VPN app package..."
	sudo dnf install -y proton-vpn-gnome-desktop || { echo "Failed to install proton-vpn-gnome-desktop" >&2; exit 1; }
	echo "Fedora Proton VPN installation complete (dynamic discovery)."
}

install_arch() {
	need_cmd pacman
	AUR_HELPER=""
	for h in yay paru; do
		if have_cmd "$h"; then AUR_HELPER="$h"; break; fi
	done
	if [ -z "$AUR_HELPER" ]; then
		echo "No AUR helper (yay/paru) found. Please install one and re-run." >&2
		exit 1
	fi
	echo "Using AUR helper: $AUR_HELPER"
	# Install CLI + GUI; fall back to single meta if necessary.
	if "$AUR_HELPER" -Si protonvpn-cli-ng >/dev/null 2>&1; then
		"$AUR_HELPER" -S --noconfirm protonvpn-cli-ng protonvpn-gui || {
			echo "Attempt to install CLI+GUI failed; trying protonvpn" >&2
			"$AUR_HELPER" -S --noconfirm protonvpn || { echo "Arch install failed" >&2; exit 1; }
		}
	else
		"$AUR_HELPER" -S --noconfirm protonvpn || { echo "Arch install failed" >&2; exit 1; }
	fi
	echo "Arch-based Proton VPN installation complete. (Packages are community/AUR; verify trust.)"
}

case "$DTYPE" in
	debian|ubuntu|linuxmint|pop|elementary|zorin)
		install_debian
		;;
	fedora|rhel|centos|almalinux|rocky)
		install_fedora
		;;
	arch|manjaro|endeavouros|garuda|arcolinux)
		install_arch
		;;
	*)
		echo "Unsupported or unrecognized distro: $DTYPE" >&2
		echo "Supported IDs: debian/ubuntu*, fedora/rhel*, arch-based." >&2
		exit 1
		;;
esac