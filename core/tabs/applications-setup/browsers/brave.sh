#!/bin/sh -e

. ../../common-script.sh

installBrave() {
    if ! command_exists com.brave.Browser && ! command_exists brave; then
        printf "%b\n" "${YELLOW}Installing Brave...${RC}"
        case "$PACKAGER" in
            apt-get|nala)
            if [ "$DTYPE" = "ubuntu" ] && command_exists snap; then
                "$ESCALATION_TOOL" snap install brave
            else
                "$ESCALATION_TOOL" curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
                "$ESCALATION_TOOL" curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
                "$ESCALATION_TOOL" "$PACKAGER" update
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
            fi
            ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" install -y dnf-plugins-core
                if command_exists dnf5; then
                    "$ESCALATION_TOOL" dnf5 config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                else
                    "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                fi
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
                "$ESCALATION_TOOL" "$PACKAGER" --gpg-auto-import-keys refresh
                "$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
                ;;
            pacman)
                "$AUR_HELPER" -S --needed --noconfirm brave-bin
                ;;
            *)
                checkFlatpak
                "$ESCALATION_TOOL" flatpak install --noninteractive flathub com.brave.Browser 2>/dev/null || \
                    curl -fsS https://dl.brave.com/install.sh | sh
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Brave Browser is already installed.${RC}"
    fi
}

checkEnv
installBrave
