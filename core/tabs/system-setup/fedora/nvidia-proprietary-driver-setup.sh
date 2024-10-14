#!/bin/sh -e

. ../../common-script.sh
# This script allows user to download proprietary drivers for nvidia in fedora

# It also disables nouveau nvidia drivers

# Installation guide link: https://rpmfusion.org/Howto/NVIDIA

# NOTE: Currently script only provides drivers for gpu 2014 and above (510+ and above)

checkRepo() {
  REPO_ID="rpmfusion-nonfree-nvidia-driver"

  if [ "$(dnf repolist enabled 2>/dev/null | grep -c "$REPO_ID")" -gt 0 ]; then
    printf "%b\n" "${GREEN}Nvidia non-free repository is already enabled.${RC}"
  else
    printf "%b\n" "${YELLOW}Nvidia non-free repository is not enabled. Enabling now...${RC}"

    # Enable the repository
    elevated_execution dnf config-manager --set-enabled "$REPO_ID"

    # Refreshing repository list
    elevated_execution dnf makecache

    # Verify if the repository is enabled
    if [ "$(dnf repolist enabled 2>/dev/null | grep -c "$REPO_ID")" -gt 0 ]; then
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

installDriver() {

  if checkDriverInstallation; then
    printf "%b\n" "${GREEN}NVIDIA driver is already installed.${RC}"
    exit 0
  fi

  # NOTE:: Installing graphics driver.
  elevated_execution dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda -y
  printf "%b\n" "${YELLOW}Building the drivers may take upto 5 minutes. Please don't kill the script!\n If the build failed try running the script again, select \"Remove Nvidia Drivers\" and reboot the system, then try installing drivers again.${RC}"

  for i in $(seq 1 5); do
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

# NOTE: A confirmation option to proceed or not
userConfirmation() {
  printf "%b" "${YELLOW}Do you want to continue? (y/N): ${RC}"
  read -r choice
  case "$choice" in
  y | Y)
    checkRepo
    installDriver
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

printf "%b\n" "${YELLOW}Warning! This script will enable Nvidia non-free repository and only install drivers for GPUs from 2014 or later. It works on fedora 34 and above.\n It is recommended remove this driver while updating your kernel packages to newer version.${RC}"

checkEnv
checkEscalationTool
userConfirmation
