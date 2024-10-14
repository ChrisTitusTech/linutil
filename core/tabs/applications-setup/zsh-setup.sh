#!/bin/sh

. ../common-script.sh

# Function to install zsh
installZsh() {
  if ! command_exists zsh; then
    printf "%b\n" "${YELLOW}Installing Zsh...${RC}"
      case "$PACKAGER" in
          pacman)
              elevated_execution "$PACKAGER" -S --needed --noconfirm zsh
              ;;
          *)
              elevated_execution "$PACKAGER" install -y zsh
              ;;
      esac
  else
      printf "%b\n" "${GREEN}ZSH is already installed.${RC}"
  fi
}

# Function to setup zsh configuration
setupZshConfig() {
  printf "%b\n" "${YELLOW}Setting up Zsh configuration...${RC}"
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
  [ ! -f /etc/zsh/zshenv ] && elevated_execution mkdir -p /etc/zsh && elevated_execution touch /etc/zsh/zshenv
  echo "export ZDOTDIR=\"$HOME/.config/zsh\"" | elevated_execution tee -a /etc/zsh/zshenv
}

checkEnv
checkEscalationTool
installZsh
setupZshConfig
