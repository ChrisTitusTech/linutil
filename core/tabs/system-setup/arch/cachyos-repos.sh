#!/bin/sh -e

. ../../common-script.sh

checkRepo() {
    if ! repoList=$(pacman-conf --repo-list); then
        printf '%s\n' "Could not read the pacman repository configuration." >&2
        return 1
    fi
    activeRepos=$(printf '%s\n' "$repoList" | grep -E '^cachyos(-[[:alnum:]-]+)?$' || :)
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

runRepoHelper() (
    workdir=$(mktemp -d)
    trap '"$ESCALATION_TOOL" rm -rf -- "$workdir"' 0
    cd "$workdir"
    curl -f https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz
    cd cachyos-repo
    "$ESCALATION_TOOL" ./cachyos-repo.sh "$@"
)

setupRepos() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        printf "%b\n" "CachyOS repos already configured"
    elif grep -Eq '^[[:space:]]*#[[:space:]]*\[cachyos(-[[:alnum:]-]+)?\][[:space:]]*(#.*)?$' /etc/pacman.conf; then
        printf "%b\n" "Enable the commented CachyOS repos in /etc/pacman.conf before continuing."
        return 1
    else
        printf "%b\n" "Installing CachyOS repo.."
        runRepoHelper
        checkRepo
        if [ -z "$activeRepos" ]; then
            printf "%b\n" "The installer did not enable CachyOS repos in /etc/pacman.conf."
            return 1
        fi
    fi
}

verifyGrubEntry() {
    # Check the standard 10_linux layout. Leave custom menus alone.
    # shellcheck disable=SC2016
    "$ESCALATION_TOOL" awk -F "'" -v setting="$1" '
        setting == "GRUB_DEFAULT=0" {
            if ($1 ~ /^menuentry[[:space:]]/) {
                if (++entries > 1) exit
            } else if ($1 ~ /^submenu[[:space:]]/) {
                exit
            } else if (entries == 1 && $0 ~ /^[[:space:]]+linux(efi)?[[:space:]]+[^[:space:]]*\/vmlinuz-linux(-lts)?[[:space:]]/) {
                found = 1
                exit
            }
        }
        setting != "GRUB_DEFAULT=0" {
            if ($1 ~ /^submenu[[:space:]]/) cachyosSubmenu = ($2 == "Advanced options for Arch Linux")
            if ($0 ~ /^}/) cachyosSubmenu = 0
            if (cachyosSubmenu && $1 ~ /^[[:space:]]+menuentry[[:space:]]/ &&
                $2 == "Arch Linux, with Linux linux-cachyos-lts") found = 1
        }
        END { exit !found }
    ' "$2"
}

updateGrubDefault() (
    backup=$("$ESCALATION_TOOL" mktemp /etc/default/grub.linutil.XXXXXX)
    candidate=
    trap '"$ESCALATION_TOOL" rm -f -- ${backup:+"$backup"} ${candidate:+"$candidate" "$candidate.new"}' 0
    candidate=$("$ESCALATION_TOOL" mktemp /boot/grub/grub.cfg.linutil.XXXXXX)
    "$ESCALATION_TOOL" cp -p /etc/default/grub "$backup"
    "$ESCALATION_TOOL" sed -i "s/^GRUB_DEFAULT=.*/$1/" /etc/default/grub
    if "$ESCALATION_TOOL" grub-mkconfig -o "$candidate" &&
        verifyGrubEntry "$1" "$candidate" &&
        "$ESCALATION_TOOL" mv -f -- "$candidate" /boot/grub/grub.cfg; then
        return 0
    else
        status=$?
        printf '%s\n' "Could not verify and install the requested GRUB default." >&2
        if ! "$ESCALATION_TOOL" mv -f -- "$backup" /etc/default/grub; then
            backup_path=$backup
            backup=
            printf '%s\n' "Could not restore GRUB settings. Backup kept at $backup_path." >&2
        fi
        return "$status"
    fi
)

setDefaultKernel() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos linux-cachyos-headers

        newDefaultKernel='GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"'

        updateGrubDefault "$newDefaultKernel"
    else
        printf "%b\n" "CachyOS repos are not enabled. Install or enable them in /etc/pacman.conf before installing the kernel."
        return 1
    fi
}

resetDefaultKernel() {
    oldDefaultKernel=$(awk '/^GRUB_DEFAULT=/{print; exit}' /etc/default/grub)

    if [ "$oldDefaultKernel" = 'GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"' ]; then
        updateGrubDefault "GRUB_DEFAULT=0"
    else
        printf "%b\n" "CachyOS is not the default kernel"
    fi
}

removeRepos() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        for repo in $activeRepos; do
            if ! grep -Fqx "[$repo]" /etc/pacman.conf; then
                printf '%s\n' "Remove the $repo repository manually. The CachyOS helper requires an exact header in /etc/pacman.conf." >&2
                return 1
            fi
        done
        printf "%b\n" "Removing CachyOS repo.."
        runRepoHelper --remove
        checkRepo
        if [ -n "$activeRepos" ]; then
            printf "%b\n" "CachyOS repos are still enabled in /etc/pacman.conf."
            return 1
        fi
    else
        printf "%b\n" "No CachyOS repos are enabled"
    fi
}

main() {
	printf "%b\n" "${YELLOW}Do you want to Install or Uninstall CachyOS${RC}"
    printf "%b\n" "1. ${YELLOW}Install CachyOS repos${RC}"
    printf "%b\n" "2. ${YELLOW}Set CachyOS-LTS default as kernel${RC}"
    printf "%b\n" "3. ${YELLOW}Install CachyOS repos and and set CachyOS-LTS as default kernel${RC}"
    printf "%b\n" "4. ${YELLOW}Remove CachyOS Repos and set default kernel to stock${RC}"
    printf "%b\n" "5. ${YELLOW}Reset default kernel to stock${RC}"
    printf "%b\n" "6. ${YELLOW}Remove CachyOS repos only${RC}"
    printf "%b" "Enter your choice [1-6]: "
    read -r CHOICE
    case "$CHOICE" in
        2|3|4|5) checkGrub ;;
    esac
    # None of these actions needs an AUR helper.
    AUR_HELPER_CHECKED=true checkEnv
    case "$CHOICE" in
        1) setupRepos ;;
        2) setDefaultKernel ;;
        3) setupRepos
           setDefaultKernel ;;
        4) removeRepos
           resetDefaultKernel;;
        5) resetDefaultKernel ;;
        6) removeRepos ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

main
