#!/bin/sh -e

. ../common-script.sh

USERNAME=$(whoami)

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
    sessions=""
    session_names=""
    i=1
    for session_type in xsessions wayland-sessions; do
        for session_file in /usr/share/"$session_type"/*.desktop; do
            [ -e "$session_file" ] || continue
            name=$(grep -i "^Name=" "$session_file" | cut -d= -f2)
            type=$(printf "%s" "$session_type" | sed 's/s$//')  # Remove trailing 's'
            printf "%d) %s (%s)\n" "$i" "$name" "$type"
            sessions="$sessions $i:$session_file"
            session_names="$session_names $i:$name ($type)"
            i=$((i + 1))
        done
    done

    # Prompt user to choose a session
    while true; do
        printf "Enter the number of the session you'd like to autologin: "
        read -r choice
        session_file=$(echo "$sessions" | tr ' ' '\n' | grep "^$choice:" | cut -d: -f2)
        if [ -n "$session_file" ]; then
            break
        else
            printf "Invalid choice. Please enter a valid number.\n"
        fi
    done

    # Find the corresponding .desktop file and Update SDDM configuration
    actual_session=$(basename "$session_file" .desktop)

    $ESCALATION_TOOL tee -a /etc/sddm.conf > /dev/null << EOF
[Autologin]
User=$USERNAME
Session=$actual_session
EOF
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
