#!/bin/sh -e

. ../common-script.sh

install_sddm() {
    printf "%b\n" "${YELLOW}Installing SDDM...${RC}"
    case $PACKAGER in
        apt-get|nala)
            $ESCALATION_TOOL "$PACKAGER" install -y sddm qt6-svg-dev
            ;;
        zypper)
            $ESCALATION_TOOL "$PACKAGER" --non-interactive install sddm-qt6 qt6-svg
            ;;
        dnf)
            $ESCALATION_TOOL "$PACKAGER" install -y sddm qt6-qtsvg
            ;;
        pacman)
            $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm sddm qt6-svg
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager. Please install SDDM manually.${RC}"
            exit 1
            ;;
    esac
}

install_theme() {
    echo "Installing and configuring SDDM theme..."

    # Check if astronaut-theme already exists
    if [ -d "/usr/share/sddm/themes/sddm-astronaut-theme" ]; then
        echo "SDDM astronaut theme is already installed. Skipping theme installation."
    else
        if ! $ESCALATION_TOOL git clone https://github.com/keyitdev/sddm-astronaut-theme.git /usr/share/sddm/themes/sddm-astronaut-theme; then
            echo "Failed to clone theme repository. Exiting."
            exit 1
        fi
    fi

    # Create or update /etc/sddm.conf
    $ESCALATION_TOOL tee /etc/sddm.conf > /dev/null << EOF
[General]
HaltCommand=/usr/bin/systemctl poweroff
RebootCommand=/usr/bin/systemctl reboot

[Theme]
Current=sddm-astronaut-theme
EOF

    $ESCALATION_TOOL systemctl enable sddm
    echo "SDDM theme configuration complete."
}

# Autologin
configure_autologin() {
    read -r -p "Do you want to enable autologin? (y/n): " enable_autologin
    if [ "$enable_autologin" != "y" ] && [ "$enable_autologin" != "Y" ]; then
        echo "Autologin not configured."
        return
    fi

    echo "Available sessions:"
    i=1
    for session_type in xsessions wayland-sessions; do
        for session_file in /usr/share/$session_type/*.desktop; do
            [ -e "$session_file" ] || continue
            name=$(grep -i "^Name=" "$session_file" | cut -d= -f2)
            type=$(echo "$session_type" | sed 's/s$//')
            eval "session_file_$i=\"$session_file\""
            echo "$i) $name ($type)"
            i=$((i + 1))
        done
    done

    # Prompt user to choose a session
    while true; do
        echo "Enter the number of the session you'd like to autologin: "
        read choice
        selected_session=""
        eval "selected_session=\$session_file_$choice"
        if [ -n "$selected_session" ]; then
            session_file="$selected_session"
            break
        else
            echo "Invalid choice. Please enter a valid number."
        fi
    done

    # Find the corresponding .desktop file and Update SDDM configuration
    actual_session=$(basename "$session_file" .desktop)

    $ESCALATION_TOOL sed -i '1i[Autologin]\nUser = '"$USER"'\nSession = '"$actual_session"'\n' /etc/sddm.conf
    echo "Autologin configuration complete."

    echo "For changes to take effect, do you want to restart SDDM now? (y/n): " restart_sddm
    if [ "$restart_sddm" = "y" ] || [ "$restart_sddm" = "Y" ]; then
        $ESCALATION_TOOL systemctl restart sddm
    fi
}

checkEnv
checkEscalationTool
install_sddm
install_theme
configure_autologin
