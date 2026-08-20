#!/bin/sh -e

. ../../common-script.sh

installEnteAuth() {
    if ! command_exists io.ente.auth && ! command_exists EnteAuth; then
        printf "%b\n" "${YELLOW}Installing Ente Auth...${RC}"
        # Ente publishes all apps (auth, photos, locker, ...) in one repo, tagged e.g. "auth-v4.4.25".
        latest_tag=$(curl -sL "https://api.github.com/repos/ente-io/ente/releases?per_page=100" |
            grep -o '"tag_name": *"auth-v[^"]*"' |
            head -n1 |
            sed -E 's/.*"(auth-v[^"]*)".*/\1/')
        if [ -z "$latest_tag" ]; then
            printf "%b\n" "${RED}Could not find the latest Ente Auth release${RC}"
            exit 1
        fi
        latest_release=$(curl -sL "https://api.github.com/repos/ente-io/ente/releases/tags/${latest_tag}")
        case "$PACKAGER" in
            apt-get|nala)
                case "$ARCH" in
                    x86_64) EnteAuth_DEB_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*_x86_64\.deb' | head -n1) ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Ente Auth: $ARCH${RC}" && exit 1 ;;
                esac
                # Ensure the downloaded .deb is removed even on failure under `set -e`.
                trap 'rm -f EnteAuth.deb' EXIT
                curl -fLo EnteAuth.deb "$EnteAuth_DEB_URL"
                "$ESCALATION_TOOL" "$PACKAGER" install -y ./EnteAuth.deb
                rm -f EnteAuth.deb
                trap - EXIT
                ;;
            dnf)
                case "$ARCH" in
                    x86_64) EnteAuth_RPM_URL=$(printf '%s' "$latest_release" | grep -o 'https://[^"]*_x86_64\.rpm' | head -n1) ;;
                    *) printf "%b\n" "${RED}Unsupported architecture for Ente Auth: $ARCH${RC}" && exit 1 ;;
                esac
                "$ESCALATION_TOOL" "$PACKAGER" install -y "$EnteAuth_RPM_URL"
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm ente-auth-bin
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub io.ente.auth
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Ente Auth is already installed.${RC}"
    fi
}

checkEnv
installEnteAuth