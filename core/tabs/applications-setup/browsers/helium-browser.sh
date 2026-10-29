#!/bin/sh -e

. ../../common-script.sh

checkHeliumInstalled() {
  command_exists helium-browser || command_exists helium || command_exists Helium
}

installHeliumBrowser() {
  if ! checkHeliumInstalled; then
    printf "%b\n" "${YELLOW}Installing Helium Browser...${RC}"
    case "$PACKAGER" in
    pacman)
      "$AUR_HELPER" -S --needed --noconfirm helium-browser-bin
      ;;
    dnf)
      "$ESCALATION_TOOL" "$PACKAGER" copr enable imput/helium
      "$ESCALATION_TOOL" "$PACKAGER" install -y helium-bin
      ;;
    nala | apt-get)
      # apt reads an .asc key as is, so gpg (missing on minimal installs) is not needed.
      "$ESCALATION_TOOL" curl -fsSLo /usr/share/keyrings/helium.asc https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc
      echo "deb [signed-by=/usr/share/keyrings/helium.asc] https://pkg.helium.computer/deb stable main" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/helium.list
      "$ESCALATION_TOOL" "$PACKAGER" update
      "$ESCALATION_TOOL" "$PACKAGER" install -y helium-bin
      ;;
    *)
      printf "%b\n" "${RED}Helium doesn't support ${PACKAGER}${RC}"
      ;;
    esac
  else
    printf "%b\n" "${GREEN}Helium Browser is already installed.${RC}"
  fi
}

uninstallHeliumBrowser() {
  if checkHeliumInstalled; then
    printf "%b\n" "${YELLOW}Removing Helium Browser...${RC}"
    case "$PACKAGER" in
    pacman)
      "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm helium-browser-bin
      ;;
    dnf)
      "$ESCALATION_TOOL" "$PACKAGER" remove -y helium-bin
      "$ESCALATION_TOOL" "$PACKAGER" copr disable imput/helium
      ;;
    nala | apt-get)
      # helium.gpg is the key older versions of this script installed.
      "$ESCALATION_TOOL" rm -f /usr/share/keyrings/helium.asc /usr/share/keyrings/helium.gpg /etc/apt/sources.list.d/helium.list
      "$ESCALATION_TOOL" "$PACKAGER" update
      "$ESCALATION_TOOL" "$PACKAGER" purge --autoremove -y helium-bin
      ;;
    esac
  else
    printf "%b\n" "${GREEN}Helium Browser is not installed.${RC}"
  fi
}

main() {
  printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Helium Browser?${RC}"
  printf "%b\n" "1. ${YELLOW}Install Helium Browser${RC}"
  printf "%b\n" "2. ${YELLOW}Uninstall Helium Browser${RC}"
  printf "%b" "Enter your choice [1-2]: "
  read -r CHOICE
  case "$CHOICE" in
  1) installHeliumBrowser ;;
  2) uninstallHeliumBrowser ;;
  *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
  esac
}

checkEnv
main
