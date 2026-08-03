#!/bin/sh -e

. ../../common-script.sh

installDiscord() {
    if ! command_exists com.discordapp.Discord && ! command_exists discord; then
        printf "%b\n" "${YELLOW}Installing Discord...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                # Ensure the downloaded .deb is removed even on failure under `set -e`.
                trap 'rm -f discord.deb' EXIT
                curl -fLo discord.deb "https://discord.com/api/download?platform=linux&format=deb"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./discord.deb
                rm -f discord.deb
                trap - EXIT
                ;;
            zypper|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y discord
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm discord 
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
                "$ESCALATION_TOOL" "$PACKAGER" install -y discord
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub com.discordapp.Discord
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Discord is already installed.${RC}"
    fi
}

installVesktop() {
    if ! command_exists dev.vencord.Vesktop && ! command_exists vesktop; then
        printf "%b\n" "${YELLOW}Installing Vesktop...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                case "$ARCH" in
                    x86_64) VESKTOP_DEB_URL="https://vencord.dev/download/vesktop/amd64/deb" ;;
                    aarch64) VESKTOP_DEB_URL="https://vencord.dev/download/vesktop/arm64/deb" ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Vesktop: $ARCH${RC}" && exit 1 ;;
                esac
                # Ensure the downloaded .deb is removed even on failure under `set -e`.
                trap 'rm -f vesktop.deb' EXIT
                curl -fLo vesktop.deb "$VESKTOP_DEB_URL"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./vesktop.deb
                rm -f vesktop.deb
                trap - EXIT
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm vesktop-bin
                ;;
            dnf)
                case "$ARCH" in
                    x86_64) VESKTOP_RPM_URL="https://vencord.dev/download/vesktop/amd64/rpm" ;;
                    aarch64) VESKTOP_RPM_URL="https://vencord.dev/download/vesktop/arm64/rpm" ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Vesktop: $ARCH${RC}" && exit 1 ;;
                esac
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$VESKTOP_RPM_URL"
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub dev.vencord.Vesktop
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Vesktop is already installed.${RC}"
    fi
}

installEquibop() {
    if ! command_exists org.equicord.equibop && ! command_exists equibop; then
        printf "%b\n" "${YELLOW}Installing Equibop...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                latest_release=$(curl -s https://api.github.com/repos/Equicord/Equibop/releases/latest)
                case "$ARCH" in
                    x86_64) EQUIBOP_DEB_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*_amd64\.deb' | head -n1) ;;
                    aarch64) EQUIBOP_DEB_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*_arm64\.deb' | head -n1) ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Equibop: $ARCH${RC}" && exit 1 ;;
                esac
                # Ensure the downloaded .deb is removed even on failure under `set -e`.
                trap 'rm -f equibop.deb' EXIT
                curl -fLo equibop.deb "$EQUIBOP_DEB_URL"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./equibop.deb
                rm -f equibop.deb
                trap - EXIT
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm equibop-bin
                ;;
            dnf)
                latest_release=$(curl -s https://api.github.com/repos/Equicord/Equibop/releases/latest)
                case "$ARCH" in
                    x86_64) EQUIBOP_RPM_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*\.x86_64\.rpm' | head -n1) ;;
                    aarch64) EQUIBOP_RPM_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*\.aarch64\.rpm' | head -n1) ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Equibop: $ARCH${RC}" && exit 1 ;;
                esac
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$EQUIBOP_RPM_URL"
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub org.equicord.equibop
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Equibop is already installed.${RC}"
    fi
}

main() {

    printf "%b\n" "${YELLOW}Choose a fork of Discord to install:${RC}"
    printf "%b\n" "${YELLOW}1) Vanilla Discord${RC}"
    printf "%b\n" "${YELLOW}2) Vesktop (Discord with plugins)${RC}"
    printf "%b\n" "${YELLOW}3) Equibop (Vesktop with more plugins)${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r choice

    case "$choice" in
        1)
            installDiscord
            ;;
        2)
            installVesktop
            ;;
        3)
            installEquibop
            ;;
        *)
            printf "%b\n" "${RED}Invalid choice. Exiting.${RC}"
            exit 1
            ;;
    esac
}
checkEnv
main

