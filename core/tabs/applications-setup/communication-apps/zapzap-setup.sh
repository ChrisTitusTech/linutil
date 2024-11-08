#!/bin/sh -e

. ../../common-script.sh

installZapZap() {
  if ! command_exists com.rtosta.zapzap && ! command_exists zapzap; then
  printf "%b\n" "${YELLOW}Installing Zap-Zap...${RC}"
    case "$PACKAGER" in
      pacman)
        "$AUR_HELPER" -S --needed --noconfirm zapzap
        ;;
      *)
        checkFlatpak
        flatpak install flathub com.rtosta.zapzap
        ;;
    esac
  else
    printf "%b\n" "${GREEN}Zap-Zap is already installed.${RC}"
  fi
}

checkEnv
installZapZap
