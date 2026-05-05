#!/bin/sh -e

. ../common-script.sh

installTopgrade() {
  printf "%b\n" "${YELLOW}Installing topgrade...${RC}"
  case "$PACKAGER" in
  pacman)
    "$AUR_HELPER" -S --needed --noconfirm topgrade
    ;;
  zypper)
    "$ESCALATION_TOOL" "$PACKAGER" install -y topgrade
    ;;
  apt-get | apt | nala)
    "$ESCALATION_TOOL" "$PACKAGER" update
    "$ESCALATION_TOOL" "$PACKAGER" install -y cargo libssl-dev pkg-config
    cargo install topgrade-rs
    ;;
  dnf)
    "$ESCALATION_TOOL" "$PACKAGER" install -y cargo openssl-devel pkg-config
    cargo install topgrade-rs
    ;;
  *)
    printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
    exit 1
    ;;
  esac
  if [ -d "$HOME/.cargo/bin" ]; then
    export PATH="$HOME/.cargo/bin:$PATH"
  fi
}

runTopgrade() {
  printf "%b\n" "${YELLOW}Topgrade config is stored at ~/.config/topgrade.toml${RC}"
  printf "%b\n" "${CYAN}You can edit it to customize update behavior.${RC}"

  export PATH="$HOME/.cargo/bin:$PATH"

  printf "%b\n" "${YELLOW}Running topgrade...${RC}"
  if command_exists topgrade; then
    topgrade
  else
    installTopgrade
    topgrade
  fi
}

checkEnv
checkEscalationTool
checkDistro
runTopgrade
