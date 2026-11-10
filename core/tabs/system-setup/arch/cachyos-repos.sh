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

findGrubEntry() {
    # GRUB's 10_linux assigns stable IDs to its advanced kernel entries.
    # shellcheck disable=SC2016
    "$ESCALATION_TOOL" awk -F "'" -v kernel="$1" '
        /^### BEGIN .*[/]10_linux ###$/ { linux = 1 }
        /^### END .*[/]10_linux ###$/ { linux = 0 }
        !linux { next }
        /^}/ { submenu = ""; path = "" }
        /^[[:space:]]*}/ { path = "" }
        /\$menuentry_id_option / {
            id = $4
            if (id !~ /^[[:alnum:]_-]+$/) next
            if ($1 ~ /^submenu[[:space:]]/) submenu = id
            if ($1 ~ /^[[:space:]]*menuentry[[:space:]]/) {
                path = ($1 ~ /^[[:space:]]/ && submenu != "" ? submenu ">" : "") id
                if (id ~ /-recovery-/) path = ""
            }
        }
        path != "" && $1 ~ /^[[:space:]]+linux(efi)?[[:space:]]/ {
            split($0, args, /[[:space:]]+/)
            image = args[3]
            sub(/^.*[/]/, "", image)
            if (image == "vmlinuz-" kernel) {
                if (id !~ /^gnulinux-simple-/) {
                    print path
                    found = 1
                    exit
                }
                fallback = path
            }
            if (kernel == "linux" && image == "vmlinuz-linux-lts" && fallback == "")
                fallback = path
        }
        END {
            if (found) exit 0
            if (fallback == "") exit 1
            print fallback
        }
    ' "$2"
}

cleanupGrubUpdate() {
    if [ "$restore" = true ] && ! "$ESCALATION_TOOL" mv -f -- "$backup" /etc/default/grub; then
        printf '%s\n' "Could not restore GRUB settings. Backup kept at $backup." >&2
        backup=
    fi
    "$ESCALATION_TOOL" rm -f -- ${backup:+"$backup"} ${candidate:+"$candidate" "$candidate.new"}
}

updateGrubDefault() (
    backup=
    candidate=
    restore=false
    trap cleanupGrubUpdate 0
    trap 'exit 129' HUP
    trap 'exit 130' INT
    trap 'exit 143' TERM
    candidate=$("$ESCALATION_TOOL" mktemp /boot/grub/grub.cfg.linutil.XXXXXX)
    "$ESCALATION_TOOL" grub-mkconfig -o "$candidate"
    if [ "$#" -eq 2 ]; then
        cachyosEntry=$(findGrubEntry linux-cachyos-lts "$candidate" || :)
        if [ "$2" != "GRUB_DEFAULT=\"$cachyosEntry\"" ] || [ -z "$cachyosEntry" ]; then
            printf '%s\n' "CachyOS is not the default kernel"
            return 0
        fi
    fi
    if ! entry=$(findGrubEntry "$1" "$candidate"); then
        printf '%s\n' "Could not find a GRUB entry for $1." >&2
        return 1
    fi
    backup=$("$ESCALATION_TOOL" mktemp /etc/default/grub.linutil.XXXXXX)
    "$ESCALATION_TOOL" cp -p /etc/default/grub "$backup"
    restore=true
    "$ESCALATION_TOOL" sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$entry\"/" /etc/default/grub
    "$ESCALATION_TOOL" grub-mkconfig -o "$candidate"
    if ! "$ESCALATION_TOOL" grep -Eq "^[[:space:]]*set default=\"$entry\"[[:space:]]*$" "$candidate" ||
        [ "$(findGrubEntry "$1" "$candidate")" != "$entry" ]; then
        printf '%s\n' "Could not verify the requested GRUB default." >&2
        return 1
    fi
    # Finish installing the config before handling any further signals.
    trap '' HUP INT TERM
    "$ESCALATION_TOOL" mv -f -- "$candidate" /boot/grub/grub.cfg
    restore=false
)

setDefaultKernel() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm linux-cachyos-lts linux-cachyos-lts-headers linux-cachyos linux-cachyos-headers

        updateGrubDefault linux-cachyos-lts
    else
        printf "%b\n" "CachyOS repos are not enabled. Install or enable them in /etc/pacman.conf before installing the kernel."
        return 1
    fi
}

resetDefaultKernel() {
    oldDefaultKernel=$(awk '/^GRUB_DEFAULT=/{print; exit}' /etc/default/grub)

    case "$oldDefaultKernel" in
        'GRUB_DEFAULT="Advanced options for Arch Linux>Arch Linux, with Linux linux-cachyos-lts"' )
            updateGrubDefault linux ;;
        'GRUB_DEFAULT="gnulinux-'*'"')
            updateGrubDefault linux "$oldDefaultKernel" ;;
        *) printf '%s\n' "CachyOS is not the default kernel" ;;
    esac
}

removeRepos() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        for repo in $activeRepos; do
            case "$repo" in
                cachyos|cachyos-v3|cachyos-core-v3|cachyos-extra-v3|cachyos-testing-v3|\
                cachyos-v4|cachyos-core-v4|cachyos-extra-v4|cachyos-znver4|cachyos-core-znver4|cachyos-extra-znver4)
                    ;;
                *)
                    printf '%s\n' "Remove the unsupported $repo repository manually." >&2
                    return 1 ;;
            esac
            if ! awk -v header="[$repo]" '
                $0 == header {
                    if (getline != 1 || $0 !~ /^Include = \/etc\/pacman[.]d\/cachyos(-[[:alnum:]-]+)?-mirrorlist$/) exit
                    while (getline == 1) {
                        if ($0 ~ /^[[:space:]]*\[/) break
                        if ($0 !~ /^[[:space:]]*(#.*)?$/) exit
                    }
                    safe = 1
                    exit
                }
                END { exit !safe }
            ' /etc/pacman.conf; then
                printf '%s\n' "Remove the $repo repository manually. The CachyOS helper requires a standard repository block in /etc/pacman.conf." >&2
                return 1
            fi
        done
        printf '%s\n' "Removal can downgrade system packages, replace pacman, and remove the CachyOS keyring and mirrorlists."
        printf '%s' "Continue with CachyOS removal? [y/N] "
        read -r confirm
        case "$confirm" in
            y|Y) ;;
            *) return 1 ;;
        esac
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
    printf "%b\n" "6. ${YELLOW}Remove CachyOS repos and migrate packages without changing GRUB${RC}"
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
