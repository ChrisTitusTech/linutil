#!/bin/sh

. ../common-script.sh

if command_exists linutil; then
    echo "linutil already exists in your system."
    exit 1
fi

# Bash alias setup script
setup_bash() {
    BASHRC_FILE="$HOME/.bashrc"

    echo

    if [ ! -f "$BASHRC_FILE" ]; then # Checks if the default config exists
        echo ".bashrc not found."

        if [ -f "/etc/skel/.bashrc" ]; then
            echo "Defaults found. Copying."
            cp "/etc/skel/.bashrc" "$BASHRC_FILE" # Copies distro-specific defaults
        else
            echo "Default .bashrc not found. Creating a new one."
            touch "$BASHRC_FILE"
        fi

        echo
    fi

    if grep -Fxq 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' "$BASHRC_FILE"; then # Checks if alias already exists
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' >> "$BASHRC_FILE" # Adds the alias

        echo "Alias added."
        echo
    fi
}

# Zsh alias setup script
setup_zsh() {
    ZSHRC_FILE="$HOME/.zshrc"

    echo

    if [ ! -f "$ZSHRC_FILE" ]; then # Checks if the default config exists
        echo ".zshrc not found. Creating a new one."
        touch "$ZSHRC_FILE"
        echo
    fi

    if grep -Fxq 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' "$ZSHRC_FILE"; then # Checks if alias already exists
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' >> "$ZSHRC_FILE" # Adds the alias

        echo "Alias added."
        echo
    fi
}

# Fish alias setup script
setup_fish() {
    FISHCONF_DIR="$XDG_CONFIG_HOME/fish"
    FISHCONF_FILE="$FISHCONF_DIR/config.fish"

    echo

    if [ ! -d "$FISHCONF_DIR" ]; then
        mkdir "$FISHCONF_DIR"
    fi

    if [ ! -f "$FISHCONF_FILE" ]; then # Checks if the default config exists
        echo "config.fish not found. Creating a new one."
        touch "$FISHCONF_FILE"
        echo
    fi

    if grep -Fxq 'alias linutil "curl -fsSL https://christitus.com/linux | sh"' "$FISHCONF_FILE"; then # Checks if alias already exists
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil "curl -fsSL https://christitus.com/linux | sh"' >> "$FISHCONF_FILE" # Adds the alias

        echo "Alias added."
        echo
    fi
}

# TCSH alias setup script
setup_tcsh() {
    TCSHRC_FILE="$HOME/.tcshrc"

    echo

    if [ ! -f "$TCSHRC_FILE" ]; then # Checks if the default config exists
        echo ".tcshrc not found. Creating a new one."
        touch "$TCSHRC_FILE"
        echo
    fi

    if grep -Fxq 'alias linutil "curl -fsSL https://christitus.com/linux | sh"' "$TCSHRC_FILE"; then # Checks if alias already exists
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil "curl -fsSL https://christitus.com/linux | sh"' >> "$TCSHRC_FILE" # Adds the alias

        echo "Alias added."
        echo
    fi
}

# Ksh alias setup script
setup_ksh() {
    KSHRC_FILE="$HOME/.kshrc"

    echo

    if [ ! -f "$KSHRC_FILE" ]; then # Checks if the default config exists
        echo ".kshrc not found. Creating a new one."
        touch "$KSHRC_FILE"
        echo
    fi

    if grep -Fxq "alias linutil='curl -fsSL https://christitus.com/linux | sh'" "$KSHRC_FILE"; then # Checks if alias already exists
        echo "Alias already exists."
        echo
    else
        echo "alias linutil='curl -fsSL https://christitus.com/linux | sh'" >> "$KSHRC_FILE" # Adds the alias

        echo "Alias added."
        echo
    fi
}

# Nushell alias setup script
setup_nu() {
    NUCONF_DIR="$XDG_CONFIG_HOME/nushell"
    NUCONF_FILE="$NUCONF_DIR/config.nu"

    echo

    if [ ! -d "$NUCONF_DIR" ]; then
        mkdir "$NUCONF_DIR"
    fi

    if [ ! -f "$NUCONF_FILE" ]; then # Checks if the default config exists
        echo "config.nu not found. Creating a new one."
        touch "$NUCONF_FILE"
        echo
    fi

    if grep -Fxq 'alias linutil = curl -fsSL https://christitus.com/linux | sh' "$NUCONF_FILE"; then # Checks if alias already exists
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil = curl -fsSL https://christitus.com/linux | sh' >> "$NUCONF_FILE" # Adds the alias

        echo "Alias added."
        echo
    fi
}

# Function to check for installed shells and invoke setups
check_shells() {
    echo "Checking if Bash is installed..."
    if command_exists bash; then
        echo "Found Bash. Adding the alias..."
        setup_bash
    fi

    echo "Checking if ZSH is installed..."
    if command_exists zsh; then
        echo "Found ZSH. Adding the alias..."
        setup_zsh
    fi

    echo "Checking if Fish is installed..."
    if command_exists fish; then
        echo "Found Fish. Adding the alias..."
        setup_fish
    fi

    echo "Checking if TCSH is installed..."
    if command_exists tcsh; then
        echo "Found TCSH. Adding the alias..."
        setup_tcsh
    fi

    echo "Checking if KornShell is installed..."
    if command_exists ksh; then
        echo "Found KSH. Adding the alias..."
        setup_ksh
    fi

    echo "Checking if Nushell is installed..."
    if command_exists nu; then
        echo "Found Nu. Adding the alias..."
        setup_nu
    fi
}

check_shells