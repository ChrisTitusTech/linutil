#!/bin/sh -e 

. ../common-script.sh   

# Function to list common session options
list_sessions() {
    printf "Select the session:\n"
    printf "1) GNOME (gnome.desktop)\n"
    printf "2) KDE Plasma (plasma.desktop)\n"
    printf "3) XFCE (xfce.desktop)\n"
    printf "4) LXDE (LXDE.desktop)\n"
    printf "5) LXQt (lxqt.desktop)\n"
    printf "6) Cinnamon (cinnamon.desktop)\n"
    printf "7) MATE (mate.desktop)\n"
    printf "8) Openbox (openbox.desktop)\n"
    printf "9) i3 (i3.desktop)\n"
    printf "10) Custom session\n"
    printf "Enter your choice [1-10]: "
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
            printf "Enter custom session name (e.g., mysession.desktop): "
            read -r session ;;
        *) 
            printf "Invalid option selected.\n" 
            exit 1 ;;
    esac
}

# Function to configure LightDM
configure_lightdm() {
    printf "Configuring LightDM for autologin...\n"
    
    printf "Enter username for LightDM autologin: "
    read -r user

    "$ESCALATION_TOOL" "printf '[Seat:*]' > /etc/lightdm/lightdm.conf.d/50-autologin.conf"
    "$ESCALATION_TOOL" "printf 'autologin-user=$user' >> /etc/lightdm/lightdm.conf.d/50-autologin.conf"
    "$ESCALATION_TOOL" "printf 'autologin-user-timeout=0' >> /etc/lightdm/lightdm.conf.d/50-autologin.conf"

    printf "LightDM has been configured for autologin.\n"
}

# Function to remove LightDM autologin
remove_lightdm_autologin() {
    printf "Removing LightDM autologin configuration...\n"
    "$ESCALATION_TOOL" rm -f /etc/lightdm/lightdm.conf.d/50-autologin.conf
    printf "LightDM autologin configuration has been removed.\n"
}

# Function to configure GDM
configure_gdm() {
    printf "Configuring GDM for autologin...\n"
    
    printf "Enter username for GDM autologin: "
    read -r user

    "$ESCALATION_TOOL" "printf '[daemon]' > /etc/gdm/custom.conf"
    "$ESCALATION_TOOL" "printf 'AutomaticLoginEnable = true' >> /etc/gdm/custom.conf"
    "$ESCALATION_TOOL" "printf 'AutomaticLogin = $user' >> /etc/gdm/custom.conf"

    printf "GDM has been configured for autologin.\n"
}

# Function to remove GDM autologin
remove_gdm_autologin() {
    printf "Removing GDM autologin configuration...\n"
    "$ESCALATION_TOOL" sed -i '/AutomaticLoginEnable/d' /etc/gdm/custom.conf
    "$ESCALATION_TOOL" sed -i '/AutomaticLogin/d' /etc/gdm/custom.conf
    printf "GDM autologin configuration has been removed.\n"
}

# Function to configure SDDM
configure_sddm() {
    printf "Configuring SDDM for autologin...\n"
    
    printf "Enter username for SDDM autologin: "
    read -r user
    list_sessions  # Show session options

    "$ESCALATION_TOOL" "printf '[Autologin]' > /etc/sddm.conf"
    "$ESCALATION_TOOL" "printf 'User=$user' >> /etc/sddm.conf"
    "$ESCALATION_TOOL" "printf 'Session=$session' >> /etc/sddm.conf"

    printf "SDDM has been configured for autologin.\n"
}

# Function to remove SDDM autologin
remove_sddm_autologin() {
    printf "Removing SDDM autologin configuration...\n"
    "$ESCALATION_TOOL" sed -i '/\[Autologin\]/,+2d' /etc/sddm.conf
    printf "SDDM autologin configuration has been removed.\n"
}

# Function to configure LXDM
configure_lxdm() {
    printf "Configuring LXDM for autologin...\n"
    
    printf "Enter username for LXDM autologin: "
    read -r user
    list_sessions  # Show session options
    
    "$ESCALATION_TOOL" sed -i "s/^#.*autologin=.*$/autologin=${user}/" /etc/lxdm/lxdm.conf
    "$ESCALATION_TOOL" sed -i "s|^#.*session=.*$|session=/usr/bin/${session}|; s|^session=.*$|session=/usr/bin/${session}|" /etc/lxdm/lxdm.conf

    printf "LXDM has been configured for autologin.\n"
}

# Function to remove LXDM autologin
remove_lxdm_autologin() {
    printf "Removing LXDM autologin configuration...\n"
    "$ESCALATION_TOOL" sed -i "s/^autologin=.*$/#autologin=/" /etc/lxdm/lxdm.conf
    "$ESCALATION_TOOL" sed -i "s/^session=.*$/#session=/" /etc/lxdm/lxdm.conf
    printf "LXDM autologin configuration has been removed.\n"
}

# Function to configure or remove autologin based on user choice
configure_or_remove_autologin() {
    printf "Do you want to add or remove autologin?\n"
    printf "1) Add autologin\n"
    printf "2) Remove autologin\n"
    printf "Enter your choice [1-2]: "
    read -r action_choice

    if [ "$action_choice" = "1" ]; then
        printf "Choose the display manager to configure:\n"
        printf "1) LightDM\n"
        printf "2) GDM\n"
        printf "3) SDDM\n"
        printf "4) LXDM\n"
        printf "Enter your choice [1-4]: "
        read -r choice

        case "$choice" in
            1) configure_lightdm ;;
            2) configure_gdm ;;
            3) configure_sddm ;;
            4) configure_lxdm ;;
            *) printf "Invalid option selected.\n" ;;
        esac
    elif [ "$action_choice" = "2" ]; then
        printf "Choose the display manager to remove autologin:\n"
        printf "1) LightDM\n"
        printf "2) GDM\n"
        printf "3) SDDM\n"
        printf "4) LXDM\n"
        printf "Enter your choice [1-4]: "
        read -r choice

        case "$choice" in
            1) remove_lightdm_autologin ;;
            2) remove_gdm_autologin ;;
            3) remove_sddm_autologin ;;
            4) remove_lxdm_autologin ;;
            *) printf "Invalid option selected.\n" ;;
        esac
    else
        printf "Invalid choice. Exiting...\n"
        exit 1
    fi

    printf "Action completed. Exiting...\n"
    exit 0
}

checkEnv
checkEscalationTool
configure_or_remove_autologin
