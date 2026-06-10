#!/bin/sh -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)
# shellcheck source=core/tabs/common-script.sh
. "$SCRIPT_DIR/../common-script.sh"

set_tool() {
    case "$1" in
        protonplus)
            TOOL_NAME="ProtonPlus"
            NATIVE_PKG_NAMES="protonplus protonplus-bin"
            FLATPAK_ID="com.vysp3r.ProtonPlus"
            ;;
        protonup-qt)
            TOOL_NAME="ProtonUp-Qt"
            NATIVE_PKG_NAMES="protonup-qt"
            FLATPAK_ID="net.davidotek.pupgui2"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported Proton tool preset: $1${RC}"
            exit 1
            ;;
    esac
}

is_flatpak_installed() {
    command_exists flatpak && flatpak list --app --columns=application 2>/dev/null | grep -qx "$FLATPAK_ID"
}

is_native_pkg_installed() {
    pkg="$1"
    case "$PACKAGER" in
        pacman) "$PACKAGER" -Qq "$pkg" >/dev/null 2>&1 ;;
        apt-get | nala) dpkg -s "$pkg" >/dev/null 2>&1 ;;
        dnf | zypper) rpm -q "$pkg" >/dev/null 2>&1 ;;
        apk) "$PACKAGER" info -e "$pkg" >/dev/null 2>&1 ;;
        xbps-install) xbps-query "$pkg" >/dev/null 2>&1 ;;
        eopkg) "$PACKAGER" info "$pkg" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

install_native_pkg() {
    pkg="$1"
    case "$PACKAGER" in
        pacman) "$AUR_HELPER" -S --needed --noconfirm "$pkg" ;;
        apt-get | nala) "$ESCALATION_TOOL" "$PACKAGER" install -y "$pkg" ;;
        dnf) "$ESCALATION_TOOL" "$PACKAGER" install -y "$pkg" ;;
        zypper) "$ESCALATION_TOOL" "$PACKAGER" -n install "$pkg" ;;
        apk) "$ESCALATION_TOOL" "$PACKAGER" add "$pkg" ;;
        xbps-install) "$ESCALATION_TOOL" "$PACKAGER" -Sy "$pkg" ;;
        eopkg) "$ESCALATION_TOOL" "$PACKAGER" install -y "$pkg" ;;
        *) return 1 ;;
    esac
}

install_native_tool() {
    for pkg in $NATIVE_PKG_NAMES; do
        if is_native_pkg_installed "$pkg"; then
            printf "%b\n" "${GREEN}${TOOL_NAME} is already installed as ${pkg}.${RC}"
            return 0
        fi

        printf "%b\n" "${YELLOW}Trying native package ${pkg} for ${TOOL_NAME}...${RC}"
        if install_native_pkg "$pkg"; then
            return 0
        fi
    done

    return 1
}

uninstall_native_pkg() {
    pkg="$1"
    case "$PACKAGER" in
        pacman) "$ESCALATION_TOOL" "$PACKAGER" -Rns --noconfirm "$pkg" ;;
        apt-get | nala) "$ESCALATION_TOOL" "$PACKAGER" remove -y "$pkg" ;;
        dnf) "$ESCALATION_TOOL" "$PACKAGER" remove -y "$pkg" ;;
        zypper) "$ESCALATION_TOOL" "$PACKAGER" -n remove "$pkg" ;;
        apk) "$ESCALATION_TOOL" "$PACKAGER" del "$pkg" ;;
        xbps-install) "$ESCALATION_TOOL" xbps-remove -R "$pkg" ;;
        eopkg) "$ESCALATION_TOOL" "$PACKAGER" remove -y "$pkg" ;;
        *) return 1 ;;
    esac
}

uninstall_native_tool() {
    removed_any=false

    for pkg in $NATIVE_PKG_NAMES; do
        if is_native_pkg_installed "$pkg"; then
            uninstall_native_pkg "$pkg"
            removed_any=true
        fi
    done

    [ "$removed_any" = true ]
}

install_tool() {
    if is_flatpak_installed; then
        printf "%b\n" "${GREEN}${TOOL_NAME} is already installed.${RC}"
        return 0
    fi

    if install_native_tool; then
        printf "%b\n" "${GREEN}${TOOL_NAME} installation completed.${RC}"
        return 0
    fi

    checkFlatpak
    printf "%b\n" "${YELLOW}Native package unavailable. Installing ${TOOL_NAME} with Flatpak...${RC}"
    "$ESCALATION_TOOL" flatpak install --noninteractive flathub "$FLATPAK_ID"
    printf "%b\n" "${GREEN}${TOOL_NAME} installation completed.${RC}"
}

uninstall_tool() {
    removed_any=false

    if uninstall_native_tool; then
        removed_any=true
    fi

    if is_flatpak_installed; then
        printf "%b\n" "${YELLOW}Uninstalling ${TOOL_NAME} with Flatpak...${RC}"
        "$ESCALATION_TOOL" flatpak uninstall --noninteractive "$FLATPAK_ID"
        removed_any=true
    fi

    if [ "$removed_any" = false ]; then
        printf "%b\n" "${CYAN}${TOOL_NAME} is not installed.${RC}"
        return 0
    fi

    printf "%b\n" "${GREEN}${TOOL_NAME} uninstall completed.${RC}"
}

main() {
    preset="${1:-${PROTON_TOOL_PRESET:-}}"
    if [ -z "$preset" ]; then
        printf "%b\n" "${RED}No Proton tool specified. Please run this script through Gaming > Tools and Setups.${RC}"
        exit 1
    fi

    set_tool "$preset"
    printf "%b\n" "${YELLOW}Choose action for ${TOOL_NAME}:${RC}"
    printf "%b\n" "1. ${YELLOW}Install${RC}"
    printf "%b\n" "2. ${YELLOW}Uninstall${RC}"
    printf "%b\n" "3. ${YELLOW}Abort${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r action_choice

    case "$action_choice" in
        1) install_tool ;;
        2) uninstall_tool ;;
        3) printf "%b\n" "${CYAN}Aborted.${RC}" ; exit 0 ;;
        *) printf "%b\n" "${RED}Invalid action choice.${RC}" ; exit 1 ;;
    esac
}

checkDistro
checkEnv
main "$@"
