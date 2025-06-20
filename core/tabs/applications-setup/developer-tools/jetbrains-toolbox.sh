#!/bin/sh -e

. ../../common-script.sh

manualInstall() {
    JETBRAINS_TOOLBOX_DIR="/opt/jetbrains-toolbox"

    case "$ARCH" in
        x86_64) ARCHIVE_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | jq -r ".TBA[0].downloads.linux.link") ;;
        aarch64) ARCHIVE_URL=$(curl -s "https://data.services.jetbrains.com/products/releases?code=TBA&latest=true&type=release" | jq -r ".TBA[0].downloads.linuxARM64.link") ;;
    esac

    curl -fSL "$ARCHIVE_URL" -o "jetbrains-toolbox.tar.gz"

    if [ -d "$JETBRAINS_TOOLBOX_DIR" ]; then
        "$ESCALATION_TOOL" rm -rf "$JETBRAINS_TOOLBOX_DIR"
    fi

    "$ESCALATION_TOOL" mkdir -p "$JETBRAINS_TOOLBOX_DIR"
    "$ESCALATION_TOOL" tar -xzf "jetbrains-toolbox.tar.gz" -C "$JETBRAINS_TOOLBOX_DIR" --strip-components=1
    "$ESCALATION_TOOL" ln -sf "$JETBRAINS_TOOLBOX_DIR/jetbrains-toolbox" "/usr/bin/jetbrains-toolbox"
}

installJetBrainsToolBox() {
    if ! command_exists jetbrains-toolbox; then
        printf "%b\n" "${YELLOW}Installing Jetbrains Toolbox...${RC}"
        case "$PACKAGER" in
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm jetbrains-toolbox
                ;;
            dnf|eopkg)
                manualInstall
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy fuse3
                manualInstall
                ;;
            *)
                "$ESCALATION_TOOL" "$PACKAGER" install -y libfuse2
                manualInstall
                ;;
        esac
        printf "%b\n" "${GREEN}Successfully installed Jetbrains Toolbox.${RC}"
    else
        printf "%b\n" "${GREEN}Jetbrains toolbox is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installJetBrainsToolBox
