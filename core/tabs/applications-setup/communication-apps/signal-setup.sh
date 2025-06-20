#!/bin/sh -e

. ../../common-script.sh

installSignal() {
    if ! command_exists org.signal.Signal && ! command_exists signal; then
        printf "%b\n" "${YELLOW}Installing Signal...${RC}"
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
            dnf)
                checkFlatpak
                flatpak install -y flathub org.signal.Signal
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy Signal-Desktop
                ;;   
            apk)
                checkFlatpak
                flatpak install -y flathub org.signal.Signal
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
