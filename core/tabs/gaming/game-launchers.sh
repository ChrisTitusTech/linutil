#!/bin/sh -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)
# shellcheck source=core/tabs/common-script.sh
. "$SCRIPT_DIR/../common-script.sh"

set_launcher() {
    case "$1" in
        steam)
            LAUNCHER_NAME="Steam"
            PKG_NAME="steam"
            FLATPAK_ID="com.valvesoftware.Steam"
            NIX_CONFIG='programs.steam.enable = true;'
            ;;
        lutris)
            LAUNCHER_NAME="Lutris"
            PKG_NAME="lutris"
            FLATPAK_ID="net.lutris.Lutris"
            NIX_CONFIG='environment.systemPackages = with pkgs; [ lutris ];'
            ;;
        retroarch)
            LAUNCHER_NAME="RetroArch"
            PKG_NAME="retroarch"
            FLATPAK_ID="org.libretro.RetroArch"
            NIX_CONFIG='environment.systemPackages = with pkgs; [ retroarch ];'
            ;;
        heroic)
            LAUNCHER_NAME="Heroic"
            PKG_NAME="heroic-games-launcher-bin"
            FLATPAK_ID="com.heroicgameslauncher.hgl"
            NIX_CONFIG='environment.systemPackages = with pkgs; [ heroic ];'
            ;;
        *)
            printf "%b\n" "${RED}Unsupported launcher preset: $1${RC}"
            exit 1
            ;;
    esac
}

print_nixos_guidance() {
    printf "%b\n" "${YELLOW}NixOS is declarative. Linutil will not install or uninstall ${LAUNCHER_NAME} imperatively.${RC}"
    printf "%b\n" "${CYAN}Add this to /etc/nixos/configuration.nix:${RC}"
    printf "%s\n" "$NIX_CONFIG"
    printf "%b\n" "${CYAN}Then apply it with:${RC} sudo nixos-rebuild switch"
    printf "%b\n" "${CYAN}To uninstall, remove that option/package from configuration.nix and rebuild.${RC}"
}

is_flatpak_installed() {
    command_exists flatpak && flatpak list --app --columns=application 2>/dev/null | grep -qx "$1"
}

install_flatpak_app() {
    checkFlatpak
    "$ESCALATION_TOOL" flatpak install --noninteractive flathub "$FLATPAK_ID"
}

uninstall_flatpak_app() {
    if is_flatpak_installed "$FLATPAK_ID"; then
        "$ESCALATION_TOOL" flatpak uninstall --noninteractive "$FLATPAK_ID"
        return 0
    fi
    return 1
}

is_native_pkg_installed() {
    pkg="$1"
    case "$PACKAGER" in
        pacman) "$PACKAGER" -Qq "$pkg" >/dev/null 2>&1 ;;
        apt-get | nala) dpkg -s "$pkg" >/dev/null 2>&1 ;;
        dnf | zypper) rpm -q "$pkg" >/dev/null 2>&1 ;;
        eopkg) "$PACKAGER" info "$pkg" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

get_pacman_pkg_name() {
    pkg="$1"
    "$PACKAGER" -Qq "$pkg" 2>/dev/null | sed -n '1p'
}

install_native_pkg() {
    case "$PACKAGER" in
        pacman) "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm "$@" ;;
        apt-get | nala) "$ESCALATION_TOOL" "$PACKAGER" install -y "$@" ;;
        dnf) "$ESCALATION_TOOL" "$PACKAGER" install -y "$@" ;;
        zypper) "$ESCALATION_TOOL" "$PACKAGER" -n install "$@" ;;
        eopkg) "$ESCALATION_TOOL" "$PACKAGER" install -y "$@" ;;
        *) return 1 ;;
    esac
}

install_aur_pkg_direct() {
    pkg="$1"

    if ! command_exists git makepkg; then
        install_native_pkg base-devel git
    fi

    temp_dir=$(mktemp -d)
    if git clone "https://aur.archlinux.org/${pkg}.git" "$temp_dir/$pkg"; then
        if (cd "$temp_dir/$pkg" && makepkg --noconfirm -si); then
            rm -rf "$temp_dir"
            return 0
        fi
    fi

    rm -rf "$temp_dir"
    return 1
}

uninstall_native_pkg() {
    case "$PACKAGER" in
        pacman) "$ESCALATION_TOOL" "$PACKAGER" -Rns --noconfirm "$@" ;;
        apt-get | nala) "$ESCALATION_TOOL" "$PACKAGER" remove -y "$@" ;;
        dnf) "$ESCALATION_TOOL" "$PACKAGER" remove -y "$@" ;;
        zypper) "$ESCALATION_TOOL" "$PACKAGER" -n remove "$@" ;;
        eopkg) "$ESCALATION_TOOL" "$PACKAGER" remove -y "$@" ;;
        *) return 1 ;;
    esac
}

install_arch_launcher() {
    case "$LAUNCHER_NAME" in
        Heroic)
            install_aur_pkg_direct "$PKG_NAME"
            ;;
        RetroArch)
            install_native_pkg retroarch retroarch-assets-xmb retroarch-assets-ozone retroarch-assets-glui libretro-core-info
            ;;
        *)
            install_native_pkg "$PKG_NAME"
            ;;
    esac
}

install_launcher() {
    if [ "$DTYPE" = "nixos" ]; then
        print_nixos_guidance
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing ${LAUNCHER_NAME}...${RC}"
    case "$PACKAGER" in
        pacman)
            install_arch_launcher
            ;;
        apt-get | nala | dnf | zypper | eopkg)
            if [ "$LAUNCHER_NAME" = "Steam" ] || [ "$LAUNCHER_NAME" = "Heroic" ]; then
                install_flatpak_app
            elif [ "$PACKAGER" = "eopkg" ] && [ "$LAUNCHER_NAME" = "RetroArch" ]; then
                install_flatpak_app
            else
                install_native_pkg "$PKG_NAME"
            fi
            ;;
        *)
            install_flatpak_app
            ;;
    esac
    printf "%b\n" "${GREEN}${LAUNCHER_NAME} installation completed.${RC}"
}

uninstall_arch_launcher() {
    installed_pkgs=""

    case "$LAUNCHER_NAME" in
        Heroic)
            for pkg in heroic-games-launcher heroic-games-launcher-bin; do
                installed_pkg=$(get_pacman_pkg_name "$pkg")
                if [ -n "$installed_pkg" ] && ! printf '%s\n' "$installed_pkgs" | grep -qx "$installed_pkg"; then
                    installed_pkgs="${installed_pkgs}${installed_pkgs:+
}$installed_pkg"
                fi
            done
            ;;
        RetroArch)
            for pkg in retroarch retroarch-assets-xmb retroarch-assets-ozone retroarch-assets-glui libretro-core-info; do
                installed_pkg=$(get_pacman_pkg_name "$pkg")
                if [ -n "$installed_pkg" ] && ! printf '%s\n' "$installed_pkgs" | grep -qx "$installed_pkg"; then
                    installed_pkgs="${installed_pkgs}${installed_pkgs:+
}$installed_pkg"
                fi
            done
            ;;
        *)
            installed_pkg=$(get_pacman_pkg_name "$PKG_NAME")
            if [ -n "$installed_pkg" ]; then
                installed_pkgs="$installed_pkg"
            fi
            ;;
    esac

    if [ -n "$installed_pkgs" ]; then
        # Remove related pacman packages in one transaction to satisfy dependencies.
        # shellcheck disable=SC2086
        uninstall_native_pkg $installed_pkgs
        return 0
    fi

    if uninstall_flatpak_app; then
        return 0
    fi

    return 1
}

uninstall_pkg_if_installed() {
    pkg="$1"
    if is_native_pkg_installed "$pkg"; then
        uninstall_native_pkg "$pkg"
        return 0
    fi
    return 1
}

uninstall_launcher() {
    if [ "$DTYPE" = "nixos" ]; then
        print_nixos_guidance
        return 0
    fi

    printf "%b\n" "${YELLOW}Uninstalling ${LAUNCHER_NAME}...${RC}"
    removed_any=false

    case "$PACKAGER" in
        pacman)
            if uninstall_arch_launcher; then
                removed_any=true
            fi
            ;;
        apt-get | nala | dnf | zypper | eopkg)
            if uninstall_pkg_if_installed "$PKG_NAME"; then
                removed_any=true
            fi
            if uninstall_flatpak_app; then
                removed_any=true
            fi
            ;;
        *)
            if uninstall_flatpak_app; then
                removed_any=true
            fi
            ;;
    esac

    if [ "$removed_any" = true ]; then
        printf "%b\n" "${GREEN}${LAUNCHER_NAME} uninstall completed.${RC}"
    else
        printf "%b\n" "${CYAN}${LAUNCHER_NAME} is not installed.${RC}"
    fi
}

main() {
    preset="${1:-${LAUNCHER_PRESET:-}}"
    if [ -z "$preset" ]; then
        printf "%b\n" "${RED}No launcher specified. Please run this script through Gaming > Game Launchers.${RC}"
        exit 1
    fi
    set_launcher "$preset"
    printf "%b\n" "${YELLOW}Choose action for ${LAUNCHER_NAME}:${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b\n" "3. ${YELLOW}Abort${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r action_choice

    case "$action_choice" in
        1) install_launcher ;;
        2) uninstall_launcher ;;
        3) printf "%b\n" "${CYAN}Aborted.${RC}" ; exit 0 ;;
        *) printf "%b\n" "${RED}Invalid action choice.${RC}" ; exit 1 ;;
    esac
}

checkDistro
if [ "$DTYPE" = "nixos" ]; then
    checkArch
else
    checkEnv
fi
main "$@"
