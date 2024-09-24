#!/bin/sh -e 

. ../common-script.sh   

# Function to list common session options
list_sessions() {
    printf "%b\n" "Select the session:"
    printf "%b\n" "1) GNOME (gnome.desktop)"
    printf "%b\n" "2) KDE Plasma (plasma.desktop)"
    printf "%b\n" "3) XFCE (xfce.desktop)"
    printf "%b\n" "4) LXDE (LXDE.desktop)"
    printf "%b\n" "5) LXQt (lxqt.desktop)"
    printf "%b\n" "6) Cinnamon (cinnamon.desktop)"
    printf "%b\n" "7) MATE (mate.desktop)"
    printf "%b\n" "8) Openbox (openbox.desktop)"
    printf "%b\n" "9) i3 (i3.desktop)"
    printf "%b\n" "10) Custom session"
    printf "%b" "Enter your choice (1-10): "
    read -r session_choice

    case "$session_choice" in
        1) session="gnome.desktop" ;;
        2) session="plasma.desktop" ;;
        3) session="xfce.desktop" ;;
        4) session="LXDE.desktop" ;;
        5) session="lxqt.desktop" ;;
        6) session="cinnamon.desktop" ;;
        7) session="mate.desktop" ;;
        8) session="openbox.desktop" ;;
        9) session="i3.desktop" ;;
        10) 
            printf "%b" "Enter custom session name (e.g., mysession): "
            read -r session ;;
        *) 
            printf "%b\n" "Invalid option selected."
            exit 1 ;;
    esac
}

# Function to configure LightDM
configure_lightdm() {
    printf "%b\n" "Configuring LightDM for autologin..."
    printf "%b" "Enter username for LightDM autologin: "
    read -r user

    printf "%b\n" '[Seat:*]' | "$ESCALATION_TOOL" tee -a /etc/lightdm/lightdm.conf
    printf "%s\n" "autologin-user=$user" | "$ESCALATION_TOOL" tee -a /etc/lightdm/lightdm.conf
    printf "%b\n" 'autologin-user-timeout=0' | "$ESCALATION_TOOL" tee -a /etc/lightdm/lightdm.conf

    printf "%b\n" "LightDM has been configured for autologin."
}

# Function to remove LightDM autologin
remove_lightdm_autologin() {
    printf "%b\n" "Removing LightDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' '/^\[Seat:\*]/d' /etc/lightdm/lightdm.conf
    "$ESCALATION_TOOL" sed -i'' '/^autologin-/d' /etc/lightdm/lightdm.conf
    printf "%b\n" "LightDM autologin configuration has been removed."
}

# Function to configure GDM
configure_gdm() {
    printf "%b\n" "Configuring GDM for autologin..."
    printf "%b" "Enter username for GDM autologin: "
    read -r user

    printf "%b\n" '[daemon]' | "$ESCALATION_TOOL" tee -a /etc/gdm/custom.conf
    printf "%b\n" 'AutomaticLoginEnable = true' | "$ESCALATION_TOOL" tee -a /etc/gdm/custom.conf
    printf "%s\n" "AutomaticLogin = $user" | "$ESCALATION_TOOL" tee -a /etc/gdm/custom.conf

    printf "%b\n" "GDM has been configured for autologin."
}

# Function to remove GDM autologin
remove_gdm_autologin() {
    printf "%b\n" "Removing GDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' '/AutomaticLoginEnable/d' /etc/gdm/custom.conf
    "$ESCALATION_TOOL" sed -i'' '/AutomaticLogin/d' /etc/gdm/custom.conf
    printf "%b\n" "GDM autologin configuration has been removed."
}

# Function to configure SDDM
configure_sddm() {
    printf "%b\n" "Configuring SDDM for autologin..."
    printf "%b" "Enter username for SDDM autologin: "
    read -r user
    list_sessions  # Show session options

    printf "%b\n" '[Autologin]' | "$ESCALATION_TOOL" tee -a /etc/sddm.conf
    printf "%s\n" "User=$user" | "$ESCALATION_TOOL" tee -a /etc/sddm.conf
    printf "%s\n" "Session=$session" | "$ESCALATION_TOOL" tee -a /etc/sddm.conf

    printf "%b\n" "SDDM has been configured for autologin."
}

# Function to remove SDDM autologin
remove_sddm_autologin() {
    printf "%b\n" "Removing SDDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' '/\[Autologin\]/,+2d' /etc/sddm.conf
    printf "%b\n" "SDDM autologin configuration has been removed."
}

# Function to configure LXDM
configure_lxdm() {
    printf "%b\n" "Configuring LXDM for autologin..."
    printf "%b" "Enter username for LXDM autologin: "
    read -r user
    list_sessions  # Show session options
    
    "$ESCALATION_TOOL" sed -i'' "s/^#.*autologin=.*$/autologin=${user}/" /etc/lxdm/lxdm.conf
    "$ESCALATION_TOOL" sed -i'' "s|^#.*session=.*$|session=/usr/bin/${session}|; s|^session=.*$|session=/usr/bin/${session}|" /etc/lxdm/lxdm.conf

    printf "%b\n" "LXDM has been configured for autologin."
}

# Function to remove LXDM autologin
remove_lxdm_autologin() {
    printf "%b\n" "Removing LXDM autologin configuration..."
    "$ESCALATION_TOOL" sed -i'' "s/^autologin=.*$/#autologin=/" /etc/lxdm/lxdm.conf
    "$ESCALATION_TOOL" sed -i'' "s/^session=.*$/#session=/" /etc/lxdm/lxdm.conf
    printf "%b\n" "LXDM autologin configuration has been removed."
}

# Function to configure or remove autologin based on user choice
configure_or_remove_autologin() {
    printf "%b\n" "Do you want to add or remove autologin?"
    printf "%b\n" "1) Add autologin"
    printf "%b\n" "2) Remove autologin"
    printf "%b" "Enter your choice (1-2): "
    read -r action_choice

    if [ "$action_choice" = "1" ]; then
        printf "%b\n" "Choose the display manager to configure:"
        printf "%b\n" "1) LightDM"
        printf "%b\n" "2) GDM"
        printf "%b\n" "3) SDDM"
        printf "%b\n" "4) LXDM"
        printf "%b" "Enter your choice (1-4): "
        read -r choice

        case "$choice" in
            1) configure_lightdm ;;
            2) configure_gdm ;;
            3) configure_sddm ;;
            4) configure_lxdm ;;
            *) printf "%b\n" "Invalid option selected." ;;
        esac
    elif [ "$action_choice" = "2" ]; then
        printf "%b\n" "Choose the display manager to remove autologin:"
        printf "%b\n" "1) LightDM"
        printf "%b\n" "2) GDM"
        printf "%b\n" "3) SDDM"
        printf "%b\n" "4) LXDM"
        printf "%b" "Enter your choice (1-4): "
        read -r choice

        case "$choice" in
            1) remove_lightdm_autologin ;;
            2) remove_gdm_autologin ;;
            3) remove_sddm_autologin ;;
            4) remove_lxdm_autologin ;;
            *) printf "%b\n" "Invalid option selected." ;;
        esac
    else
        printf "%b\n" "Invalid choice. Exiting..."
        exit 1
    fi

    printf "%b\n" "Action completed. Exiting..."
    exit 0
}

checkEnv
checkEscalationTool
configure_or_remove_autologin
