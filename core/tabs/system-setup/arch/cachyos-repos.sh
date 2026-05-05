#!/bin/sh -e

. ../../common-script.sh

checkRepo() {
    "$ESCALATION_TOOL" cat /etc/pacman.conf | grep "(cachyos\|cachyos-v3\|cachyos-core-v3\|cachyos-extra-v3\|cachyos-testing-v3\|cachyos-v4\|cachyos-core-v4\|cachyos-extra-v4\|cachyos-znver4\|cachyos-core-znver4\|cachyos-extra-znver4)" > /dev/null
    isInstalled=$?
    printf "%b\n" "Installed Status: $isInstalled"
    "$ESCALATION_TOOL" cat /etc/pacman.conf | grep "cachyos\|cachyos-v3\|cachyos-core-v3\|cachyos-extra-v3\|cachyos-testing-v3\|cachyos-v4\|cachyos-core-v4\|cachyos-extra-v4\|cachyos-znver4\|cachyos-core-znver4\|cachyos-extra-znver4" | grep -v "#\[" | grep "\[" > /dev/null
    isCommented=$?
}

setupRepos() {
    checkRepo
    if [ "$isInstalled" -ne "0" ]; then
        printf "%b\n" "Installing CachyOS repo.."
        curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
        tar xvf cachyos-repo.tar.xz && cd cachyos-repo
        "$ESCALATION_TOOL" ./cachyos-repo.sh
        cd ../
        "$ESCALATION_TOOL" rm -rf cachyos-repo*
    else
        printf "%b\n" "CachyOS repo already installed"
    fi
}

setDefaultKernel() {
    checkRepo
    if [ "$isInstalled" -ne "0" ] || [ "$isCommented" -ne "0" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos linux-cachyos-headers

        oldDefaultKernel=$(cat /etc/default/grub | grep GRUB_DEFAULT | awk 'NR==1{print}')
        newDefaultKernel='GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"'

        "$ESCALATION_TOOL" sed -i "s/${oldDefaultKernel}/${newDefaultKernel}/g" /etc/default/grub || 

        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "CachyOS repos are not installed.  Please install before Installing Kernel"
    fi
}

resetDefaultKernel() {
    oldDefaultKernel=$(cat /etc/default/grub | grep GRUB_DEFAULT | awk 'NR==1{print}')

    if "$oldDefaultKernel" -eq "GRUB_DEFAULT=\"Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts\""; then      
        newDefaultKernel="GRUB_DEFAULT=0"

        "$ESCALATION_TOOL" sed -i "s/${oldDefaultKernel}/${newDefaultKernel}/g" /etc/default/grub || 

        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "CachyOS is not the default kernel"
    fi
}

removeRepos() {
    checkRepo
    if [ "$isInstalled" -eq "0" ]; then
        printf "%b\n" "Removing CachyOS repo.."
        curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
        tar xvf cachyos-repo.tar.xz && cd cachyos-repo
        "$ESCALATION_TOOL" ./cachyos-repo.sh --remove
        cd ../
        "$ESCALATION_TOOL" rm -rf cachyos-repo*
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

checkEnv
main