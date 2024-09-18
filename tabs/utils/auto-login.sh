#!/bin/sh -e 

. ../common-script.sh   

# Function to list common session options
list_sessions() {
    echo "Select the session:"
    echo "1) GNOME (gnome.desktop)"
    echo "2) KDE Plasma (plasma.desktop)"
    echo "3) XFCE (xfce.desktop)"
    echo "4) LXDE (LXDE.desktop)"
    echo "5) LXQt (lxqt.desktop)"
    echo "6) Cinnamon (cinnamon.desktop)"
    echo "7) MATE (mate.desktop)"
    echo "8) Openbox (openbox.desktop)"
    echo "9) i3 (i3.desktop)"
    echo "10) Custom session"
    echo "Enter your choice [1-10]: "
    read session_choice

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
            echo "Enter custom session name (e.g., mysession.desktop): "
            read session ;;
        *) 
            echo "Invalid option selected." 
            exit 1 ;;
    esac
}

# Function to configure LightDM
configure_lightdm() {
    echo "Configuring LightDM for autologin..."
    
    echo "Enter username for LightDM autologin: "
    read -r user

    $ESCALATION_TOOL "echo '[Seat:*]' > /etc/lightdm/lightdm.conf.d/50-autologin.conf"
    $ESCALATION_TOOL "echo 'autologin-user=$user' >> /etc/lightdm/lightdm.conf.d/50-autologin.conf"
    $ESCALATION_TOOL "echo 'autologin-user-timeout=0' >> /etc/lightdm/lightdm.conf.d/50-autologin.conf"

    echo "LightDM has been configured for autologin."
}

# Function to remove LightDM autologin
remove_lightdm_autologin() {
    echo "Removing LightDM autologin configuration..."
    $ESCALATION_TOOL rm -f /etc/lightdm/lightdm.conf.d/50-autologin.conf
    echo "LightDM autologin configuration has been removed."
}

# Function to configure GDM
configure_gdm() {
    echo "Configuring GDM for autologin..."
    
    echo "Enter username for GDM autologin: "
    read -r user

    $ESCALATION_TOOL "echo '[daemon]' > /etc/gdm/custom.conf"
    $ESCALATION_TOOL "echo 'AutomaticLoginEnable = true' >> /etc/gdm/custom.conf"
    $ESCALATION_TOOL "echo 'AutomaticLogin = $user' >> /etc/gdm/custom.conf"

    echo "GDM has been configured for autologin."
}

# Function to remove GDM autologin
remove_gdm_autologin() {
    echo "Removing GDM autologin configuration..."
    $ESCALATION_TOOL sed -i '/AutomaticLoginEnable/d' /etc/gdm/custom.conf
    $ESCALATION_TOOL sed -i '/AutomaticLogin/d' /etc/gdm/custom.conf
    echo "GDM autologin configuration has been removed."
}

# Function to configure SDDM
configure_sddm() {
    echo "Configuring SDDM for autologin..."
    
    echo "Enter username for SDDM autologin: "
    read -r user
    list_sessions  # Show session options

    $ESCALATION_TOOL "echo '[Autologin]' > /etc/sddm.conf"
    $ESCALATION_TOOL "echo 'User=$user' >> /etc/sddm.conf"
    $ESCALATION_TOOL "echo 'Session=$session' >> /etc/sddm.conf"

    echo "SDDM has been configured for autologin."
}

# Function to remove SDDM autologin
remove_sddm_autologin() {
    echo "Removing SDDM autologin configuration..."
    $ESCALATION_TOOL sed -i '/\[Autologin\]/,+2d' /etc/sddm.conf
    echo "SDDM autologin configuration has been removed."
}

# Function to configure LXDM
configure_lxdm() {
    echo "Configuring LXDM for autologin..."
    
    echo "Enter username for LXDM autologin: "
    read -r user
    list_sessions  # Show session options
    
    $ESCALATION_TOOL sed -i "s/^#.*autologin=.*$/autologin=${user}/" /etc/lxdm/lxdm.conf
    $ESCALATION_TOOL sed -i "s|^#.*session=.*$|session=/usr/bin/${session}|; s|^session=.*$|session=/usr/bin/${session}|" /etc/lxdm/lxdm.conf

    echo "LXDM has been configured for autologin."
}

# Function to remove LXDM autologin
remove_lxdm_autologin() {
    echo "Removing LXDM autologin configuration..."
    $ESCALATION_TOOL sed -i "s/^autologin=.*$/#autologin=/" /etc/lxdm/lxdm.conf
    $ESCALATION_TOOL sed -i "s/^session=.*$/#session=/" /etc/lxdm/lxdm.conf
    echo "LXDM autologin configuration has been removed."
}

# Function to configure or remove autologin based on user choice
configure_or_remove_autologin() {
    echo "Do you want to add or remove autologin?"
    echo "1) Add autologin"
    echo "2) Remove autologin"
    echo "Enter your choice [1-2]: "
    read action_choice

    if [ "$action_choice" = "1" ]; then
        echo "Choose the display manager to configure:"
        echo "1) LightDM"
        echo "2) GDM"
        echo "3) SDDM"
        echo "4) LXDM"
        echo "Enter your choice [1-4]: "
        read choice

        case "$choice" in
            1) configure_lightdm ;;
            2) configure_gdm ;;
            3) configure_sddm ;;
            4) configure_lxdm ;;
            *) echo "Invalid option selected." ;;
        esac
    elif [ "$action_choice" = "2" ]; then
        echo "Choose the display manager to remove autologin:"
        echo "1) LightDM"
        echo "2) GDM"
        echo "3) SDDM"
        echo "4) LXDM"
        echo "Enter your choice [1-4]: "
        read choice

        case "$choice" in
            1) remove_lightdm_autologin ;;
            2) remove_gdm_autologin ;;
            3) remove_sddm_autologin ;;
            4) remove_lxdm_autologin ;;
            *) echo "Invalid option selected." ;;
        esac
    else
        echo "Invalid choice. Exiting..."
        exit 1
    fi

    echo "Action completed. Exiting..."
    exit 0
}


checkEnv
checkEscalationTool
configure_or_remove_autologin
