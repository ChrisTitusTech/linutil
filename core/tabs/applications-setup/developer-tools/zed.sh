#!/bin/sh -e

. ../../common-script.sh

installZed() {
    if ! command_exists dev.zed.Zed && ! command_exists zed && ! command_exists zeditor; then
        printf "%b\n" "${CYAN}Installing Zed.${RC}"
        case "$PACKAGER" in
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add zed
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S zed --needed --noconfirm
                ;;
            zypper)
                "$ESCALATION_TOOL" "$PACKAGER" addrepo -f https://download.opensuse.org/repositories/editors/openSUSE_Tumbleweed/editors.repo
                "$ESCALATION_TOOL" "$PACKAGER" install -y zed
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y zed
                ;;
            *)
                printf "%b\n" "${YELLOW}No official package found for package manager $PACKAGER. Do you want to install flathub package or from source?${RC}"
                printf "%b\n" "1) Flathub package"
                printf "%b\n" "2) Source"
                printf "%b\n" "3) Exit"
                printf "%b" "Choose an option: "
                read -r choice
                case "$choice" in
                    1)
                        checkFlatpak
                        flatpak install -y flathub dev.zed.Zed
                        ;;
                    2)
                        curl -f https://zed.dev/install.sh | sh
                        ;;
                    3)
                        printf "%b\n" "${GREEN}Exiting.${RC}"
                        exit 0
                        ;;
                    *)
                        printf "%b\n" "${RED}Invalid option.${RC}"
                        exit 1
                        ;;
                esac
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Zed is already installed.${RC}"
    fi
}

checkEnv
clear
installZed
