#!/bin/sh -e

. ../../common-script.sh

installOnlyOffice() {
  if ! command_exists org.onlyoffice.desktopeditors && ! command_exists onlyoffice-desktopeditors; then
    printf "%b\n" "${YELLOW}Installing Only Office..${RC}."
    case "$PACKAGER" in
    apt-get | nala)
      curl -O https://download.onlyoffice.com/install/desktop/editors/linux/onlyoffice-desktopeditors_amd64.deb
      "$ESCALATION_TOOL" "$PACKAGER" install -y ./onlyoffice-desktopeditors_amd64.deb
      "$ESCALATION_TOOL" rm ./onlyoffice-desktopeditors_amd64.deb
      ;;
    pacman)
      "$AUR_HELPER" -S --needed --noconfirm onlyoffice-bin
      ;;
    *)
      checkFlatpak
      "$ESCALATION_TOOL" flatpak --noninteractive org.onlyoffice.desktopeditors
      ;;
    esac
  else
    printf "%b\n" "${GREEN}Only Office is already installed.${RC}"
  fi
}

checkEnv
installOnlyOffice
