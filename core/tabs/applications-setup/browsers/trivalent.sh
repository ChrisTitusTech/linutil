#!/bin/sh -e

. ../../common-script.sh

installTrivalent() {
    if ! command_exists trivalent && ! command_exists trivalent; then
        printf "%b\n" "${YELLOW}Installing Trivalent...${RC}"

        # rpm-ostree handle
        if command_exists rpm-ostree; then
            printf "%b\n" "${YELLOW}Detected rpm-ostree (ostree-based system). Adding SecureBlue repo and layering package...${RC}"
            "$ESCALATION_TOOL" curl -fsSLo /etc/yum.repos.d/secureblue.repo https://repo.secureblue.dev/secureblue.repo || true
            printf "%b\n" "${YELLOW}Running rpm-ostree install trivalent (will require a reboot to take effect)...${RC}"
            "$ESCALATION_TOOL" rpm-ostree install trivalent || {
                printf "%b\n" "${RED}rpm-ostree install failed. You may need to layer the RPM manually or check the secureblue repo.${RC}"
                exit 1
            }
            printf "%b\n" "${GREEN}Requested rpm-ostree layering of trivalent. Reboot required to apply changes.${RC}"
            return 0
        fi

        case "$PACKAGER" in
            pacman)
                # unofficial aur package
                checkAURHelper
                "$AUR_HELPER" -S --needed --noconfirm trivalent-bin
                ;;
            dnf)
                printf "%b\n" "${YELLOW}Adding SecureBlue repository file and installing trivalent via dnf...${RC}"
                "$ESCALATION_TOOL" curl -fsSLo /etc/yum.repos.d/secureblue.repo https://repo.secureblue.dev/secureblue.repo || true
                "$ESCALATION_TOOL" "$PACKAGER" makecache || true
                "$ESCALATION_TOOL" "$PACKAGER" install -y trivalent || {
                    printf "%b\n" "${RED}Failed to install trivalent via dnf. Check repo availability or package name.${RC}"
                    exit 1
                }
                ;;
            # 0 support distros (for now)
            zypper)
                printf "%b\n" "${RED}Trivalent is not published as an RPM for openSUSE and cant be installed via zypper.${RC}"
                printf "%b\n" "${YELLOW}You however can::${RC}"
                printf "%b\n" " - Run Trivalent in a container (Fedora distrobox recommended) or VM"
                printf "%b\n" " - Build Trivalent from source: https://github.com/secureblue/Trivalent"
                printf "%b\n" " - Keep an eye ouu, this might chnage in the future."
                exit 1
                ;;
            apt-get|nala)
                printf "%b\n" "${RED}Trivalent has no official Debian/Ubuntu packages. ${YELLOW}Options:${RC}"
                printf "%b\n" " - Build from source: https://github.com/secureblue/Trivalent"
                exit 1
                ;;
            xbps-install|apk)
                printf "%b\n" "${RED}Trivalent is not officially packaged for this distribution. Consider using a supported distro or building from source.${RC}"
                exit 1
                ;;
            *)
                printf "%b\n" "${RED}Unsupported package manager: ${PACKAGER}${RC}"
                exit 1
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Trivalent is already installed.${RC}"
    fi
}

uninstallTrivalent() {
    # rpm-ostree handle
    if command_exists rpm-ostree; then
        printf "%b\n" "${YELLOW}Detected rpm-ostree. Attempting to unlayer trivalent...${RC}"
        if "$ESCALATION_TOOL" rpm-ostree uninstall trivalent 2>/dev/null; then
            printf "%b\n" "${GREEN}Requested rpm-ostree uninstall of trivalent succeeded. Reboot to apply changes.${RC}"
        elif "$ESCALATION_TOOL" rpm-ostree override remove trivalent 2>/dev/null; then
            printf "%b\n" "${GREEN}Requested rpm-ostree override remove of trivalent succeeded. Reboot to apply changes.${RC}"
        else
            printf "%b\n" "${RED}Failed to remove trivalent via rpm-ostree. Use 'rpm-ostree status' and 'rpm-ostree override remove <pkg>' manually.${RC}"
            exit 1
        fi

        printf "%b\n" "${YELLOW}Note: SecureBlue repo file (if present) was NOT removed. Remove /etc/yum.repos.d/secureblue.repo manually if you want.${RC}"
        printf "%b\n" "${YELLOW}Reboot is required to apply the OSTree changes.${RC}"
        return 0
    fi

    if command_exists trivalent || command_exists trivalent; then
        printf "%b\n" "${YELLOW}Uninstalling Trivalent...${RC}"
        case "$PACKAGER" in
            pacman)
                checkAURHelper
                "$AUR_HELPER" -Rns --noconfirm trivalent-bin || true
                ;;
            dnf)
                "$ESCALATION_TOOL" "$PACKAGER" remove -y trivalent || "$ESCALATION_TOOL" "$PACKAGER" remove -y trivalent || true
                ;;
            zypper)
                # useful if manually installed? could remove
                "$ESCALATION_TOOL" "$PACKAGER" remove -y trivalent || "$ESCALATION_TOOL" rpm -e trivalent || true
                ;;
            *)
                printf "%b\n" "${YELLOW}Removal for ${PACKAGER} not implemented; try your package manager manually.${RC}"
                ;;
        esac
    else
        printf "%b\n" "${GREEN}Trivalent is not installed.${RC}"
    fi
}

main() {
  printf "%b\n" "${YELLOW}Do you want to Install or Uninstall Trivalent Browser?${RC}"
  printf "%b\n" "1. ${YELLOW}Install Trivalent Browser${RC}"
  printf "%b\n" "2. ${YELLOW}Uninstall Trivalent Browser${RC}"
  printf "%b" "Enter your choice [1-2]: "
  read -r CHOICE
  case "$CHOICE" in
  1) installTrivalent ;;
  2) uninstallTrivalent ;;
  *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
  esac
}

checkEnv
main
