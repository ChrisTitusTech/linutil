#!/bin/sh -e

. ../../common-script.sh
# This script allows user to download proprietary drivers for nvidia in fedora

# It also disables noveau nvidia drivers

# Installation guide link: https://rpmfusion.org/Howto/NVIDIA

# NOTE: Currently script only provides drivers for gpu 2014 and above (510+ and above)

checkRepo() {
  REPO_ID="rpmfusion-nonfree-nvidia-driver"

  if [ $(dnf repolist enabled 2>/dev/null | grep "$REPO_ID" | wc -l) -gt 0 ]; then
    printf "%b\n" "${GREEN}Nvidia non-free repository is already enabled.${RC}"
  else
    printf "%b\n" "${YELLOW}Nvidia non-free repository is not enabled. Enabling now...${RC}"

    # Enable the repository
    $ESCALATION_TOOL dnf config-manager --set-enabled "$REPO_ID"

    # Refreshing repository list
    $ESCALATION_TOOL dnf makecache

    # Verify if the repository is enabled
    if [ $(dnf repolist enabled 2>/dev/null | grep "$REPO_ID" | wc -l) -gt 0 ]; then
      printf "%b\n" "${GREEN}Nvidia non-free repository is now enabled...${RC}"
    else
      printf "%b\n" "${RED}Failed to enable nvidia non-free repository...${RC}"
      exit 1
    fi
  fi
}

checkDriverInstallation() {
  if modinfo -F version nvidia >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

driverSetupMenu() {

  installDriver() {
    if checkDriverInstallation; then
      printf "%b\n" "${GREEN}NVIDIA driver is already installed.${RC}"
      exit 0
    fi

    # NOTE:: Installing graphics driver.
    $ESCALATION_TOOL dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y
    printf "%b\n" "${YELLOW}Building the drivers may take upto 5 minutes. Please don't kill the script!\n If the build failed try running the script again, select \"Remove Nvidia Drivers\" and reboot the system, then try installing drivers again.${RC}"

    for i in {1..5}; do
      if checkDriverInstallation; then
        printf "%b\n" "${GREEN}Driver installed successfully.${RC}"
        printf "%b\n" "${GREEN}Installed driver version $(modinfo -F version nvidia)${RC}"
        break
      fi
      printf "%b\n" "${YELLOW}Waiting for driver to be built..."
      sleep 1m
    done

    printf "%b\n" "${GREEN}Now you can reboot the system.${RC}"
  }

  removeDriver() {

    if ! checkDriverInstallation; then
      printf "%b\n" "${RED}NVIDIA driver is not installed.${RC}"
      exit 0
    fi

    printf "%b\n" "${YELLOW}Removing Nvidia Drivers ${RC}"
    $ESCALATION_TOOL dnf remove akmod-nvidia xorg-x11-drv-nvidia xorg-x11-drv-nvidia-cuda -y

    printf "%b\n" "${YELLOW}Resetting Nvidia Settings${RC}"
    $ESCALATION_TOOL rm -f /usr/lib{,64}/libGL.so.* /usr/lib{,64}/libEGL.so.*
    $ESCALATION_TOOL rm -f /usr/lib{,64}/xorg/modules/extensions/libglx.so
    $ESCALATION_TOOL dnf reinstall xorg-x11-server-Xorg mesa-libGL mesa-libEGL libglvnd\* -y

    # NOTE: Check if /etc/X11/xorg.conf exists
    if [ -f /etc/X11/xorg.conf ]; then
      $ESCALATION_TOOL mv /etc/X11/xorg.conf /etc/X11/xorg.conf.saved
    else
      echo "/etc/X11/xorg.conf does not exist."
    fi
    printf "%b\n" "${GREEN}Nvidia driver was successfully removed${RC}"
    printf "%b\n" "${YELLOW}If you want to remove the nvidia non-free repository run sudo dnf config-manager --set-disabled rpmfusion-nonfree-nvidia-driver${RC}"
  }

  echo "1. Install Nvidia Drivers"
  echo "2. Remove Nvidia Drivers"

  read -p "Enter your choice: " choice

  case "${choice}" in
  1)
    installDriver
    ;;
  2)
    removeDriver
    ;;
  *)
    printf "%b\n" "${RED}Invalid Options${RC}"
    exit 1
    ;;
  esac

}

# NOTE: A confirmation option to proceed or not
userConfirmation() {
  read -p "Do you want to continue? (Y/N): " choice
  case "$choice" in
  y | Y)
    checkRepo
    driverSetupMenu
    return
    ;;
  n | N)
    printf "%b\n" "${RED} Exiting the Script ${RC}"
    return
    ;;
  *)
    printf "%b\n" "${RED} Invalid Option! ${RC}"
    userConfirmation
    ;;
  esac
}

printf "%b\n" "${YELLOW}Warning! This script will enable Nvidia non-free repository and only install drivers for GPUs from 2014 or later. It works on fedora 34 and above.${RC}"

checkEnv
checkEscalationTool
userConfirmation
