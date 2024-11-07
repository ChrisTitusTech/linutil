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
            "$ESCALATION_TOOL" "$PACKAGER" install linutil -y
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
                                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm curl rustup man-db
                                ;;
                            dnf)
                                "$ESCALATION_TOOL" "$PACKAGER" install -y curl rustup man-pages man-db man
                                ;;
                            apk)
                                "$ESCALATION_TOOL" "$PACKAGER" add build-base
                                "$ESCALATION_TOOL" "$PACKAGER" add rustup
                                rustup-init
                                # shellcheck disable=SC1091
                                . "$HOME/.cargo/env"
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
                    installExtra
                    ;;
                *) printf "%b\n" "${RED}Linutil not installed.${RC}" ;;
            esac
    esac
}

installExtra() {
    printf "%b\n" "${YELLOW}Installing the manpage...${RC}"
    "$ESCALATION_TOOL" mkdir -p /usr/share/man/man1
    curl 'https://raw.githubusercontent.com/ChrisTitusTech/linutil/refs/heads/main/man/linutil.1' | "$ESCALATION_TOOL" tee '/usr/share/man/man1/linutil.1' > /dev/null
    printf "%b\n" "${YELLOW}Creating a Desktop Entry...${RC}"
    "$ESCALATION_TOOL" mkdir -p /usr/share/applications
    curl 'https://raw.githubusercontent.com/ChrisTitusTech/linutil/refs/heads/main/linutil.desktop' | "$ESCALATION_TOOL" tee /usr/share/applications/linutil.desktop > /dev/null
    printf "%b\n" "${GREEN}Done.${RC}"
}

checkEnv
checkEscalationTool
checkAURHelper
installLinutil
