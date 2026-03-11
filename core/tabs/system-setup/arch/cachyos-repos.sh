#!/bin/sh -e

. ../../common-script.sh

CheckCPU() {
    /lib/ld-linux-x86-64.so.2 --help | grep "$1 (supported, searched)" > /dev/null
    v4Supported=$?
    gcc -march=native -Q --help=target 2>&1 | grep 'march' | grep -E '(znver4|znver5)' > /dev/null
    isAM5=$?
}

checkRepo() {
    cat /etc/pacman.conf | grep "(cachyos\|cachyos-v3\|cachyos-core-v3\|cachyos-extra-v3\|cachyos-testing-v3\|cachyos-v4\|cachyos-core-v4\|cachyos-extra-v4\|cachyos-znver4\|cachyos-core-znver4\|cachyos-extra-znver4)" > /dev/null
    isInstalled=$?
    cat /etc/pacman.conf | grep "cachyos\|cachyos-v3\|cachyos-core-v3\|cachyos-extra-v3\|cachyos-testing-v3\|cachyos-v4\|cachyos-core-v4\|cachyos-extra-v4\|cachyos-znver4\|cachyos-core-znver4\|cachyos-extra-znver4" | grep -v "#\[" | grep "\[" > /dev/null
    isCommented=$?
}

addRepo() {
    version="${1:-v3}"   # default to v3 if not provided

    gawk -i inplace -v version="$version" '
    BEGIN {
        err = 1
        repo1 = "[cachyos-" version "]"
        repo2 = "[cachyos-core-" version "]"
        repo3 = "[cachyos-extra-" version "]"
        mirror1 = "Include = /etc/pacman.d/cachyos-" version "-mirrorlist"
    }

    {
        if ($0 == "[options]") {
            print
            next
        } else if ($0 == "[cachyos]" || $0 == repo1 || $0 == repo2 || $0 == repo3) {
            if (set) {
                rm = 2
            }
            set = 1
        } else if ($0 == "Architecture = x86_64" ||
                $0 == "Architecture = x86_64 x86_64_v3" ||
                $0 == "Architecture = x86_64 x86_64_v3 x86_64_v4") {
            print "Architecture = auto"
            next
        }

        if (rm) {
            rm--
            next
        }
    }

    /^\[[^ \[\]]+\]/ {
        if (!set) {
            print repo1
            print mirror1
            print ""

            print repo2
            print mirror1
            print ""

            print repo3
            print mirror1
            print ""

            print "[cachyos]"
            print "Include = /etc/pacman.d/cachyos-mirrorlist"
            print ""

            set = 1
            err = 0
        }
    }

    END { exit err }

    1
    ' "/etc/pacman.conf"
}

setupRepos() {
    printf "%b\n" "Installing CachyOS repo.."

    pacman-key --recv-keys F3B607488DB35A47 --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key F3B607488DB35A47

    mirror_url="https://mirror.cachyos.org/repo/x86_64/cachyos"

    pacman -U "${mirror_url}/cachyos-keyring-20240331-1-any.pkg.tar.zst" \
              "${mirror_url}/cachyos-mirrorlist-22-1-any.pkg.tar.zst"    \
              "${mirror_url}/cachyos-v3-mirrorlist-22-1-any.pkg.tar.zst" \
              "${mirror_url}/cachyos-v4-mirrorlist-22-1-any.pkg.tar.zst"  \
              "${mirror_url}/pacman-7.1.0.r9.g54d9411-2-x86_64.pkg.tar.zst"

    mv /etc/pacman.conf /etc/pacman.conf.bak
    checkRepo
    checkCPU x86-64-v4

    if [ "$isInstalled" -ne "0" ] || [ "$isCommented" -ne "0" ]; then
        if [ $isAM5 -eq "0" ]; then
            addRepo znver4
        elif [ "$v4Supported" -eq "0" ]; then
            addRepo v4
        else
            addRepo v3
        fi
    else
        printf "%b\n" "Repo is already added!"
    fi

    printf "%b\n" "Done installing CachyOS repo."
}

installKernel() {
    if [ "$isInstalled" -ne "0" ] || [ "$isCommented" -ne "0" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm linux-cachyos linux-cachyos-headers linux-cachyos-lts linux-cachyos-lts-headers

        oldDefaultKernel="GRUB_DEFAULT=0"
        newDefaultKernel='GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"'

        sed -i "s/${oldDefaultKernel}/${newDefaultKernel}/g" /etc/default/grub

        "$ESCALATION_TOOL" grub-mkconfig -o /boot/grub/grub.cfg
    else
        printf "%b\n" "CachyOS Repos are not installed.  Please install before Installing Kernel"
        break
    fi
}

removeRepos() {
    printf "%b\n" "Removing CachyOS repo.."

    checkRepo
    if [ "$isInstalled" -eq "0" ] || [ "$isCommented" -eq "0" ]; then
       
        mv /etc/pacman.conf.bak /etc/pacman.conf 
        pacman -Suuy
        pacman -S core/pacman
        pacman -Qqn | pacman -S -

        pacman -R "cachyos-keyring"       \
                  "cachyos-mirrorlist"    \
                  "cachyos-v3-mirrorlist" \
                  "cachyos-v4-mirrorlist"

        pacman-key --delete F3B607488DB35A47 || true
    else
        printf "%b\n" "Repo is not added!"
    fi

    printf "%b\n" "Done removing CachyOS repo."
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall CachyOS${RC}"
    printf "%b\n" "1. ${YELLOW}Install CachyOS Repos${RC}"
    printf "%b\n" "2. ${YELLOW}Install CachyOS Kernel${RC}"
    printf "%b\n" "1. ${YELLOW}Install CachyOS Repos and Kernel${RC}"
    printf "%b\n" "2. ${YELLOW}Remove CachyOS Kernel${RC}"
    printf "%b" "Enter your choice [1-4]: "
    read -r CHOICE
    case "$CHOICE" in
        1) setupRepos ;;
        2) installKernel ;;
        3) setupRepos
           installKernel ;;
        4) removeRepos ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
main