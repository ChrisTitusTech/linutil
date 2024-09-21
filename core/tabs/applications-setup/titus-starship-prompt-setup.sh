#!/bin/sh -e

. ../common-script.sh

# HACK: Only Setup Titus Starship prompt without compromising with your bash or zsh config

cmdCheck() {
  if [ $? -eq 0 ]; then
    printf "%b\n" "${GREEN}**SUCCESS**${RC}"
  else
    printf "%b\n" "${RED}**FAIL**${RC}"
  fi
}

installStarship() {
  if ! command_exists starship; then
    printf "%b\n" "${CYAN} Installing starship ${RC}"
    curl -sS https://starship.rs/install.sh | sh
    cmdCheck
  else
    printf "%b\n" "${CYAN} Starship is already installed ${RC}"
  fi
}

setupStarshipTomlFile() {
  printf "%b\n" "${YELLOW} Copying starship prompt config ${RC}"
  if [ -d "$HOME/.config/starship" ]; then
    printf "%b\n" "${CYAN} Backing up existing starship prompt ${RC}"
    mv "$HOME/.config/starship/" "$HOME/.config/starship.bk/"
    cmdCheck
    printf "%b\n" "${CYAN} Download Titus starship prompt file ${RC}"
    mkdir -p "$HOME/.config/starship/"
    curl -sSLo "$HOME/.config/starship/starship.toml" "https://github.com/ChrisTitusTech/mybash/raw/main/starship.toml"
    cmdCheck
  else
    printf "%b\n" "${CYAN} Download Titus starship prompt file ${RC}"
    mkdir -p "$HOME/.config/starship/"
    curl -sSLo "$HOME/.config/starship/starship.toml" "https://github.com/ChrisTitusTech/mybash/raw/main/starship.toml"
    cmdCheck
  fi
}

# NOTE: Checking if starship config line exist in particular shell
configureShell() {
  printf "%b\n" "${CYAN} Setting up your shell. ${RC}"
  if [ -e "$HOME/.bashrc" ]; then
    printf "%b\n" "${CYAN} Setting up bash to use starship as default prompt ${RC}"
    printf "%s\n" 'eval "$(starship init bash)"' >>"$HOME/.bashrc"
    printf "%s\n" "export STARSHIP_CONFIG=~/.config/starship/starship.toml" >>"$HOME/.bashrc"
    cmdCheck
  fi

  if [ -e "$HOME/.zshrc" ]; then
    printf "%b\n" "${CYAN} Setting up zsh to use starship as default prompt ${RC}"
    printf "%s\n" 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    printf "%s\n" "export STARSHIP_CONFIG=~/.config/starship/starship.toml" >> "$HOME/.zshrc"
    cmdCheck
  fi

  # NOTE: There is a script in linutil application section which sets up zsh in .config directory.
  # I need to add this config just for that script, if someone has configured their z shell using linutil
  if [ -e "$HOME/.config/.zshrc" ]; then
    printf "%b\n" "${CYAN} Setting up zsh to use starship as default prompt ${RC}"
    printf "%s\n" 'eval "$(starship init fish)"' >> "$HOME/.config/.zshrc"
    printf "%s\n" "export STARSHIP_CONFIG=~/.config/starship/starship.toml" >> "$HOME/.config/.zshrc"
    cmdCheck
  fi
}

checkEnv
printf "%b\n" "${YELLOW}NOTE: currently this script only support bash and zsh."
installStarship
setupStarshipTomlFile
configureShell
printf "%b\n" "${GREEN} Starship Setup is now complete ${RC}"
