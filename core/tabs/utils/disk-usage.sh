#!/bin/sh -e

. ../common-script.sh

LINUTIL_UNINSTALL_SUPPORTED=1

install_dust() {
    if command_exists dust; then
        return 0
    fi

    if [ "$DTYPE" = "nixos" ] && command_exists nix; then
        nix profile install nixpkgs#dust
        command_exists dust && return 0
        return 1
    fi

    case "$PACKAGER" in
        apt-get|nala|dnf|zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install -y dust
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm dust
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add dust
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy dust
            ;;
        eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y dust
            ;;
        *)
            return 1
            ;;
    esac

    command_exists dust
}

setup_dust_launcher() {
    launcher_path="$HOME/.local/bin/linutil-disk-usage"
    desktop_path="$HOME/.local/share/applications/Disk Usage.desktop"
    icon_path="$HOME/.local/share/applications/icons/Disk Usage.png"

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"

    cat <<'EOF' >"$launcher_path"
#!/bin/sh
CMD="dust -r; read -n 1 -s"

detect_env() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    fi

    IS_HYPRLAND=0
    IS_WAYLAND=0
    IS_X11=0

    if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] || [ "${XDG_CURRENT_DESKTOP}" = "Hyprland" ] || [ "${XDG_SESSION_DESKTOP}" = "Hyprland" ]; then
        IS_HYPRLAND=1
    fi

    if [ "${XDG_SESSION_TYPE}" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
        IS_WAYLAND=1
    fi

    if [ "${XDG_SESSION_TYPE}" = "x11" ] || [ -n "$DISPLAY" ]; then
        IS_X11=1
    fi
}

try_xdg_terminal_exec() {
    if ! command -v xdg-terminal-exec >/dev/null 2>&1; then
        return 1
    fi

    if [ "$IS_HYPRLAND" -eq 1 ] || [ "$IS_WAYLAND" -eq 1 ]; then
        xdg-terminal-exec --app-id=TUI.float -e bash -c "$CMD" >/dev/null 2>&1 && return 0
    fi

    xdg-terminal-exec -e bash -c "$CMD" >/dev/null 2>&1
}

try_terminal_list() {
    for term in ghostty kitty alacritty gnome-terminal konsole x-terminal-emulator; do
        if command -v "$term" >/dev/null 2>&1; then
            case "$term" in
                gnome-terminal)
                    gnome-terminal -- bash -c "$CMD"
                    ;;
                konsole)
                    konsole -e bash -c "$CMD"
                    ;;
                *)
                    "$term" -e bash -c "$CMD"
                    ;;
            esac
            return 0
        fi
    done
    return 1
}

detect_env
try_xdg_terminal_exec && exit 0
try_terminal_list && exit 0

exec dust -r
EOF
    chmod +x "$launcher_path"

    if [ -f "$icon_path" ]; then
        icon_line="Icon=$icon_path"
    else
        icon_line=""
    fi

    {
        echo "[Desktop Entry]"
        echo "Version=1.0"
        echo "Name=Disk Usage"
        echo "Comment=Disk Usage"
        echo "Exec=$launcher_path"
        echo "Terminal=false"
        echo "Type=Application"
        [ -n "$icon_line" ] && echo "$icon_line"
        echo "StartupNotify=true"
    } > "$desktop_path"
}

remove_dust_launcher() {
    launcher_path="$HOME/.local/bin/linutil-disk-usage"
    desktop_path="$HOME/.local/share/applications/Disk Usage.desktop"

    rm -f "$launcher_path"
    if [ -f "$desktop_path" ] && grep -q "linutil-disk-usage" "$desktop_path"; then
        rm -f "$desktop_path"
    fi
}

installDiskUsage() {
    if install_dust; then
        setup_dust_launcher
        printf "%b\n" "${GREEN}Disk Usage launcher set to dust.${RC}"
        return 0
    else
        printf "%b\n" "${YELLOW}Dust is unavailable. Falling back to GNOME Disk Usage...${RC}"
    fi

    if ! flatpak_app_installed org.gnome.baobab && ! command_exists baobab; then
        printf "%b\n" "${YELLOW}Installing GNOME Disk Usage Analyzer...${RC}"
        if [ "$DTYPE" = "nixos" ] && command_exists nix; then
            nix profile install nixpkgs#baobab
            return 0
        fi
        case "$PACKAGER" in
            apt-get|nala|dnf|zypper)
                "$ESCALATION_TOOL" "$PACKAGER" install -y baobab
                ;;
            pacman)
                "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm baobab
                ;;
            apk)
                "$ESCALATION_TOOL" "$PACKAGER" add baobab
                ;;
            xbps-install)
                "$ESCALATION_TOOL" "$PACKAGER" -Sy baobab
                ;;
            eopkg)
                "$ESCALATION_TOOL" "$PACKAGER" install -y baobab
                ;;
            flatpak)
                printf "%b\n" "${YELLOW}Flatpak-only environment detected. Falling back to Flatpak...${RC}"
                ;;
            *)
                printf "%b\n" "${YELLOW}No native package configured for ${PACKAGER}. Falling back to Flatpak...${RC}"
                ;;
        esac
        if command_exists baobab; then
            return 0
        fi
        if try_flatpak_install org.gnome.baobab; then
            return 0
        fi
        printf "%b\n" "${RED}Failed to install GNOME Disk Usage Analyzer.${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}GNOME Disk Usage Analyzer is already installed.${RC}"
    fi
}

checkEnv
checkEscalationTool
if [ "$LINUTIL_ACTION" = "uninstall" ]; then
    remove_dust_launcher
    if command_exists dust; then
        uninstall_native dust || true
    else
        uninstall_flatpak_if_installed org.gnome.baobab || true
        uninstall_native baobab || true
    fi
else
    installDiskUsage
fi
