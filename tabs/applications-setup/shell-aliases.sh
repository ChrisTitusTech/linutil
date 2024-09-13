#!/bin/sh -e

. ../common-script.sh

check_shells() {
    config_home="$HOME/.config"

    for shell in bash zsh fish tcsh ksh nu; do                                           # Supported shells
        if command_exists "$shell"; then
            setup_alias "$shell"
        fi
    done
}

setup_alias() {
    shell="$1"
    config_file=""
    alias_line=""

    case "$shell" in                                                                     # Different config files & syntax for shells
        bash|zsh|ksh)
            config_file="$HOME/.${shell}rc"
            alias_line="alias linutil='curl -fsSL https://christitus.com/linux | sh'"
            ;;
        fish)
            config_file="$config_home/fish/config.fish"
            alias_line="alias linutil 'curl -fsSL https://christitus.com/linux | sh'"
            ;;
        tcsh)
            config_file="$HOME/.tcshrc"
            alias_line="alias linutil 'curl -fsSL https://christitus.com/linux | sh'"
            ;;
        nu)
            config_file="$config_home/nushell/config.nu"
            alias_line="alias linutil = curl -fsSL https://christitus.com/linux | sh"
            ;;
    esac

    if [ ! -f "$config_file" ]; then
        if [ "$shell" = bash ] && [ -f "/etc/skel/.bashrc" ]; then                       # Default distro-specific config for bash
            cat "/etc/skel/.bashrc" > "$config_file"
            echo "Copied default config to $config_file."
        else
            echo "Creating $config_file ."
            touch "$config_file"
        fi
    fi

    if grep "^$alias_line$" "$config_file" > /dev/null; then
        echo "Alias already exists in $config_file."
    else
        echo "$alias_line" >> "$config_file"
        echo "Alias added to $config_file."
    fi
}

check_shells
