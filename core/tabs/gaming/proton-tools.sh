#!/bin/sh -e

SCRIPT_DIR=$(dirname -- "$0")
SCRIPT_DIR=$(cd -- "$SCRIPT_DIR" && pwd)
# shellcheck source=core/tabs/common-script.sh
. "$SCRIPT_DIR/../common-script.sh"

set_tool() {
    case "$1" in
        protonplus)
            TOOL_NAME="ProtonPlus"
            FLATPAK_ID="com.vysp3r.ProtonPlus"
            ;;
        protonup-qt)
            TOOL_NAME="ProtonUp-Qt"
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

install_tool() {
    if is_flatpak_installed; then
        printf "%b\n" "${GREEN}${TOOL_NAME} is already installed.${RC}"
        return 0
    fi

    checkFlatpak
    printf "%b\n" "${YELLOW}Installing ${TOOL_NAME} with Flatpak...${RC}"
    "$ESCALATION_TOOL" flatpak install --noninteractive flathub "$FLATPAK_ID"
    printf "%b\n" "${GREEN}${TOOL_NAME} installation completed.${RC}"
}

uninstall_tool() {
    if ! is_flatpak_installed; then
        printf "%b\n" "${CYAN}${TOOL_NAME} is not installed via Flatpak.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Uninstalling ${TOOL_NAME} with Flatpak...${RC}"
    "$ESCALATION_TOOL" flatpak uninstall --noninteractive "$FLATPAK_ID"
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
