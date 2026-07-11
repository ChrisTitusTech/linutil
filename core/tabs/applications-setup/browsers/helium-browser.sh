#!/bin/sh -e

. ../../common-script.sh

installHeliumBrowser() {
    if ! command_exists Helium && ! command_exists helium; then
        printf "%b\n" "${YELLOW}Installing Helium Browser...${RC}"
        case "$PACKAGER" in
        pacman)
            "$AUR_HELPER" -S --needed --noconfirm helium-browser-bin
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" copr enable imput/helium
            "$ESCALATION_TOOL" "$PACKAGER" install -y helium-bin
            ;;
        nala|apt-get)
            "$ESCALATION_TOOL" "$PACKAGER" install -y curl
            curl -fsSL https://raw.githubusercontent.com/imputnet/helium-linux/main/pubkey.asc | "$ESCALATION_TOOL" gpg --dearmor -o /usr/share/keyrings/helium.gpg
            echo "deb [signed-by=/usr/share/keyrings/helium.gpg] https://pkg.helium.computer/deb stable main" | "$ESCALATION_TOOL" tee /etc/apt/sources.list.d/helium.list
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
uninstallHeliumBrowser() {
  if command_exists Helium && commands_exists helium; then
    printf "%b\n" "${YELLOW}Removing Helium Browser...${RC}"
    case "$PACKAGER" in
    pacman)
      "$ESCALATION_TOOL" "$PACKAGER" -R --noconfirm --needed helium-browser-bin
      ;;
    dnf)
      "$ESCALATION_TOOL" "$PACKAGER" uninstall helium-bin
      "$ESCALATION_TOOL" "$PACKAGER" copr disable imput/helium
      ;;
    nala | apt-get)
      [[ -f "/usr/share/keyrings/helium.gpg" ]] && rm "/usr/share/keyrings/helium.gpg"
      [[ -f "/etc/apt/sources.list.d/helium.list" ]] && rm "/etc/apt/sources.list.d/helium.list"
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
checkEscalationTool
checkAURHelper
main
