#!/bin/sh -e

. ../common-script.sh

installFastfetch() {
    if ! command_exists fastfetch; then
        printf "%b\n" "${YELLOW}Installing Fastfetch...${RC}"
        case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm fastfetch
            ;;
        apt-get | nala)
            case "$ARCH" in
                x86_64)
                    DEB_FILE="fastfetch-linux-amd64.deb"
                    ;;
                aarch64)
                    DEB_FILE="fastfetch-linux-aarch64.deb"
                    ;;
            esac
            curl -sSLo "/tmp/fastfetch.deb" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/$DEB_FILE"
            "$ESCALATION_TOOL" "$PACKAGER" install -y /tmp/fastfetch.deb
            rm /tmp/fastfetch.deb
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add fastfetch
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy fastfetch
            ;;
        *)
            "$ESCALATION_TOOL" "$PACKAGER" install -y fastfetch
            ;;
        esac
    else
        printf "%b\n" "${GREEN}Fastfetch is already installed.${RC}"
    fi
}

setupFastfetchConfig() {
    printf "%b\n" "${YELLOW}Copying Fastfetch config files...${RC}"
    if [ -d "${HOME}/.config/fastfetch" ] && [ ! -d "${HOME}/.config/fastfetch-bak" ]; then
        cp -r "${HOME}/.config/fastfetch" "${HOME}/.config/fastfetch-bak"
    fi
    mkdir -p "${HOME}/.config/fastfetch/"
    curl -sSLo "${HOME}/.config/fastfetch/config.jsonc" https://raw.githubusercontent.com/ChrisTitusTech/mybash/main/config.jsonc
}

setupFastfetchShell() {
    printf "%b\n" "${YELLOW}Configuring shell integration...${RC}"

    current_shell=$(basename "$SHELL")
    rc_file=""

    case "$current_shell" in
    "bash")
        rc_file="$HOME/.bashrc"
        ;;
    "zsh")
        rc_file="$HOME/.zshrc"
        ;;
    "fish")
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    "nu")
        rc_file="$HOME/.config/nushell/config.nu"
        ;;
    *)
        printf "%b\n" "${RED}$current_shell is not supported. Update your shell configuration manually.${RC}"
        ;;
    esac

    if [ ! -f "$rc_file" ]; then
        printf "%b\n" "${RED}Shell config file $rc_file not found${RC}"
    else
        if grep -q "fastfetch" "$rc_file"; then
            printf "%b\n" "${YELLOW}Fastfetch is already configured in $rc_file${RC}"
            return 0
        else
            printf "%b" "${GREEN}Would you like to add fastfetch to $rc_file? [y/N] ${RC}"
            read -r response
            if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                printf "\n# Run fastfetch on shell initialization\nfastfetch\n" >>"$rc_file"
                printf "%b\n" "${GREEN}Added fastfetch to $rc_file${RC}"
            else
                printf "%b\n" "${YELLOW}Skipped adding fastfetch to shell config${RC}"
            fi
        fi
    fi

}

checkEnv
checkEscalationTool
installFastfetch
setupFastfetchConfig
setupFastfetchShell
