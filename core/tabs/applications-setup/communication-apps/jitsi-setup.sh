#!/bin/sh -e

. ../../common-script.sh

installJitsi() {
    if ! command_exists jitsi-meet; then
        printf "%b\n" "${YELLOW}Installing Jitsi meet...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl https://download.jitsi.org/jitsi-key.gpg.key | elevated_execution gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg
                printf "%b\n" 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | elevated_execution tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" -y install jitsi-meet
                ;;
            zypper)
                elevated_execution "$PACKAGER" --non-interactive install jitsi
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm jitsi-meet-bin
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y jitsi-meet
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Jitsi meet is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installJitsi