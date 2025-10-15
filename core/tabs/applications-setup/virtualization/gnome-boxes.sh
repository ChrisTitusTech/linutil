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
            "$ESCALATION_TOOL" flatpak install --noninteractive org.gnome.Boxes
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
                if command_exists yay || command_exists paru; then
                    "$AUR_HELPER" -R --noconfirm gnome-boxes
                else
                    "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm gnome-boxes
                fi
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