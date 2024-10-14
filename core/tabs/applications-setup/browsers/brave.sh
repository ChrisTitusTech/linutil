#!/bin/sh -e

. ../../common-script.sh

installBrave() {
    if ! command_exists brave; then
        printf "%b\n" "${YELLOW}Installing Brave...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                elevated_execution "$PACKAGER" install -y curl
                elevated_execution curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | elevated_execution tee /etc/apt/sources.list.d/brave-browser-release.list
                elevated_execution "$PACKAGER" update
                elevated_execution "$PACKAGER" install -y brave-browser
                ;;
            zypper)
                elevated_execution "$PACKAGER" install -y curl
                elevated_execution rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
                elevated_execution "$PACKAGER" addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                elevated_execution "$PACKAGER" refresh
                elevated_execution "$PACKAGER" --non-interactive install brave-browser
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm brave-bin
                ;;
            dnf)
                elevated_execution "$PACKAGER" install -y dnf-plugins-core
                elevated_execution "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                elevated_execution rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
                elevated_execution "$PACKAGER" install -y brave-browser
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Brave Browser is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
checkAURHelper
installBrave