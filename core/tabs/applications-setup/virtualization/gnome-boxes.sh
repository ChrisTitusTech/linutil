#!/bin/sh

. ../../common-script.sh

installBoxes() {
	printf "%b\n" "${YELLOW}Installing Gnome Boxes...${RC}"
    case "$PACKAGER" in
        apt-get|nala|dnf|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -y install gnome-boxes
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm gnome-boxes 
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER" Installing Flatpak version"${RC}"
            "$ESCALATION_TOOL" flatpak install --noninteractive org.gnome.Boxes
            ;;
    esac
}

checkEnv
checkEscalationTool
installBoxes