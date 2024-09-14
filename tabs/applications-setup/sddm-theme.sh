#!/bin/sh

. ../common-script.sh

USERNAME=$(id -un)

install_sddm() {
    printf "%sInstalling SDDM login manager...%s\n" "$YELLOW" "$RC"
    case "$PACKAGER" in
        apt-get)
            $ESCALATION_TOOL apt-get update
            $ESCALATION_TOOL apt-get install -y sddm qt6-svg
            ;;
        zypper)
            $ESCALATION_TOOL zypper refresh
            $ESCALATION_TOOL zypper --non-interactive install sddm qt6-svg
            ;;
        dnf)
            $ESCALATION_TOOL dnf update
            $ESCALATION_TOOL dnf install -y sddm qt6-qtsvg
            ;;
        pacman)
            $ESCALATION_TOOL pacman -S --needed --noconfirm sddm qt6-svg
            ;;
        *)
            printf "%sUnsupported package manager. Please install SDDM manually.%s\n" "$RED" "$RC"
            exit 1
            ;;
    esac
}

install_theme() {
    printf "Installing and configuring SDDM theme...\n"

    # Check if astronaut-theme already exists
    if [ -d "/usr/share/sddm/themes/sddm-astronaut-theme" ]; then
        printf "SDDM astronaut theme is already installed. Skipping theme installation.\n"
    else
        if ! $ESCALATION_TOOL git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme; then
            printf "Failed to clone theme repository. Exiting.\n"
            exit 1
        fi
    fi

    # Create or update /etc/sddm.conf
    $ESCALATION_TOOL sh -c "cat > /etc/sddm.conf" << EOF
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=sddm-astronaut-theme
EOF

    $ESCALATION_TOOL systemctl enable sddm
    printf "SDDM theme configuration complete.\n"
}

# Autologin
configure_autologin() {
    printf "Available sessions:\n"
    sessions=""
    session_names=""
    i=1
    for session_type in xsessions wayland-sessions; do
        for session_file in /usr/share/"$session_type"/*.desktop; do
            [ -e "$session_file" ] || continue
            name=$(sed -n 's/^Name=//p' "$session_file" | head -n 1)
            type=${session_type%s}  # Remove trailing 's'
            printf "%d) %s (%s)\n" "$i" "$name" "$type"
            sessions="$sessions $i:$session_file"
            session_names="$session_names $i:$name ($type)"
            i=$((i + 1))
        done
    done

    # Prompt user to choose a session
    while true; do
        printf "Enter the number of the session you'd like to autologin: "
        read -r enable_autologin
        session_file=$(printf "%s\n" "$sessions" | sed -n "s/^$enable_autologin://p")
        if [ -n "$session_file" ]; then
            break
        else
            printf "Invalid choice. Please enter a valid number.\n"
        fi
    done

    # Find the corresponding .desktop file and Update SDDM configuration
    actual_session=${session_file##*/}
    actual_session=${actual_session%.desktop}

    $ESCALATION_TOOL sh -c "cat >> /etc/sddm.conf" << EOF

[Autologin]
User=$USERNAME
Session=$actual_session
EOF
    printf "Autologin configuration complete.\n"
}

checkEnv
checkEscalationTool

# Check if SDDM is already installed
if ! command -v sddm > /dev/null 2>&1; then
    install_sddm
else
    printf "SDDM is already installed. Skipping installation.\n"
fi

install_theme

printf "Do you want to enable autologin? (y/n): "
read -r enable_autologin
case "$enable_autologin" in
    [Yy]*)
        configure_autologin
        ;;
    *)
        printf "Autologin not configured.\n"
        ;;
esac

$ESCALATION_TOOL systemctl restart sddm
