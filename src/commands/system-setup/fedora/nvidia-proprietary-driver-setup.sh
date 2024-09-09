#!/usr/bin/env bash

. "$(dirname "$0")/../../common-script.sh"
# This script allows user to download proprietary drivers for nvidia in fedora

# It also disables noveau nvidia drivers

# Installation guide link: https://rpmfusion.org/Howto/NVIDIA

# NOTE: Currently script only provides drivers for gpu 2014 and above (510+ and above)

#NOTE: The main function which executes the commands based on option selected by user
# all the commands are used from the installation guide link provided above
function menu() {
  echo -e "Welcome to Nvidia Driver Setup Script"
  PS3="Your Option: "
  options=("Install Nvidia Drivers" "Remove Nvidia Drivers")

  select SELECTED_OPTION in "${options[@]}"; do
    case "${SELECTED_OPTION}" in
    "Install Nvidia Drivers")
      checkPackageManager 'dnf'
      sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y
      echo -e "${YELLOW} Stopping script for 4min, for building the drivers. Please don't kill the script!\n If the driver number is showing then your driver is installed properly.\n Else run the script again, select second option and reboot the system, then try the first option again.${RC}"
      sleep 4m
      modinfo -F version nvidia
      echo -e "Now you can reboot the system."
      break
      ;;

    "Remove Nvidia Drivers")
      echo -e "${GREEN}Removing Nvidia Drivers${RC}"
      sudo dnf remove akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda -y

      echo -e "${GREEN}Resetting Nvidia Settings${RC}"
      sudo rm -f /usr/lib{,64}/libGL.so.* /usr/lib{,64}/libEGL.so.*
      sudo rm -f /usr/lib{,64}/xorg/modules/extensions/libglx.so
      sudo dnf reinstall xorg-x11-server-Xorg mesa-libGL mesa-libEGL libglvnd\* -y
      # Check if /etc/X11/xorg.conf exists
      if [ -f /etc/X11/xorg.conf ]; then
        sudo mv /etc/X11/xorg.conf /etc/X11/xorg.conf.saved
      else
        echo "/etc/X11/xorg.conf does not exist."
      fi
      break
      ;;

    "*")
      echo "Invalid Option"
      break
      ;;
    esac
  done

}

# NOTE: A confirmation option to proceed or not
userConfirmation() {
  read -p "Do you want to continue? (Y/N): " choice
  case "$choice" in
  y | Y)
    menu
    return
    ;;
  n | N)
    echo "Exiting the script"
    return
    ;;
  *)
    echo "Invalid Option"
    userConfirmation
    ;;
  esac
}

echo -e "${YELLOW} Warning! This script only install drivers for GPU found in 2014 or later and this works on fedora 40 and above system ${RC}"

userConfirmation
