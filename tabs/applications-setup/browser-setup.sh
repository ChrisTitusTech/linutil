#!/bin/sh -e

. ../common-script.sh

install_chrome() {
    printf "%b\n" "${YELLOW}Installing Google Chrome..${RC}."
    case "$PACKAGER" in
        apt-get|nala)
            wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
            "$ESCALATION_TOOL" dpkg -i google-chrome-stable_current_amd64.deb
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" addrepo http://dl.google.com/linux/chrome/rpm/stable/x86_64 Google-Chrome
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install google-chrome-stable
            ;;
        pacman)
            "$AUR_HELPER" -S --noconfirm google-chrome
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install fedora-workstation-repositories
            "$ESCALATION_TOOL" "$PACKAGER" config-manager --set-enabled google-chrome
            "$ESCALATION_TOOL" "$PACKAGER" install google-chrome-stable
            ;;
        *)
            printf "%b\n" "${RED}The script does not support your Distro. Install manually..${RC}"
            ;;
    esac

}

install_firefox() {
    printf "%b\n" "${YELLOW}Installing Mozilla Firefox...${RC}"
    case "$PACKAGER" in
        apt-get)
            "$ESCALATION_TOOL" "$PACKAGER" update
            "$ESCALATION_TOOL" "$PACKAGER" install -y firefox
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install MozillaFirefox
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm firefox
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install firefox
            ;;
        *)
            printf "%b\n" "${RED}The script does not support your Distro. Install manually..${RC}"
            ;;
    esac

}

install_brave() {
    printf "%b\n" "${YELLOW}Installing Brave...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER"  install curl
            "$ESCALATION_TOOL" curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list
            "$ESCALATION_TOOL" "$PACKAGER"  update
            "$ESCALATION_TOOL" "$PACKAGER"  install brave-browser
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER"install curl
            "$ESCALATION_TOOL" rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            "$ESCALATION_TOOL" "$PACKAGER" addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install brave-browser
            ;;
        pacman)
            "$AUR_HELPER" -S --noconfirm brave-bin
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install dnf-plugins-core
            "$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            "$ESCALATION_TOOL" rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            "$ESCALATION_TOOL" "$PACKAGER" install brave-browser
            ;;
        *)
            printf "%b\n" "${RED}The script does not support your Distro. Install manually..${RC}"
            ;;
    esac
}

install_vivaldi() {
    printf "%b\n" "${YELLOW}Installing Vivaldi...${RC}"
    wget https://downloads.vivaldi.com/snapshot/install-vivaldi.sh
    sh install-vivaldi.sh
}

install_chromium() {
    printf "%b\n" "${YELLOW}Installing Chromium...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y chromium
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install chromium
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm chromium
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install --assumeyes https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
            "$ESCALATION_TOOL" "$PACKAGER" install chromium
            ;;
        *)
            printf "%b\n" "${RED}The script does not support your Distro. Install manually..${RC}"
            ;;
}

install_lynx() {
    printf "%b\n" "${YELLOW}Installing Lynx...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y lynx
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install lynx
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm lynx
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install lynx
            ;;
        *)
            printf "%b\n" "${RED}The script does not support your Distro. Install manually..${RC}"
            ;;
}

browserSetup() {
    clear
    printf "%b\n" "Browser Installation Script"
    printf "%b\n" "----------------------------"
    printf "%b\n" "Select the browsers you want to install:"
    printf "%b\n" "1. Google Chrome"
    printf "%b\n" "2. Mozilla Firefox"
    printf "%b\n" "3. Brave"
    printf "%b\n" "4. Vivaldi"
    printf "%b\n" "5. Chromium"
    printf "%b\n" "5. Lynx"
    printf "%b\n" "----------------------------"
    printf "%b\n"  "Enter your choices (e.g., 1 3 5): "
    read -r choice
    for ch in $choice; do
        case $ch in
                1) install_chrome ;;
                2) install_firefox ;;
                3) install_brave ;;
                4) install_vivaldi ;;
                5) install_chromium ;;
                6) install_lynx;;
                *) printf "%b\n" "${RED}Invalid option: $ch ${RC}" ;;
            esac
        done
    printf "%b\n" "${GREEN}Installation complete!${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
browserSetup
