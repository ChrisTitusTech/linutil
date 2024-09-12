#!/bin/sh

. ../common-script.sh

setup_bash() {
    BASHRC_FILE="$HOME/.bashrc"

    echo

    if [ ! -f "$BASHRC_FILE" ]; then 
        echo ".bashrc not found."

        if [ -f "/etc/skel/.bashrc" ]; then
            echo "Defaults found. Copying."
            cp "/etc/skel/.bashrc" "$BASHRC_FILE"
        else
            echo "Default .bashrc not found. Creating a new one."
            touch "$BASHRC_FILE"
        fi

        echo
    fi

    if grep -Fxq 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' "$BASHRC_FILE"; then
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' >> "$BASHRC_FILE"

        echo "Alias added."
        echo
    fi
}

setup_zsh() {
    ZSHRC_FILE="$HOME/.zshrc"

    echo

    if [ ! -f "$ZSHRC_FILE" ]; then 
        echo ".zshrc not found. Creating a new one."
        touch "$ZSHRC_FILE"
        echo
    fi

    if grep -Fxq 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' "$ZSHRC_FILE"; then
        echo "Alias already exists."
        echo
    else
        echo 'alias linutil="curl -fsSL https://christitus.com/linux | sh"' >> "$ZSHRC_FILE"

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
        echo "Found Fish."
    fi

    echo "Checking if TCSH is installed..."
    if command_exists tcsh; then
        echo "Found TCSH."
    fi

    echo "Checking if KornShell is installed..."
    if command_exists ksh; then
        echo "Found KSH."
    fi

    echo "Checking if Nushell is installed..."
    if command_exists nu; then
        echo "Found Nu."
    fi
}

check_shells