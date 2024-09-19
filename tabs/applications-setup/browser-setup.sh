#!/bin/sh -e

. ../common-script.sh

choose_browser() {
	printf "%b\n" "${YELLOW}Available browsers..${RC}"
	printf "%b\n" "1) Firefox"
	printf "%b\n" "2) Brave"
	printf "%b\n" "3) Librewolf"
	printf "%b\n" "4) Thorium Browser"
	printf "%b\n" "5) Tor Browser"

	printf "%b\n" "${YELLOW}Enter the number of the browser you want to install..${RC}"
	read -r choice

	case $choice in
		1) install_firefox ;;
		2) install_brave ;;
		3) install_librewolf ;;
		4) install_thorium ;;
		5) install_tor ;;
		*)
			printf "%b\n" "${RED}Invalid choice. Please select from the available browsers.${RC}"
			exit 1
			;;
	esac
}

install_firefox() {
	printf "%b\n" "${YELLOW}Installing Firefox...${RC}"
	case $PACKAGER in
		apt-get|nala)
			"$ESCALATION_TOOL" "$PACKAGER" install -y wget
			"$ESCALATION_TOOL" install -d -m 0755 /etc/apt/keyrings
			wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | "$ESCALATION_TOOL" tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
			gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3") print "\nThe key fingerprint matches ("$0").\n"; else print "\nVerification failed: the fingerprint ("$0") does not match the expected one.\n"}'
			echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | "$ESCALATION_TOOL" tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
			echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | "$ESCALATION_TOOL" tee /etc/apt/preferences.d/mozilla 
			"$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y firefox
			;;
		zypper)
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install MozillaFirefox
			;;
		dnf)
			"$ESCALATION_TOOL" "$PACKAGER" install -y firefox
			;;
		pacman)
			"$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm firefox
			;;
		*)
			printf "%b\n" "${RED}Unsupported package manager. Please install Firefox manually.${RC}"
			exit 1
			;;
	esac
	printf "%b\n" "${GREEN}Firefox installed successfully!${RC}"
}

install_brave() {
	printf "%b\n" "${YELLOW}Installing Brave...${RC}"
	case $PACKAGER in
		apt-get|nala)
			"$ESCALATION_TOOL" "$PACKAGER" install -y curl
			"$ESCALATION_TOOL" curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
			echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null
			"$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
			;;
		zypper)
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install curl
			"$ESCALATION_TOOL" rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
			"$ESCALATION_TOOL" "$PACKAGER" addrepo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install brave-browser
			;;
		dnf)
			"$ESCALATION_TOOL" "$PACKAGER" install -y dnf-plugins-core
			"$ESCALATION_TOOL" "$PACKAGER" config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
			"$ESCALATION_TOOL" rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
			"$ESCALATION_TOOL" "$PACKAGER" install -y brave-browser
			;;
		pacman)
			"$AUR_HELPER" -S --needed --noconfirm brave-bin
			;;
		*)
			printf "%b\n" "${RED}Unsupported package manager. Please install Brave manually.${RC}"
			exit 1
			;;
	esac
	printf "%b\n" "${GREEN}Brave installed successfully!${RC}"
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

install_tor() {
	printf "%b\n" "${YELLOW}Installing Tor Browser...${RC}"
	
	case $PACKAGER in
	    apt-get|nala)
		    "$ESCALATION_TOOL" "$PACKAGER" install -y torbrowser-launcher
			;;
		zypper)
			"$ESCALATION_TOOL" "$PACKAGER" --non-interactive install torbrowser-launcher
			;;
		dnf)
			"$ESCALATION_TOOL" "$PACKAGER" install -y torbrowser-launcher
			;;
		pacman)
			git clone https://aur.archlinux.org/tor-browser-bin.git && cd tor-browser-bin
			gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
			makepkg -si --noconfirm && cd .. && rm -rf tor-browser-bin
			;;
		*)
			printf "%b\n" "${RED}Unsupported package manager. Please install Tor Browser manually.${RC}"
			exit 1
			;;
	esac
	printf "%b\n" "${GREEN}Tor Browser installed successfully!${RC}"
}

checkEnv
checkAURHelper
checkEscalationTool
choose_browser