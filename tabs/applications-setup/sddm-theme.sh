#!/bin/sh -e

. ../common-script.sh

USERNAME=`whoami`

install_sddm() {
    printf "${YELLOW}Installing SDDM login manager...${RC}\n"
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
            printf "${RED}Unsupported package manager. Please install SDDM manually.${RC}\n"
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
    echo "Available sessions:"
    i=1
    while [ $i -le 2 ]; do
        session_type=""
        if [ $i -eq 1 ]; then
            session_type="xsessions"
        else
            session_type="wayland-sessions"
        fi

        for session_file in /usr/share/$session_type/*.desktop; do
            [ -e "$session_file" ] || continue
            name=`grep -i "^Name=" "$session_file" | cut -d= -f2`
            type=`echo $session_type | sed 's/s$//'`  # Remove trailing 's'
            echo "%d) %s (%s)\n" "$i" "$name" "$type"
            sessions[$i]="$session_file"
            session_names[$i]="$name ($type)"
            i=`expr $i + 1`
        done
    done

    # Prompt user to choose a session
    while true; do
        echo "Enter the number of the session you'd like to autologin: "
        read choice
        if [ -n "${sessions[$choice]}" ]; then
            session_file="${sessions[$choice]}"
            break
        else
            echo "Invalid choice. Please enter a valid number."
        fi
    done

    # Find the corresponding .desktop file and Update SDDM configuration
    actual_session=`basename "$session_file" .desktop`

    $ESCALATION_TOOL sed -i '1i[Autologin]\nUser = '$USERNAME'\nSession = '$actual_session'\n' /etc/sddm.conf
    echo "Autologin configuration complete."
}

checkEnv
checkEscalationTool

# Check if SDDM is already installed
if ! command -v sddm > /dev/null; then
    install_sddm
else
    echo "SDDM is already installed. Skipping installation."
fi

install_theme

echo "Do you want to enable autologin? (y/n): "
read enable_autologin
if [ "$enable_autologin" = "y" ] || [ "$enable_autologin" = "Y" ]; then
    configure_autologin
else
    echo "Autologin not configured."
fi

$ESCALATION_TOOL systemctl restart sddm
