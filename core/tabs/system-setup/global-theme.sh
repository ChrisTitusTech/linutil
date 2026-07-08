#!/bin/sh -e

. ../common-script.sh

# --- Dark theme functions ---

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
            return
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

applyDarkTheme() {
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
}

# --- Reset theme functions ---

detectGNOMEVersion() {
    GNOME_VER=0
    if command_exists gnome-shell; then
        GNOME_VER=$(gnome-shell --version 2>/dev/null | sed 's/[^0-9]*\([0-9]*\)\.\([0-9]*\).*/\1\2/')
    fi
}

detectPlasmaVersion() {
    PLASMA_VER=5
    if command_exists plasmashell; then
        if plasmashell --version 2>/dev/null | grep -q "6\."; then
            PLASMA_VER=6
        fi
    fi
}

detectDE() {
    DE="${XDG_CURRENT_DESKTOP:-${XDG_SESSION_DESKTOP:-}}"
    case "$DE" in
        *GNOME*|*gnome*|*Ubuntu*|*ubuntu*) DE=gnome ;;
        *KDE*|*kde*|*Plasma*|*plasma*) DE=kde ;;
        *XFCE*|*xfce*|*Xfce*) DE=xfce ;;
        *Cinnamon*|*cinnamon*) DE=cinnamon ;;
        *MATE*|*mate*) DE=mate ;;
        *Budgie*|*budgie*) DE=budgie ;;
        *LXDE*|*lxde*) DE=lxde ;;
        *LXQt*|*lxqt*) DE=lxqt ;;
        *Deepin*|*deepin*) DE=deepin ;;
        *Pantheon*|*pantheon*) DE=pantheon ;;
        *Sway*|*sway*) DE=sway ;;
        *Hyprland*|*hyprland*) DE=hyprland ;;
        *i3*|*i3wm*) DE=i3 ;;
        *Enlightenment*|*enlightenment*) DE=enlightenment ;;
        *Openbox*|*openbox*) DE=openbox ;;
        *bspwm*) DE=bspwm ;;
        *dwm*) DE=dwm ;;
        *qtile*) DE=qtile ;;
        *ukui*) DE=ukui ;;
        *Lomiri*|*lomiri*) DE=lomiri ;;
        *COSMIC*|*cosmic*) DE=cosmic ;;
        *) DE=unknown ;;
    esac
    printf "%b\n" "${CYAN}DE: ${DE}  |  Distro: ${DTYPE} ${DVER}  |  GNOME: ${GNOME_VER}  |  Plasma: ${PLASMA_VER}${RC}"
}

resetGNOME() {
    if ! command_exists gsettings; then return; fi

    GTK_THEME=Adwaita
    ICON_THEME=Adwaita
    CURSOR_THEME=Adwaita
    FONT_NAME="Cantarell 11"
    BG_LIGHT=""
    BG_DARK=""

    case "$DTYPE" in
        ubuntu|ubuntu-core)
            if [ "$DVER_MAJOR" -ge 24 ]; then
                GTK_THEME=Yaru; ICON_THEME=Yaru; CURSOR_THEME=Yaru
                FONT_NAME="Ubuntu 11"
                BG_LIGHT="file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png"
                BG_DARK="$BG_LIGHT"
            elif [ "$DVER_MAJOR" -ge 20 ]; then
                GTK_THEME=Yaru; ICON_THEME=Yaru; CURSOR_THEME=Yaru
                FONT_NAME="Ubuntu 11"
                BG_LIGHT="file:///usr/share/backgrounds/ubuntu-default-greyscale-wallpaper.png"
            elif [ "$DVER_MAJOR" -ge 18 ]; then
                GTK_THEME=Yaru; ICON_THEME=Yaru; CURSOR_THEME=Yaru
                FONT_NAME="Ubuntu 11"
            else
                GTK_THEME=Ambiance; ICON_THEME=ubuntu-mono-dark
                FONT_NAME="Ubuntu 11"
            fi
            ;;
        pop|popos)
            GTK_THEME=Pop; ICON_THEME=Pop; CURSOR_THEME=Pop
            FONT_NAME="Fira Sans 10"
            BG_LIGHT="file:///usr/share/backgrounds/pop/default.png"
            ;;
        zorin)
            GTK_THEME=ZorinBlue-Dark; ICON_THEME=Zorin; CURSOR_THEME=Zorin
            FONT_NAME="Inter 11"
            BG_LIGHT="file:///usr/share/backgrounds/zorin-default.jpg"
            ;;
        fedora|rhel|centos|rocky|alma|nobara)
            GTK_THEME=Adwaita; ICON_THEME=Adwaita; CURSOR_THEME=Adwaita
            FONT_NAME="Cantarell 11"
            BG_LIGHT="file:///usr/share/backgrounds/default.png"
            BG_DARK="$BG_LIGHT"
            ;;
        debian)
            FONT_NAME="Cantarell 11"
            ;;
    esac

    gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "$CURSOR_THEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "$FONT_NAME" 2>/dev/null || true

    if [ "$GNOME_VER" -ge 42 ] || [ "$GNOME_VER" = "0" ]; then
        gsettings set org.gnome.desktop.interface color-scheme "default" 2>/dev/null || true
    fi
    if [ -n "$BG_LIGHT" ]; then
        gsettings set org.gnome.desktop.background picture-uri "$BG_LIGHT" 2>/dev/null || true
    fi
    if [ -n "$BG_DARK" ] && [ "$GNOME_VER" -ge 42 ] || [ "$GNOME_VER" = "0" ]; then
        gsettings set org.gnome.desktop.background picture-uri-dark "$BG_DARK" 2>/dev/null || true
    fi
    gsettings set org.gnome.desktop.wm.preferences theme "$GTK_THEME" 2>/dev/null || true
    printf "%b\n" "${GREEN}GNOME theme reset to ${GTK_THEME}.${RC}"
}

resetKDE() {
    printf "%b\n" "${YELLOW}Resetting KDE Plasma ${PLASMA_VER} theme...${RC}"
    if command_exists lookandfeeltool; then
        lookandfeeltool -a org.kde.breeze.desktop 2>/dev/null || true
    fi
    KW="kwriteconfig${PLASMA_VER}"
    if ! command_exists "$KW"; then
        for kw in kwriteconfig6 kwriteconfig5; do
            command_exists "$kw" && KW="$kw" && break
        done
    fi
    if command_exists "$KW"; then
        "$KW" --file ~/.config/kdeglobals --group KDE --key widgetStyle Breeze 2>/dev/null || true
        "$KW" --file ~/.config/kdeglobals --group General --key ColorScheme Breeze 2>/dev/null || true
        "$KW" --file ~/.config/kdeglobals --group Icons --key Theme breeze 2>/dev/null || true
        "$KW" --file ~/.config/plasmarc --group Theme --key name default 2>/dev/null || true
        "$KW" --file ~/.config/kcminputrc --group Mouse --key cursorTheme breeze 2>/dev/null || true
        "$KW" --file ~/.config/kwinrc --group org.kde.kdecoration2 --key theme Breeze 2>/dev/null || true
    fi
    if command_exists plasma-apply-desktoptheme; then
        plasma-apply-desktoptheme breeze 2>/dev/null || true
    fi
    if command_exists plasma-apply-colorscheme; then
        plasma-apply-colorscheme Breeze 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}KDE Plasma theme reset to Breeze.${RC}"
}

resetXFCE() {
    if command_exists xfconf-query; then
        xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita" 2>/dev/null || true
        xfconf-query -c xsettings -p /Net/IconThemeName -s "Adwaita" 2>/dev/null || true
        xfconf-query -c xsettings -p /Gtk/CursorThemeName -s "Adwaita" 2>/dev/null || true
        xfconf-query -c xsettings -p /Gtk/FontName -s "Cantarell 11" 2>/dev/null || true
        xfconf-query -c xfwm4 -p /general/theme -s "Adwaita" 2>/dev/null || true
        xfconf-query -c xfce4-panel -p /panels/panel-0/position -s "p=6;x=0;y=0" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}XFCE theme reset to Adwaita.${RC}"
}

resetCinnamon() {
    if ! command_exists gsettings; then return; fi
    if [ "$DVER_MAJOR" -ge 21 ]; then
        GTK_THEME="Mint-Y"; ICON_THEME="Mint-Y"
        THEME_NAME="Mint-Y-Dark"; WM_THEME="Mint-Y"
    else
        GTK_THEME="Adwaita"; ICON_THEME="Adwaita"
        THEME_NAME="cinnamon"; WM_THEME="Adwaita"
    fi
    gsettings set org.cinnamon.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface cursor-theme "Adwaita" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.interface font-name "Cantarell 11" 2>/dev/null || true
    gsettings set org.cinnamon.theme name "$THEME_NAME" 2>/dev/null || true
    gsettings set org.cinnamon.desktop.wm.preferences theme "$WM_THEME" 2>/dev/null || true
    printf "%b\n" "${GREEN}Cinnamon theme reset to ${GTK_THEME}.${RC}"
}

resetMATE() {
    if ! command_exists gsettings; then return; fi
    if [ "$DTYPE" = "ubuntu" ] || [ "$DTYPE" = "ubuntu-core" ]; then
        GTK_THEME="Yaru"; ICON_THEME="Yaru"
    else
        GTK_THEME="Adwaita"; ICON_THEME="Adwaita"
    fi
    gsettings set org.mate.interface gtk-theme "$GTK_THEME" 2>/dev/null || true
    gsettings set org.mate.interface icon-theme "$ICON_THEME" 2>/dev/null || true
    gsettings set org.mate.interface cursor-theme "Adwaita" 2>/dev/null || true
    gsettings set org.mate.interface font-name "Cantarell 11" 2>/dev/null || true
    gsettings set org.mate.Marco.general theme "$GTK_THEME" 2>/dev/null || true
    printf "%b\n" "${GREEN}MATE theme reset to ${GTK_THEME}.${RC}"
}

resetBudgie() {
    resetGNOME
    if command_exists gsettings; then
        gsettings set com.solus-project.budgie.panel layout "" 2>/dev/null || true
        gsettings set com.solus-project.budgie.wm button-layout "appmenu:close" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Budgie theme reset.${RC}"
}

resetLXDE() {
    mkdir -p "$HOME/.config/lxde"
    cat > "$HOME/.config/lxde/config" <<-EOF 2>/dev/null || true
[GTK]
sNet/ThemeName=Adwaita
sNet/IconThemeName=Adwaita
sGtk/CursorThemeName=Adwaita
sGtk/FontName=Cantarell 11
EOF
    printf "%b\n" "${GREEN}LXDE theme reset.${RC}"
}

resetLXQt() {
    rm -f "$HOME/.config/lxqt/lxqt.conf" "$HOME/.config/lxqt/panel.conf" "$HOME/.config/lxqt/session.conf" 2>/dev/null || true
    printf "%b\n" "${GREEN}LXQt theme reset.${RC}"
}

resetDeepin() {
    if command_exists gsettings; then
        gsettings set com.deepin.dde.appearance gtk-theme "deepin" 2>/dev/null || \
            gsettings set com.deepin.dde.appearance gtk-theme "Adwaita" 2>/dev/null || true
        gsettings set com.deepin.dde.appearance icon-theme "deepin" 2>/dev/null || \
            gsettings set com.deepin.dde.appearance icon-theme "Adwaita" 2>/dev/null || true
        gsettings set com.deepin.dde.appearance cursor-theme "deepin" 2>/dev/null || \
            gsettings set com.deepin.dde.appearance cursor-theme "Adwaita" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Deepin theme reset.${RC}"
}

resetPantheon() {
    if command_exists gsettings; then
        gsettings set org.gnome.desktop.interface gtk-theme "io.elementary.stylesheet.blueberry" 2>/dev/null || \
            gsettings set org.gnome.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme "elementary" 2>/dev/null || \
            gsettings set org.gnome.desktop.interface icon-theme "Adwaita" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme "elementary" 2>/dev/null || \
            gsettings set org.gnome.desktop.interface cursor-theme "Adwaita" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name "Inter 10" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Pantheon theme reset.${RC}"
}

resetSway() {
    rm -f "$HOME/.config/sway/config" 2>/dev/null || true
    if [ -f /etc/sway/config ]; then
        mkdir -p "$HOME/.config/sway"
        cp /etc/sway/config "$HOME/.config/sway/" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Sway config reset.${RC}"
}

resetHyprland() {
    rm -f "$HOME/.config/hypr/hyprland.conf" 2>/dev/null || true
    if [ -f /usr/share/hyprland/hyprland.conf ]; then
        mkdir -p "$HOME/.config/hypr"
        cp /usr/share/hyprland/hyprland.conf "$HOME/.config/hypr/" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Hyprland config reset.${RC}"
}

resetWMCommon() {
    for wm_dir in i3 bspwm qtile dwm; do
        rm -f "$HOME/.config/$wm_dir/config" "$HOME/.config/$wm_dir/theme" 2>/dev/null || true
    done
    if [ -f /etc/i3/config ]; then
        mkdir -p "$HOME/.config/i3"
        cp /etc/i3/config "$HOME/.config/i3/" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}WM configs reset.${RC}"
}

resetOpenbox() {
    rm -f "$HOME/.config/openbox/rc.xml" 2>/dev/null || true
    if [ -f /etc/xdg/openbox/rc.xml ]; then
        mkdir -p "$HOME/.config/openbox"
        cp /etc/xdg/openbox/rc.xml "$HOME/.config/openbox/" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Openbox config reset.${RC}"
}

resetEnlightenment() {
    rm -rf "$HOME/.e/e/config" 2>/dev/null || true
    if command_exists enlightenment_remote; then
        enlightenment_remote -default-all 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Enlightenment reset.${RC}"
}

resetUKUI() {
    if command_exists gsettings; then
        gsettings set org.ukui.desktop.interface gtk-theme "ukui" 2>/dev/null || \
            gsettings set org.ukui.desktop.interface gtk-theme "Adwaita" 2>/dev/null || true
        gsettings set org.ukui.desktop.interface icon-theme "ukui-icon-theme" 2>/dev/null || \
            gsettings set org.ukui.desktop.interface icon-theme "Adwaita" 2>/dev/null || true
        gsettings set org.ukui.desktop.interface cursor-theme "ukui" 2>/dev/null || \
            gsettings set org.ukui.desktop.interface cursor-theme "Adwaita" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}UKUI theme reset.${RC}"
}

resetLomiri() {
    if command_exists gsettings; then
        gsettings set com.lomiri.interface gtk-theme "Adwaita" 2>/dev/null || true
        gsettings set com.lomiri.interface icon-theme "Adwaita" 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Lomiri theme reset.${RC}"
}

resetCOSMIC() {
    rm -f "$HOME/.config/cosmic/com.system76.CosmicTheme" 2>/dev/null || true
    rm -f "$HOME/.config/cosmic/com.system76.CosmicBg" 2>/dev/null || true
    printf "%b\n" "${GREEN}COSMIC theme reset.${RC}"
}

cleanThemeConfigs() {
    rm -f "$HOME/.gtkrc-2.0" "$HOME/.gtkrc.mine"
    rm -f "$HOME/.config/gtk-3.0/settings.ini"
    rm -f "$HOME/.config/gtk-4.0/settings.ini"
    rm -rf "$HOME/.config/qt5ct" "$HOME/.config/qt6ct"
    printf "%b\n" "${GREEN}Theme config files removed.${RC}"
}

cleanThemeEnv() {
    for f in "$HOME/.profile" "$HOME/.xprofile" "$HOME/.bashrc" \
             "$HOME/.zshrc" "$HOME/.xsessionrc" "$HOME/.xinitrc"; do
        if [ -f "$f" ]; then
            sed -i '/^export GTK_THEME/d; /^export QT_QPA_PLATFORMTHEME/d' "$f" 2>/dev/null || true
        fi
    done
    if command_exists sudo; then
        sudo sed -i '/^QT_QPA_PLATFORMTHEME=/d; /^GTK_THEME=/d' /etc/environment 2>/dev/null || true
    fi
    printf "%b\n" "${GREEN}Theme environment variables cleaned.${RC}"
}

resetDE() {
    case "$DE" in
        gnome) resetGNOME ;;
        kde) resetKDE ;;
        xfce) resetXFCE ;;
        cinnamon) resetCinnamon ;;
        mate) resetMATE ;;
        budgie) resetBudgie ;;
        lxde) resetLXDE ;;
        lxqt) resetLXQt ;;
        deepin) resetDeepin ;;
        pantheon) resetPantheon ;;
        sway) resetSway; resetWMCommon ;;
        hyprland) resetHyprland; resetWMCommon ;;
        i3|bspwm|qtile|dwm) resetWMCommon ;;
        openbox) resetOpenbox ;;
        enlightenment) resetEnlightenment ;;
        ukui) resetUKUI ;;
        lomiri) resetLomiri ;;
        cosmic) resetCOSMIC ;;
        *)
            printf "%b\n" "${YELLOW}Unknown DE, applying generic reset...${RC}"
            resetGNOME
            resetWMCommon ;;
    esac
}

applyReset() {
    detectGNOMEVersion
    detectPlasmaVersion
    detectDE
    cleanThemeConfigs
    cleanThemeEnv
    resetDE
    printf "%b\n" "${GREEN}Theme reset complete. Reboot or log out to apply.${RC}"
}

# --- Main menu ---

main() {
    printf "%b\n" "${YELLOW}Global Theme Manager${RC}"
    printf "%b\n" "1. ${YELLOW}Apply Dark Theme${RC}"
    printf "%b\n" "2. ${YELLOW}Reset Theme to Defaults${RC}"
    printf "%b\n" "3. ${YELLOW}Cancel${RC}"
    printf "%b" "Enter your choice [1-3]: "
    read -r CHOICE
    case "$CHOICE" in
        1) applyDarkTheme ;;
        2) applyReset ;;
        3) printf "%b\n" "${GREEN}Cancelled.${RC}" && exit 0 ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

checkEnv
checkDistro
DVER=${VERSION_ID:-0}
DVER_MAJOR=$(echo "$DVER" | cut -d. -f1)
main
