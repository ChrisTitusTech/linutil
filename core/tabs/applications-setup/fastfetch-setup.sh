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
            curl -sSLo /tmp/fastfetch.deb https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb
            "$ESCALATION_TOOL" "$PACKAGER" install -y /tmp/fastfetch.deb
            rm /tmp/fastfetch.deb
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add fastfetch
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

    # Get current shell and RC file path
    current_shell=$(basename "$SHELL")
    rc_file=""

    case "$current_shell" in
    "bash")
        rc_file="$HOME/.bashrc"
        ;;
    "zsh")
        rc_file="$HOME/.zshrc"
        ;;
    *)
        printf "%b\n" "${RED}You sre using shell other than zsh and bash, your shell is: $current_shell${RC}, therefore you have to manually update your rc file."
        other_shell=True
        ;;
    esac

    # Check if RC file exists
    if [ ! -f "$rc_file" ] || [ "$other_shell" != "True" ]; then
        printf "%b\n" "${RED}Shell config file $rc_file${RC} not found" 
    else
        # Check if fastfetch is already in RC file
        if grep -q "fastfetch" "$rc_file"; then
            printf "%b\n" "${YELLOW}Fastfetch is already configured in $rc_file${RC}"
            return 0
        else
            # Ask for confirmation
            printf "%b" "${GREEN}Would you like to add fastfetch to $rc_file? [y/N] ${RC}"
            read -r response

            if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
                printf "\n# Run fastfetch on terminal start\nfastfetch\n" >>"$rc_file"
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
