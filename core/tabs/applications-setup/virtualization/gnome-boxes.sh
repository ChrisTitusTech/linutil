#!/bin/sh

. ../../common-script.sh

installBoxes() {
	printf "%b\n" "${YELLOW}Installing Gnome Boxes...${RC}"
    case "$PACKAGER" in
        apt-get|nala|dnf|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" -y install gnome-boxes
            ;;
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm --cleanafter gnome-boxes 
            ;;
        *)
            if command_exists flatpak; then
                "$ESCALATION_TOOL" flatpak install --noninteractive org.gnome.Boxes
            fi
            ;;
    esac
}

uninstallBoxes() {
    printf "%b\n" "${YELLOW}Uninstalling Gnome Boxes...${RC}"
    if command_exists gnome-boxes; then
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y gnome-boxes
                ;;
            pacman)
                "$AUR_HELPER" -R --noconfirm --cleanafter gnome-boxes
                ;;
            *)
                "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.gnome.Boxes
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Gnome Boxes is not installed.${RC}"
    fi
}

main() {
    printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Gnome Boxes${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installBoxes ;;
        2) uninstallBoxes ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
installBoxes