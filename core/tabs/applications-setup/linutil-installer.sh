#!/bin/sh -e

. ../common-script.sh

installLinutil() {
    printf "%b\n" "${YELLOW}Installing Linutil...${RC}"
    case "$PACKAGER" in
        pacman)
            printf "%b\n" "-----------------------------------------------------"
            printf "%b\n" "Select the package to install:"
            printf "%b\n" "1. ${CYAN}linutil${RC}      (stable release compiled from source)"
            printf "%b\n" "2. ${CYAN}linutil-bin${RC}  (stable release pre-compiled)"
            printf "%b\n" "3. ${CYAN}linutil-git${RC}  (compiled from the latest commit)"
            printf "%b\n" "-----------------------------------------------------"
            printf "%b" "Enter your choice: "
            read -r choice
            case $choice in
                1) "$AUR_HELPER" -S --needed --noconfirm linutil ;;
                2) "$AUR_HELPER" -S --needed --noconfirm linutil-bin ;;
                3) "$AUR_HELPER" -S --needed --noconfirm linutil-git ;;
                *)
                    printf "%b\n" "${RED}Invalid choice:${RC} $choice"
                    exit 1
                    ;;
            esac
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
            zypper)
            printf "%b\n" "Detecting flavor..."
            flavor = [[zypper lr | grep -i "Tumbleweed"]] && echo "Tumbleweed" || echo "Slowroll"
            printf "%b\n" " flavor detected is ${GREEN} ${flavor} ${RC}"
            printf "%b\n" "setting up repos..."
            if [$flavor == "Tumbleweed"]
            then 
                  "$ESCALATION_TOOL" "$PACKAGER" addrepo https://download.opensuse.org/repositories/home:solomoncyj/openSUSE_Tumbleweed/home:solomoncyj.repo
            fi

            if [$flavor == "Slowroll"]
            then
            "$ESCALATION_TOOL" "$PACKAGER" addrepo https://download.opensuse.org/repositories/home:solomoncyj/openSUSE_Slowroll/home:solomoncyj.repo
            fi
            
            printf "%b\n" "refreshing and installing"
            "$ESCALATION_TOOL" "$PACKAGER" refresh
            "$ESCALATION_TOOL" "$PACKAGER" install linutil
            printf "%b\n" "${GREEN}Installed successfully.${RC}"
            ;;
        *)
            printf "%b\n" "${RED}There are no official packages for your distro.${RC}"
            printf "%b" "${YELLOW}Do you want to install the crates.io package? (y/N): ${RC}"
            read -r choice
            case $choice in
                y|Y)
                    if ! command_exists cargo; then
                        printf "%b\n" "${YELLOW}Installing rustup...${RC}"
                        case "$PACKAGER" in
                            pacman)
                                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm rustup
                                ;;
                            dnf)
                                "$ESCALATION_TOOL" "$PACKAGER" install -y rustup
                                ;;
                            zypper)
                                "$ESCALATION_TOOL" "$PACKAGER" install -n curl gcc make
                                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                                . $HOME/.cargo/env
                                ;;
                            *)
                                curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
                                . $HOME/.cargo/env
                                ;;
                        esac
                    fi
                    rustup default stable
                    cargo install --force linutil_tui
                    printf "%b\n" "${GREEN}Installed successfully.${RC}"
                    ;;
                *) printf "%b\n" "${RED}Linutil not installed.${RC}" ;;
            esac
    esac
}

checkEnv
checkEscalationTool
checkAURHelper
installLinutil
