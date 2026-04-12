#!/bin/sh -e

. ../common-script.sh

install_theme_tools() {
    printf "%b\n" "${YELLOW}Installing Qt theming tools (qt5ct, qt6ct)...${RC}"
    case "$PACKAGER" in
        apt-get|nala)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qt5ct qt6ct || true
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" --non-interactive install qt5ct qt6ct || true
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y qt5ct qt6ct || true
            ;;
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --needed --noconfirm qt5ct qt6ct || true
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy qt5ct qt6ct || true
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: $PACKAGER${RC}"
            exit 1
            ;;
    esac
}

configure_gtk2() {
    printf "%b\n" "${YELLOW}Configuring GTK2 dark theme...${RC}"
    cat > "$HOME/.gtkrc-2.0" <<'EOF'
gtk-theme-name="Adwaita"
gtk-icon-theme-name="Adwaita"
gtk-font-name="Sans 10"
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintfull"
EOF
    printf "%b\n" "${GREEN}GTK2 configured.${RC}"
}

configure_gtk3() {
    printf "%b\n" "${YELLOW}Configuring GTK3 dark theme...${RC}"
    mkdir -p "$HOME/.config/gtk-3.0"
    cat > "$HOME/.config/gtk-3.0/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita
gtk-icon-theme-name=Adwaita
gtk-font-name=Sans 10
gtk-cursor-theme-size=0
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-application-prefer-dark-theme=1
EOF
    printf "%b\n" "${GREEN}GTK3 configured.${RC}"
}

configure_gtk4() {
    printf "%b\n" "${YELLOW}Configuring GTK4 dark theme...${RC}"
    mkdir -p "$HOME/.config/gtk-4.0"
    cat > "$HOME/.config/gtk-4.0/settings.ini" <<'EOF'
[Settings]
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Adwaita
EOF
    printf "%b\n" "${GREEN}GTK4 configured.${RC}"
}

configure_qt5ct() {
    printf "%b\n" "${YELLOW}Configuring qt5ct dark theme...${RC}"
    mkdir -p "$HOME/.config/qt5ct"
    cat > "$HOME/.config/qt5ct/qt5ct.conf" <<'EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Adwaita
standard_dialogs=default
style=Fusion

[Interface]
buttonbox_layout=0
menus_have_icons=true
toolbutton_style=4
EOF
    printf "%b\n" "${GREEN}qt5ct configured.${RC}"
}

configure_qt6ct() {
    printf "%b\n" "${YELLOW}Configuring qt6ct dark theme...${RC}"
    mkdir -p "$HOME/.config/qt6ct"
    cat > "$HOME/.config/qt6ct/qt6ct.conf" <<'EOF'
[Appearance]
color_scheme_path=
custom_palette=false
icon_theme=Adwaita
standard_dialogs=default
style=Fusion

[Interface]
buttonbox_layout=0
menus_have_icons=true
toolbutton_style=4
EOF
    printf "%b\n" "${GREEN}qt6ct configured.${RC}"
}

configure_xfce() {
    if command -v xfconf-query > /dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Configuring Xfce/Thunar dark theme via xfconf...${RC}"
        xfconf-query -c xsettings -p /Net/ThemeName       -s "Adwaita-dark" --create -t string 2>/dev/null || true
        xfconf-query -c xsettings -p /Net/IconThemeName   -s "Adwaita"      --create -t string 2>/dev/null || true
        xfconf-query -c xsettings -p /Gtk/ApplicationPreferDarkTheme -s true --create -t bool 2>/dev/null || true
        printf "%b\n" "${GREEN}Xfce/Thunar dark theme configured.${RC}"
    fi
}

set_environment_variables() {
    printf "%b\n" "${YELLOW}Setting theme environment variables...${RC}"
    add_env_var() {
        var_name="$1"
        var_value="$2"
        if ! grep -q "^${var_name}=" /etc/environment; then
            printf "%b\n" "Adding ${var_name}=${var_value} to /etc/environment"
            echo "${var_name}=${var_value}" | "$ESCALATION_TOOL" tee -a /etc/environment > /dev/null
        fi
    }
    add_env_var "QT_QPA_PLATFORMTHEME" "qt6ct"
    add_env_var "GTK_THEME" "Adwaita:dark"

    # Also export to profile files so it applies in the current WM session
    # without requiring a PAM re-login
    for profile in "$HOME/.xprofile" "$HOME/.profile"; do
        if [ -f "$profile" ] || [ "$profile" = "$HOME/.xprofile" ]; then
            if ! grep -q "GTK_THEME" "$profile" 2>/dev/null; then
                printf '%s\n' 'export GTK_THEME=Adwaita:dark' >> "$profile"
                printf "%b\n" "${GREEN}GTK_THEME exported to ${profile}.${RC}"
            fi
        fi
    done
    printf "%b\n" "${GREEN}Environment variables set.${RC}"
}

applyTheming() {
    printf "%b\n" "${YELLOW}Applying global dark theming...${RC}"
    case "$XDG_CURRENT_DESKTOP" in
        KDE)
            lookandfeeltool -a org.kde.breezedark.desktop
            successOutput
            exit 0
            ;;
        GNOME)
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita-dark"
            gsettings set org.gnome.desktop.interface icon-theme "Adwaita"
            gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
            ;;
    esac
}

apply_dconf_immediate() {
    if command -v dconf > /dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Applying dark theme immediately via dconf...${RC}"
        dconf write /org/gnome/desktop/interface/gtk-theme "'Adwaita-dark'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/icon-theme "'Adwaita'" 2>/dev/null || true
        dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'" 2>/dev/null || true
        printf "%b\n" "${GREEN}dconf settings applied.${RC}"
    fi
}

restart_thunar() {
    if command -v thunar > /dev/null 2>&1; then
        printf "%b\n" "${YELLOW}Restarting Thunar to apply new theme...${RC}"
        pkill -x thunar 2>/dev/null || true
        sleep 1
        printf "%b\n" "${GREEN}Thunar restarted. Re-open it to see the dark theme.${RC}"
    fi
}

successOutput() {
    printf "%b\n" "${GREEN}Global dark theming applied successfully.${RC}"
    printf "%b\n" "${YELLOW}NOTE: Qt app theming (qt5ct/qt6ct) requires a re-login to take effect.${RC}"
}

checkEnv
checkEscalationTool
applyTheming
install_theme_tools
configure_gtk2
configure_gtk3
configure_gtk4
configure_xfce
configure_qt5ct
configure_qt6ct
set_environment_variables
apply_dconf_immediate
restart_thunar
successOutput