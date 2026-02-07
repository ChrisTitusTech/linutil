#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1

APP_FLATPAK_ID=""
INSTALL_DIR="$HOME/.local/share/aether"
OMARCHY_BIN_DIR="$HOME/.local/share/omarchy/bin"
DESKTOP_LINK="$HOME/.local/share/applications/li.oever.aether.desktop"

installAether() {
    if command_exists aether; then
        printf "%b\n" "${GREEN}Aether is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Aether...${RC}"

    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile install \
            nixpkgs#gjs \
            nixpkgs#gtk4 \
            nixpkgs#libadwaita \
            nixpkgs#libsoup_3 \
            nixpkgs#imagemagick \
            nixpkgs#git
    else
        case "$PACKAGER" in
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm gjs gtk4 libadwaita libsoup3 imagemagick git
                ;;
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gjs libgtk-4-1 libadwaita-1-0 libsoup-3.0-0 imagemagick git
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gjs gtk4 libadwaita libsoup3 ImageMagick git
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gjs gtk4 libadwaita-1 libsoup-3_0-0 ImageMagick git
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add gjs gtk4 libadwaita libsoup3 imagemagick git
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy gjs gtk4 libadwaita libsoup3 ImageMagick git
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y gjs gtk4 libadwaita libsoup3 imagemagick git
                ;;
            flatpak)
                printf "%b\n" "${RED}No Flatpak build is currently configured for Aether in Linutil.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        git -C "$INSTALL_DIR" pull --ff-only
    else
        git clone https://github.com/bjarneo/aether.git "$INSTALL_DIR"
    fi

    if [ -x "$INSTALL_DIR/install.sh" ]; then
        (cd "$INSTALL_DIR" && "$INSTALL_DIR/install.sh")
    else
        printf "%b\n" "${YELLOW}install.sh not found; running Aether directly...${RC}"
        (cd "$INSTALL_DIR" && "$INSTALL_DIR/aether")
    fi

    printf "%b\n" "${GREEN}Aether setup complete.${RC}"
}

uninstallAether() {
    printf "%b\n" "${YELLOW}Uninstalling Aether...${RC}"
    if [ -n "$APP_FLATPAK_ID" ]; then
        uninstall_flatpak_app "$APP_FLATPAK_ID" || true
    fi

    if [ "$PACKAGER" = "pacman" ]; then
        checkAURHelper
        "$AUR_HELPER" -R --noconfirm aether || true
    fi

    if [ -d "$OMARCHY_BIN_DIR" ]; then
        rm -f "$OMARCHY_BIN_DIR/aether"
    fi
    rm -f "$HOME/.local/bin/aether"
    rm -f "$DESKTOP_LINK"
    rm -rf "$INSTALL_DIR"
    printf "%b\n" "${GREEN}Uninstall complete.${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstallAether
else
    installAether
fi
