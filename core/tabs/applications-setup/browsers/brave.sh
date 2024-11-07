#!/bin/sh -e

. ../../common-script.sh

installBrave() {
    if ! command_exists com.brave.Browser && ! command_exists brave; then
        printf "%b\n" "${YELLOW}Installing Brave...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" "$PACKAGER" install -y curl
                "$ESCALATION_TOOL" curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/brave-browser-release.list
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y curl
                "$ESCALATION_TOOL" rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
                "$ESCALATION_TOOL" "$PACKAGER" addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                "$ESCALATION_TOOL" "$PACKAGER" refresh
                "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install brave-browser
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm brave-bin
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y dnf-plugins-core
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                "$ESCALATION_TOOL" rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
                ;;
            apk)
                checkFlatpak
                flatpak install -y flathub com.brave.Browser
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