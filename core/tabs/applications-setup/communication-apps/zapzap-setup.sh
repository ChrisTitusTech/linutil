#!/bin/sh -e

. ../../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1
APP_FLATPAK_ID="com.rtosta.zapzap"
APP_UNINSTALL_PKGS="com.rtosta.zapzap flathub"


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
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    uninstall_app "$APP_FLATPAK_ID" "$APP_UNINSTALL_PKGS"
    exit 0
fi


installZapZap
