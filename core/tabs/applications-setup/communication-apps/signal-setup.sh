#!/bin/sh -e

. ../../common-script.sh

installSignal() {
    if ! command_exists signal; then
        printf "%b\n" "${YELLOW}Installing Signal...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSL https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > signal-desktop-keyring.gpg
                cat signal-desktop-keyring.gpg | elevated_execution tee /usr/share/keyrings/signal-desktop-keyring.gpg > /dev/null
                printf "%b\n" 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' | elevated_execution tee /etc/apt/sources.list.d/signal-xenial.list
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" -y install signal-desktop
                ;;
            zypper)
                elevated_execution "$PACKAGER" --non-interactive install signal-desktop
                ;;
            pacman)
                elevated_execution "$PACKAGER" -S --noconfirm signal-desktop
                ;;
            dnf)
                elevated_execution "$PACKAGER" copr enable luminoso/Signal-Desktop
                elevated_execution "$PACKAGER" install -y signal-desktop 
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