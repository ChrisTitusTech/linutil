#!/bin/sh

. ../../common-script.sh

installBoxes() {
	printf "%b\n" "${YELLOW}Installing Gnome Boxes...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" -y install gnome-boxes
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" -y install dnf-plugins-core
            dnf_version=$(dnf --version | head -n 1 | cut -d '.' -f 1)

            "$ESCALATION_TOOL" "$PACKAGER" -y install gnome-boxes
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -y install gnome-boxes 
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm gnome-boxes 
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER" Installing Flatpak version"${RC}"
            "$ESCALATION_TOOL" flatpak install --noninteractive org.gnome.Boxes
            exit 1
            ;;
    esac
}

checkEnv
checkEscalationTool
installBoxes