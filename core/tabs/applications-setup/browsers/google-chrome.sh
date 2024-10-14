#!/bin/sh -e

. ../../common-script.sh

installChrome() {
    if ! command_exists google-chrome; then
        printf "%b\n" "${YELLOW}Installing Google Chrome...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -O https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
                elevated_execution "$PACKAGER" install -y ./google-chrome-stable_current_amd64.deb
                ;;
            zypper)
                elevated_execution "$PACKAGER" addrepo http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
                elevated_execution "$PACKAGER" refresh
                elevated_execution "$PACKAGER" --non-interactive install google-chrome-stable
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm google-chrome
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y fedora-workstation-repositories
                elevated_execution "$PACKAGER" config-manager --set-enabled google-chrome
                elevated_execution "$PACKAGER" install -y google-chrome-stable
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Google Chrome Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installChrome