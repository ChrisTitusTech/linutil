#!/bin/sh

. ../../common-script.sh

installBoxes() {
	printf "%b\n" "${YELLOW}Installing Gnome Boxes...${RC}"
    case "$PACKAGER" in
        apt-get|nala|dnf|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -y install gnome-boxes
            ;;
        pacman)
            if command_exists yay || command_exists paru; then
                "$AUR_HELPER" -S --needed --noconfirm gnome-boxes
            else
                "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm gnome-boxes
            fi 
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