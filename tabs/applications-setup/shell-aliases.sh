#!/bin/sh

. ../common-script.sh

if command_exists linutil; then
    echo "linutil already exists in your system."
    exit 1
fi

shells=(bash zsh fish tcsh ksh nu)                                                    # Supported shells
configs=(.bashrc .zshrc config.fish .tcshrc .kshrc config.nu)                         # Shell config filenames
aliases=("alias linutil=\"curl -fsSL https://christitus.com/linux | sh\""             # Alias structures for different shell configs
         "alias linutil=\"curl -fsSL https://christitus.com/linux | sh\""
         "alias linutil \"curl -fsSL https://christitus.com/linux | sh\""
         "alias linutil \"curl -fsSL https://christitus.com/linux | sh\""
         "alias linutil='curl -fsSL https://christitus.com/linux | sh'"
         "alias linutil = curl -fsSL https://christitus.com/linux | sh")

for ((i=0; i<${#shells[@]}; i++)); do
    if command_exists ${shells[$i]}; then
        echo "Found ${shells[$i]}. Adding the alias..."
        config_file="$HOME/${configs[$i]}"
        if [ ! -f "$config_file" ]; then
            if [ "${shells[$i]}" == "fish" ] || [ "${shells[$i]}" == "nu" ]; then     # Change config dirs for specific shells
                config_dir="$XDG_CONFIG_HOME/${shells[$i]}"
                mkdir -p "$config_dir"
                config_file="$config_dir/${configs[$i]}"
            elif [ "${shells[$i]}" == "bash" ] && [ -f "/etc/skel/.bashrc" ]; then    # Default distro-specific config for bash
                cp "/etc/skel/.bashrc" "$config_file"
            else
                touch "$config_file"
            fi
        fi
        if ! grep -Fxq "${aliases[$i]}" "$config_file"; then                          # Check if alias already exists
            echo "${aliases[$i]}" >> "$config_file"
            echo "Alias added."
        else
            echo "Alias already exists."
        fi
        echo
    fi
done
