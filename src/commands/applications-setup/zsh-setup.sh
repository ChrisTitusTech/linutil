#!/bin/sh

. ./common-script.sh

# Function to install zsh
install_zsh() {
  echo "Install ZSH if not already installed..."
    if ! command_exists zsh; then
        case "$PACKAGER" in
            pacman)
                sudo "$PACKAGER" -Sy --noconfirm zsh
                ;;
            *)
                sudo "$PACKAGER" install -y zsh
                ;;
        esac
    else
        echo "ZSH is already installed."
    fi
}

# Function to setup zsh configuration
setup_zsh_config() {
  CONFIG_DIR="$HOME/.config/zsh"
  ZSHRC_FILE="$CONFIG_DIR/.zshrc"

  if [ ! -d "$CONFIG_DIR" ]; then
    mkdir -p "$CONFIG_DIR"
  fi

  # Write the configuration to .zshrc
  cat <<EOL >"$ZSHRC_FILE"
HISTFILE=~/.config/zsh/.histfile
HISTSIZE=5000
SAVEHIST=100000
setopt autocd extendedglob
unsetopt beep
bindkey -v

# Configure the prompt with embedded Solarized color codes
PROMPT='%F{32}%n%f%F{166}@%f%F{64}%m:%F{166}%~%f%F{15}$%f '
RPROMPT='%F{15}(%F{166}%D{%H:%M}%F{15})%f'
EOL

  # Ensure /etc/zsh/zshenv sets ZDOTDIR to the user's config directory
  echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv
}

checkEnv
setup_zsh_config
install_zsh