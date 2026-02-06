#!/bin/sh -e

. ../../common-script.sh

installTenacity() {
	printf "%b\n" "${YELLOW}Installing Tenacity...${RC}"
	if ! flatpak_app_installed org.tenacityaudio.Tenacity && ! command_exists tenacity; then
	    if try_flatpak_install org.tenacityaudio.Tenacity; then
	        return 0
	    fi
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -S --needed --noconfirm --cleanafter tenacity
	            ;;
	        *)
	        	printf "%b\n" "${RED}Flatpak install failed and no native package is configured for ${PACKAGER}.${RC}"
	        	exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}Tenacity is already installed.${RC}"
	fi
}

uninstallTenacity() {
	printf "%b\n" "${YELLOW}Uninstalling Tenacity...${RC}"
	if uninstall_flatpak_if_installed org.tenacityaudio.Tenacity; then
	    return 0
	fi
	if command_exists tenacity; then
	    case "$PACKAGER" in
	        pacman)
			    "$AUR_HELPER" -R --noconfirm --cleanafter tenacity
	            ;;
	        *)
	            printf "%b\n" "${RED}No native uninstall is configured for ${PACKAGER}.${RC}"
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}tenacity is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Tenacity${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b" "Enter your choice [1-2]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installTenacity ;;
        2) uninstallTenacity ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main
