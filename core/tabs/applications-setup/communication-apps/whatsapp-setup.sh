#!/bin/sh -e

. ../../common-script.sh

installWhatsapp() {
  printf "%b\n" "${YELLOW}The app we are installing is Zap-Zap, an Open Source Desktop Client for Linux${RC}"
  if ! command_exists com.rtosta.zapzap && ! command_exists zapzap; then
    printf "%b\n" "${YELLOW}Installing Whatsapp(Zap-Zap by rtosta)${RC}"
    case "$PACKAGER" in
      pacman)
        "$AUR_HELPER" -S --needed --noconfirm zapzap
        ;;
      *)
        . ../setup-flatpak.sh
        flatpak install flathub com.rtosta.zapzap
        ;;
    esac
  else
    printf "%b\n" "${GREEN}WhatsApp(Zap-Zap by rtosta) is already installed.${RC}"
  fi
}

checkEnv
installWhatsapp
