#!/bin/sh -e

. ../common-script.sh

setupKitty() {
    echo "Install Kitty if not already installed..."
    if ! command_exists kitty; then
        case ${PACKAGER} in
            pacman)
                $ESCALATION_TOOL "${PACKAGER}" -S --needed --noconfirm kitty
                ;;
            *)
                $ESCALATION_TOOL "${PACKAGER}" install -y kitty
                ;;
        esac
    else
        echo "Kitty is already installed."
    fi
    echo "Copy Kitty config files"
    if [ -d "${HOME}/.config/kitty" ]; then
        cp -r "${HOME}/.config/kitty" "${HOME}/.config/kitty-bak"
    fi
    mkdir -p "${HOME}/.config/kitty/"
    wget -O "${HOME}/.config/kitty/kitty.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/kitty.conf
    wget -O "${HOME}/.config/kitty/nord.conf" https://github.com/ChrisTitusTech/dwm-titus/raw/main/config/kitty/nord.conf
}

revertKitty() {
    echo "Reverting Kitty configuration..."
    CONFIG_DIR="${HOME}/.config/kitty"

    if [ -d "${CONFIG_DIR}" ]; then
        rm -rf "${CONFIG_DIR}"
        echo "Kitty configuration reverted."

        if command_exists kitty; then
            printf "Do you want to uninstall Kitty as well? (y/N): "
            read uninstall_choice
            if [ "$uninstall_choice" = "y" ] || [ "$uninstall_choice" = "Y" ]; then
                case ${PACKAGER} in
                    pacman)
                        $ESCALATION_TOOL "${PACKAGER}" -R --noconfirm kitty
                        ;;
                    *)
                        $ESCALATION_TOOL "${PACKAGER}" remove -y kitty
                        ;;
                esac
                echo "Kitty uninstalled."
            fi
        fi
    else
        echo "No Kitty configuration found. Nothing to revert."
    fi
}

run() {
    checkEnv
    checkEscalationTool
    setupKitty
}

revert() {
    checkEnv
    checkEscalationTool
    revertKitty
}
