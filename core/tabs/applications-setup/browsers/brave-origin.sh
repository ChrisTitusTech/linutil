#!/bin/sh -e

. ../../common-script.sh

installBraveOrigin() {
    if ! command_exists brave-origin && ! command_exists com.brave.Browser; then
        printf "%b\n" "${YELLOW}Installing Brave Origin...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                . /etc/os-release
                "$ESCALATION_TOOL" curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-origin
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y dnf-plugins-core
                "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-origin
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                "$ESCALATION_TOOL" "$PACKAGER" --gpg-auto-import-keys refresh
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-origin
                ;;
            pacman)
                checkAURHelper
                "$AUR_HELPER" -S --needed --noconfirm brave-origin-bin
                ;;
            *)
                curl -fsS https://dl.brave.com/install.sh | FLAVOR=origin sh
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Brave Origin is already installed.${RC}"
    fi
}

checkEnv
installBraveOrigin
