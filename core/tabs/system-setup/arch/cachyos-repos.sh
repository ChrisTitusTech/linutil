#!/bin/sh -e

. ../../common-script.sh

checkRepo() {
    hasConfiguredRepos=false
    hasActiveRepos=false
    repoSection='\[cachyos(-[[:alnum:]-]+)?\][[:space:]]*(#.*)?$'
    if grep -Eq "^[[:space:]]*#?[[:space:]]*${repoSection}" /etc/pacman.conf; then
        hasConfiguredRepos=true
    fi
    if grep -Eq "^[[:space:]]*${repoSection}" /etc/pacman.conf; then
        hasActiveRepos=true
    fi
}

checkGrub() {
    if ! command_exists grub-mkconfig || [ ! -f /etc/default/grub ] || [ ! -d /boot/grub ]; then
        printf "%b\n" "${RED}Changing the default kernel requires GRUB. Other bootloaders, including Limine and systemd-boot, are not supported by this action.${RC}"
        return 1
    fi
    if ! grep -q '^GRUB_DEFAULT=' /etc/default/grub; then
        printf "%b\n" "${RED}No GRUB_DEFAULT setting found in /etc/default/grub.${RC}"
        return 1
    fi
}

setupRepos() {
    checkRepo
    if [ "$hasActiveRepos" = false ]; then
        printf "%b\n" "Installing CachyOS repo.."
        curl -f https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
        tar xvf cachyos-repo.tar.xz
        cd cachyos-repo
        "$ESCALATION_TOOL" ./cachyos-repo.sh
        cd ../
        "$ESCALATION_TOOL" rm -rf cachyos-repo cachyos-repo.tar.xz
    else
        printf "%b\n" "CachyOS repos already configured"
    fi
}

setDefaultKernel() {
    checkRepo
    if [ "$hasActiveRepos" = true ]; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos linux-cachyos-headers

        newDefaultKernel='GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"'

        "$ESCALATION_TOOL" sed -i "s/^GRUB_DEFAULT=.*/${newDefaultKernel}/" /etc/default/grub
        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "CachyOS repos are not enabled. Install or enable them in /etc/pacman.conf before installing the kernel."
        return 1
    fi
}

resetDefaultKernel() {
    oldDefaultKernel=$(awk '/^GRUB_DEFAULT=/{print; exit}' /etc/default/grub)

    if [ "$oldDefaultKernel" = 'GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"' ]; then
        newDefaultKernel="GRUB_DEFAULT=0"

        "$ESCALATION_TOOL" sed -i "s/^GRUB_DEFAULT=.*/${newDefaultKernel}/" /etc/default/grub
        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "CachyOS is not the default kernel"
    fi
}

removeRepos() {
    checkRepo
    if [ "$hasConfiguredRepos" = true ]; then
        printf "%b\n" "Removing CachyOS repo.."
        curl -f https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
        tar xvf cachyos-repo.tar.xz
        cd cachyos-repo
        "$ESCALATION_TOOL" ./cachyos-repo.sh --remove
        cd ../
        "$ESCALATION_TOOL" rm -rf cachyos-repo cachyos-repo.tar.xz
    else
        printf "%b\n" "CachyOS repo is not installed"
    fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall CachyOS${RC}"
    printf "%b\n" "1. ${YELLOW}Install CachyOS repos${RC}"
    printf "%b\n" "2. ${YELLOW}Set CachyOS-LTS default as kernel${RC}"
    printf "%b\n" "3. ${YELLOW}Install CachyOS repos and and set CachyOS-LTS as default kernel${RC}"
    printf "%b\n" "4. ${YELLOW}Remove CachyOS Repos and set default kernel to stock${RC}"
    printf "%b\n" "5. ${YELLOW}Reset default kernel to stock${RC}"
    printf "%b" "Enter your choice [1-5]: "
    read -r CHOICE
    case "$CHOICE" in
        2|3|4|5) checkGrub ;;
    esac
    checkEnv
    case "$CHOICE" in
        1) setupRepos ;;
        2) setDefaultKernel ;;
        3) setupRepos
           setDefaultKernel ;;
        4) removeRepos
           resetDefaultKernel;;
        5) resetDefaultKernel ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

main
