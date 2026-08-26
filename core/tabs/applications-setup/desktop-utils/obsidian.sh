#!/bin/sh -e

. ../../common-script.sh

installObsidian() {
    if ! command_exists md.obsidian.Obsidian && ! command_exists obsidian; then
        printf "%b\n" "${YELLOW}Installing Obsidian...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                latest_release=$(curl -s https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest)
                case "$ARCH" in
                    x86_64) OBSIDIAN_DEB_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*_amd64\.deb' | head -n1) ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Obsidian: $ARCH${RC}" && exit 1 ;;
                esac
                # Ensure the downloaded .deb is removed even on failure under `set -e`.
                trap 'rm -f obsidian.deb' EXIT
                curl -fLo obsidian.deb "$OBSIDIAN_DEB_URL"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./obsidian.deb
                rm -f obsidian.deb
                trap - EXIT
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm obsidian
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub md.obsidian.Obsidian
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Obsidian is already installed.${RC}"
    fi
}

checkEnv
installObsidian