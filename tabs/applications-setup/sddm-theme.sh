#!/bin/sh -e

. ../common-script.sh

USERNAME=$(whoami)

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
    $ESCALATION_TOOL tee /etc/sddm.conf > /dev/null << EOF
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
    i=1
    while [ $i -le 2 ]; do
        if [ $i -eq 1 ]; then
            session_type="xsessions"
        else
            session_type="wayland-sessions"
        fi

        for session_file in /usr/share/$session_type/*.desktop; do
            [ -e "$session_file" ] || continue
            name=$(grep -i "^Name=" "$session_file" | cut -d= -f2-)
            type=$(echo "$session_type" | sed 's/s$//')  # Remove trailing 's'
            printf "%d) %s (%s)\n" "$i" "$name" "$type"
            i=$((i + 1))
        done
    done

    # Prompt user to choose a session
    while true; do
        printf "Enter the number of the session you'd like to autologin: "
        read -r choice
        if [ "$choice" -ge 1 ] && [ "$choice" -lt "$i" ]; then
            session_file="/usr/share/$session_type/$(sed -n "${choice}p" <<< "$(printf "%s\n" /usr/share/$session_type/*.desktop)")"
            actual_session=$(basename "$session_file" .desktop)
            break
        else
            printf "Invalid choice. Please enter a valid number.\n"
        fi
    done

    # Update SDDM configuration
    $ESCALATION_TOOL sed -i "1i[Autologin]\nUser = $USERNAME\nSession = $actual_session\n" /etc/sddm.conf
    printf "Autologin configuration complete.\n"
}

checkEnv
checkEscalationTool

# Check if SDDM is already installed
if ! command -v sddm > /dev/null; then
    install_sddm
else
    printf "SDDM is already installed. Skipping installation.\n"
fi

install_theme

printf "Do you want to enable autologin? (y/n): "
read -r enable_autologin
if [ "$enable_autologin" = "y" ] || [ "$enable_autologin" = "Y" ]; then
    configure_autologin
else
    printf "Autologin not configured.\n"
fi

$ESCALATION_TOOL systemctl restart sddm
