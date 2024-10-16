#!/bin/sh -e

. ../../common-script.sh

installWhatsapp() {
  printf "%b\n" "${YELLOW}The app we are installing is Zap-Zap, an Open Source Desktop Client for Linux${RC}"
  case "$PACKAGER" in
  pacman)
    if ! command_exists zapzap; then
      printf "%b\n" "${YELLOW}Installing Whatsapp(Zap-Zap by rtosta) AUR PACKAGE${RC}"
      "$AUR_HELPER" -S --needed --noconfirm zapzap
      printf "%b\n" "${GREEN}WhatsApp(Zap-Zap by rtosta) is installed. Search ZapZap to start WhatsApp${RC}"
      return
    else
      printf "%b\n" "${GREEN}Whatsapp(Zap-Zap by rtosta) is already installed${RC}"
      return
    fi
    ;;
  *)
    . ../setup-flatpak.sh
    printf "%b\n" "${YELLOW} Installing Whatsapp(Zap-Zap by rtosta) Flatpak ${RC}"
    flatpak install flathub com.rtosta.zapzap
    printf "%b\n" "${GREEN}WhatsApp(Zap-Zap by rtosta) is installed. Search ZapZap to start WhatsApp${RC}"
    return
    ;;
  esac
}

checkEnv
installWhatsapp
