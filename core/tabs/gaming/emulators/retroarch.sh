#!/bin/sh -e

. ../../common-script.sh

installRetroArch() {
	printf "%b\n" "${YELLOW}Installing RetroArch...${RC}"
	if ! command_exists retroarch; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y retroarch retroarch-assets
	            ;;
	        pacman)
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter retroarch retroarch-assets-xmb retroarch-assets-ozone retroarch-assets-glui libretro-core-info
	            ;;
	        *)
	        	if command_exists flatpak; then
	            	"$ESCALATION_TOOL" flatpak install --noninteractive org.libretro.RetroArch
	            fi
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RetroArch is already installed.${RC}"
	fi
}

configureRetroArch() {
	printf "%b\n" "${YELLOW}Configuring RetroArch...${RC}"
	if command_exists retroarch; then
	    case "$PACKAGER" in
	        apt-get|nala)
			    "$ESCALATION_TOOL" "$PACKAGER" install -y libretro-core-info libretro-mgba libretro-nestopia libretro-bnes-mercury-balanced
	            ;;
	        zypper)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y libretro-beetle-psx libretro-play \
	        	libretro-bsnes libretro-dolphin libretro-desmume libretro-mgba libretro-nestopia libretro-parallel-n64 \
	        	libretro-beetle-saturn libretro-blastem
	        	;;
	        dnf)
	        	"$ESCALATION_TOOL" "$PACKAGER" install -y libretro-mgba libretro-nestopia libretro-bsnes-mercury libretro-pcsx-rearmed
	        	;;
	        pacman)
	        	# Available in extra
	        	"$AUR_HELPER" -S --needed --noconfirm --cleanafter libretro-core-info \
		        	libretro-beetle-psx libretro-play libretro-ppsspp \
		        	libretro-nestopia libretro-mesen libretro-mgba libretro-snes9x libretro-mesen-s libretro-bsnes \
		        	libretro-parallel-n64 libretro-mupen64plus-next libretro-dolphin libretro-melonds \
		        	libretro-flycast libretro-genesis-plus-gx libretro-kronos libretro-blastem

		        # Only in AUR
		        "$AUR_HELPER" -S --needed --noconfirm --cleanafter libretro-pcsx2-launcher
	            ;;
	        *)
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RetroArch is not installed.${RC}"
	fi
}

uninstallRetroArch() {
	printf "%b\n" "${YELLOW}Uninstalling RetroArch...${RC}"
	if command_exists gimp; then
	    case "$PACKAGER" in
	        apt-get|nala|dnf|zypper)
				"$ESCALATION_TOOL" "$PACKAGER" remove -y retroarch* libretro*
	            ;;
	        pacman)
	        	"$AUR_HELPER" -R --noconfirm --cleanafter retroarch* libretro*
	            ;;
	        *)
	            "$ESCALATION_TOOL" flatpak uninstall --noninteractive org.libretro.RetroArch
	            exit 1
	            ;;
	    esac
	else
		printf "%b\n" "${GREEN}RetroArch is not installed.${RC}"
	fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install RetroArch, Install Cores, Uninstall RetroArch or Install RetroArch With Cores ${RC}"
    printf "%b\n" "1. ${YELLOW}Install RetroArch${RC}"
    printf "%b\n" "2. ${YELLOW}Install Cores${RC}"
    printf "%b\n" "3. ${YELLOW}Uninstall RetroArch${RC}"
	printf "%b\n" "4. ${YELLOW}Install RetroArch With Cores${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) installRetroArch ;;
    	2) configureRetroArch ;;
        3) uninstallRetroArch ;;
        4) 
        	installRetroArch
        	configureRetroArch
        	;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkEscalationTool
main