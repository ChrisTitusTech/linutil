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

install_thorium() {
    printf "%b\n" "${YELLOW}Installing Thorium Browser...${RC}"
    case $PACKAGER in
	apt-get|nala)
	    "$ESCALATION_TOOL" rm -fv /etc/apt/sources.list.d/thorium.list
            "$ESCALATION_TOOL" wget --no-hsts -P /etc/apt/sources.list.d/ http://dl.thorium.rocks/debian/dists/stable/thorium.list
	    "$ESCALATION_TOOL" "$PACKAGER" update
	    "$ESCALATION_TOOL" "$PACKAGER" install -y thorium-browser
		;;
	zypper|dnf)
	    url=$(curl -s https://api.github.com/repos/Alex313031/Thorium/releases/latest | grep -oP '(?<=browser_download_url": ")[^"]*\.rpm')
            echo $url && curl -L $url -o thorium-latest.rpm
            "$ESCALATION_TOOL" rpm -i thorium-latest.rpm && rm thorium-latest.rpm
		;;
	pacman)
	     "$AUR_HELPER" -S --needed --noconfirm thorium-browser-bin
		;;
		*)
	        printf "%b\n" "${RED}Unsupported package manager. Please install Thorium manually.${RC}"
		exit 1
		;;
	esac
	printf "%b\n" "${GREEN}Thorium Browser installed successfully!${RC}"
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

install_librewolf() {
	printf "%b\n" "${YELLOW}Installing Librewolf...${RC}"
	case $PACKAGER in
		apt-get|nala)
			"$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y wget gnupg lsb-release apt-transport-https ca-certificates
			distro=`if echo " una bookworm vanessa focal jammy bullseye vera uma " | grep -q " $(lsb_release -sc) "; then lsb_release -sc; else echo focal; fi`
			wget -O- https://deb.librewolf.net/keyring.gpg | "$ESCALATION_TOOL" gpg --dearmor -o /usr/share/keyrings/librewolf.gpg
			echo "Types: deb
URIs: https://deb.librewolf.net
Suites: $distro
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/librewolf.gpg" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/librewolf.sources > /dev/null
			"$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y librewolf
			;;
		dnf)
			curl -fsSL https://rpm.librewolf.net/librewolf-repo.repo | pkexec tee /etc/yum.repos.d/librewolf.repo > /dev/null
			"$ESCALATION_TOOL" "$PACKAGER" install -y librewolf
			;;
		rpm-ostree)
			rpm-ostree install -y librewolf
			;;
		zypper)
			"$ESCALATION_TOOL" rpm --import https://rpm.librewolf.net/pubkey.gpg
			"$ESCALATION_TOOL" zypper ar -ef https://rpm.librewolf.net librewolf
			"$ESCALATION_TOOL" zypper ref
			"$ESCALATION_TOOL" zypper in librewolf
			;;
		pacman)
			"$AUR_HELPER" -S --needed --noconfirm librewolf-bin
			;;
		*)
			printf "%b\n" "${RED}Unsupported package manager. Please install Librewolf manually.${RC}"
			exit 1
			;;
	esac
	printf "%b\n" "${GREEN}Librewolf installed successfully!${RC}"
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
    printf "%b\n" "3. Librewolf"
    printf "%b\n" "4. Brave"
    printf "%b\n" "5. Vivaldi"
    printf "%b\n" "6. Chromium"
    printf "%b\n" "7. Thorium"
    printf "%b\n" "8. Lynx"
    printf "%b\n" "----------------------------"
    printf "%b\n"  "Enter your choices (e.g., 1 3 5): "
    read -r choice
    for ch in $choice; do
        case $ch in
                1) install_chrome ;;
                2) install_firefox ;;
                3) install_librewolf ;;
                4) install_brave ;;
                5) install_vivaldi ;;
                6) install_chromium ;;
                7) install_thorium ;;
                8) install_lynx;;
                *) printf "%b\n" "${RED}Invalid option: $ch ${RC}" ;;
            esac
        done
    printf "%b\n" "${GREEN}Installation complete!${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
browserSetup
