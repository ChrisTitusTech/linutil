#!/bin/sh

# Function to install zsh
install_zsh() {
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update
    sudo apt-get install -y zsh
  elif command -v yum >/dev/null 2>&1; then
    sudo yum install -y zsh
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -Sy zsh
  elif command -v zypper >/dev/null 2>&1; then
    sudo zypper install -y zsh
  else
    echo "No compatible package manager found. Please install zsh manually." >&2
    exit 1
  fi
}

# Function to setup zsh configuration
setup_zsh_config() {
  CONFIG_DIR="$HOME/.config/zsh"
  ZSHRC_FILE="$CONFIG_DIR/.zshrc"

  # Create config directory if it doesn't exist
  mkdir -p "$CONFIG_DIR"

  # Write the configuration to .zshrc
  cat <<EOL >"$ZSHRC_FILE"
# Lines configured by zsh-newuser-install
HISTFILE=~/.config/zsh/.histfile
HISTSIZE=5000
SAVEHIST=100000
setopt autocd extendedglob
unsetopt beep
bindkey -v
# End of lines configured by zsh-newuser-install

# Configure the prompt with embedded Solarized color codes
PROMPT='%F{32}%n%f%F{166}@%f%F{64}%m:%F{166}%~%f%F{15}$%f '
RPROMPT='%F{15}(%F{166}%D{%H:%M}%F{15})%f'
EOL

  # Ensure /etc/zsh/zshenv sets ZDOTDIR to the user's config directory
  echo 'export ZDOTDIR="$HOME/.config/zsh"' | sudo tee -a /etc/zsh/zshenv
}

# Execute the installation and setup
install_zsh

if [ $? -eq 0 ]; then
  echo "zsh installed successfully."
  setup_zsh_config
else
  echo "zsh installation failed."
  exit 1
fi
