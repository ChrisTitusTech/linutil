#!/bin/sh -e

. ../../common-script.sh

installBraveOrigin() {
    if ! command_exists brave-origin && ! command_exists com.brave.Browser; then
        printf "%b\n" "${YELLOW}Installing Brave Origin...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
                "$ESCALATION_TOOL" curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                "$ESCALATION_TOOL" curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-origin
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y dnf-plugins-core
                if command_exists rpm-ostree; then
                    "$ESCALATION_TOOL" curl -fsSLo /etc/yum.repos.d/brave-browser.repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                    "$ESCALATION_TOOL" rpm-ostree install brave-origin
                elif command_exists dnf5; then
                    "$ESCALATION_TOOL" dnf5 config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                    "$ESCALATION_TOOL" "$PACKAGER" install -y brave-origin
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                    "$ESCALATION_TOOL" "$PACKAGER" install -y brave-origin
                fi
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
