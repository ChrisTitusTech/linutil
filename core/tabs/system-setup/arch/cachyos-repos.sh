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
    if [ -L /etc/default/grub ] || [ -L /boot/grub/grub.cfg ]; then
        printf '%s\n' "GRUB settings or config are managed through a symlink. Change the kernel default manually." >&2
        return 1
    fi
    if ! grep -q '^GRUB_DEFAULT=' /etc/default/grub; then
        printf "%b\n" "${RED}No GRUB_DEFAULT setting found in /etc/default/grub.${RC}"
        return 1
    fi
    printf '%s\n' "Continue only if this machine boots from /boot/grub/grub.cfg. Choose option 6 for removal without changing GRUB."
    printf '%s' "Does this machine boot from that GRUB config? [y/N] "
    read -r grubConfirmed
    case "$grubConfirmed" in
        y|Y) ;;
        *) return 1 ;;
    esac
}

runRepoHelper() (
    workdir=$(mktemp -d)
    trap '"$ESCALATION_TOOL" rm -rf -- "$workdir"' 0
    cd "$workdir"
    curl -f https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
    tar xvf cachyos-repo.tar.xz
    cd cachyos-repo
    if [ "${2:-}" = --reset-kernel ]; then
        updateGrubDefault linux
    fi
    "$ESCALATION_TOOL" ./cachyos-repo.sh "${1:---install}"
)

setupRepos() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        printf "%b\n" "CachyOS repos already configured"
    elif grep -Eq '^[[:space:]]*#[[:space:]]*\[cachyos(-[[:alnum:]-]+)?\][[:space:]]*(#.*)?$' /etc/pacman.conf; then
        printf "%b\n" "Enable the commented CachyOS repos in /etc/pacman.conf before continuing."
        return 1
    else
        if ! LC_ALL=C /lib/ld-linux-x86-64.so.2 --help 2>/dev/null |
            grep -Fq 'x86-64-v3 (supported, searched)'; then
            printf '%s\n' "Installing CachyOS repos requires an x86-64-v3 compatible CPU and glibc loader." >&2
            return 1
        fi
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
        /^}/ { submenu = "" }
        /^[[:space:]]*}/ { path = ""; image = "" }
        /\$menuentry_id_option / {
            split(substr($0, index($0, "$menuentry_id_option ") + length("$menuentry_id_option ")), fields, FS)
            id = fields[2]
            if (id !~ /^[[:alnum:]_-]+$/) next
            if ($1 ~ /^submenu[[:space:]]/) submenu = id
            if ($1 ~ /^[[:space:]]*menuentry[[:space:]]/) {
                path = ($1 ~ /^[[:space:]]/ && submenu != "" ? submenu ">" : "") id
                if (id ~ /-recovery-/ || id ~ /^gnulinux-simple-/) path = ""
            }
        }
        path != "" && $1 ~ /^[[:space:]]+linux(efi)?[[:space:]]/ {
            split($1, args, /[[:space:]]+/)
            image = (args[3] == "" ? $2 : args[3])
            sub(/^.*[/]/, "", image)
            sub(/^vmlinuz-/, "", image)
        }
        path != "" && image != "" && $1 ~ /^[[:space:]]+initrd(efi)?[[:space:]]/ {
            for (i = 1; i <= NF; i++) {
                count = split($i, args, /[[:space:]]+/)
                for (j = 1; j <= count; j++) {
                    sub(/^.*[/]/, "", args[j])
                    if (args[j] != "initramfs-" image ".img" &&
                        args[j] != "initramfs-" image "-fallback.img" &&
                        args[j] != "booster-" image ".img") continue
                    if (image == kernel) {
                        print path
                        found = 1
                        exit
                    }
                    if (kernel == "linux" && image == "linux-lts" &&
                        (fallback == "" || args[j] == "initramfs-linux-lts.img")) fallback = path
                }
            }
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
    if ! entry=$(findGrubEntry "$1" "$candidate"); then
        printf '%s\n' "Could not find a GRUB entry for $1." >&2
        return 1
    fi
    backup=$("$ESCALATION_TOOL" mktemp /etc/default/grub.linutil.XXXXXX)
    "$ESCALATION_TOOL" cp -p /etc/default/grub "$backup"
    restore=true
    "$ESCALATION_TOOL" sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"$entry\"/" /etc/default/grub
    "$ESCALATION_TOOL" grub-mkconfig -o "$candidate"
    # The standard header may honor a one-time boot entry from grubenv.
    # Reject any other assignment that could override the requested default.
    # shellcheck disable=SC2016
    if ! "$ESCALATION_TOOL" awk -v entry="$entry" '
        /^### BEGIN .*[/]00_header ###$/ { header = 1 }
        /^### END .*[/]00_header ###$/ { header = 0 }
        /^[[:space:]]*set[[:space:]]+default[[:space:]]*=/ {
            sub(/^[[:space:]]*set[[:space:]]+default[[:space:]]*=[[:space:]]*/, "")
            sub(/[[:space:]]*$/, "")
            if (header && $0 == "\"${next_entry}\"") next
            if ($0 != "\"" entry "\"") wrong = 1
            else found = 1
        }
        END { exit (wrong || !found) }
    ' "$candidate" || [ "$(findGrubEntry "$1" "$candidate")" != "$entry" ]; then
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

removeRepos() {
    checkRepo
    if [ -n "$activeRepos" ]; then
        if ! printf '%s\n' "$repoList" | grep -Fxq core; then
            printf '%s\n' "Enable the stock [core] repository before migrating CachyOS packages." >&2
            return 1
        fi
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
                    if (++sections > 1 || getline != 1 ||
                        $0 !~ /^Include = \/etc\/pacman[.]d\/cachyos(-[[:alnum:]-]+)?-mirrorlist$/) {
                        invalid = 1
                        exit
                    }
                    inside = 1
                    next
                }
                /^[[:space:]]*\[/ { inside = 0 }
                inside && $0 !~ /^[[:space:]]*(#.*)?$/ {
                    invalid = 1
                    exit
                }
                END { exit (sections != 1 || invalid) }
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
        runRepoHelper --remove "$@"
        checkRepo
        if [ -n "$activeRepos" ]; then
            printf "%b\n" "CachyOS repos are still enabled in /etc/pacman.conf."
            return 1
        fi
    else
        if "$PACKAGER" -Q cachyos-keyring >/dev/null 2>&1; then
            printf '%s\n' "CachyOS repos are disabled but the CachyOS keyring is still installed. Check whether package migration needs recovery." >&2
            return 1
        fi
        printf "%b\n" "No CachyOS repos are enabled"
        if [ "$#" -gt 0 ]; then
            updateGrubDefault linux
        fi
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
        4) removeRepos --reset-kernel ;;
        5) updateGrubDefault linux ;;
        6) removeRepos ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

main
