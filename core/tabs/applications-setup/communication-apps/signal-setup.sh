#!/bin/sh -e

. ../../common-script.sh

installSignal() {
    if ! flatpak_app_installed org.signal.Signal && ! command_exists signal; then
        printf "%b\n" "${YELLOW}Installing Signal...${RC}"
        if try_flatpak_install org.signal.Signal; then
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
                "$ESCALATION_TOOL" tee /usr/share/keyrings/signal-desktop-keyring.gpg < signal-desktop-keyring.gpg > /dev/null
                printf "%b\n" 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/signal-xenial.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" -y install signal-desktop
                ;;
            zypper|eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y signal-desktop
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm signal-desktop
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy Signal-Desktop
                ;;   
            dnf|apk)
                printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Signal is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
installSignal
