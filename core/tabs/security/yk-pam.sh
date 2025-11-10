#############################
# YubiKey-PAM Configuration
#############################
# TESTED AND WORKING
# Add Yubikey authentication to PAM configuration for sudo, requiring touch and not prompting for password.
# This code sets up your Yubikey for sudo authentication.
# It adds a rule to the system's PAM configuration that lets you use your Yubikey's touch to confirm sudo commands instead of typing a password.
# This is safer than using "required" because "sufficient" means if the Yubikey works, you're in (no password needed), but if it fails (e.g., key lost), you can still use your password as a backup. "Required" would demand both, potentially locking you out if the key is unavailable.

# Backup existing PAM configuration for sudo
if [ -e /etc/u2f_mappings ]; then
  sudo tar -C / -czf ~/pam_u2f_backup.tgz etc/pam.d/sudo etc/u2f_mappings
else
  sudo tar -C / -czf ~/pam_u2f_backup.tgz etc/pam.d/sudo
fi
echo -e "${INFO} ${GREEN}Backup of PAM configuration for sudo created at ~/pam_u2f_backup.tgz${NC}"

sleep 1

# Add pam_u2f to the PAM configuration for sudo if not already present
if ! grep -q "pam_u2f.so" /etc/pam.d/sudo; then
  echo -e "${INFO} ${YELLOW}Configuring PAM for Yubikey...${NC}"
  sudo bash -c 'echo "auth       sufficient   pam_u2f.so cue" >> /etc/pam.d/sudo'
  echo -e "${INFO} ${GREEN}PAM configured for Yubikey.${NC}"
else
  echo -e "${INFO} ${GREEN}PAM already configured for Yubikey. Skipping...${NC}"
fi

# Enroll your YubiKey (generate mapping for pam_u2f)
echo -e "${INFO} ${YELLOW}Enrolling YubiKey for pam_u2f...${NC}"

# Determine the actual user being configured (supports running via sudo)
TARGET_USER=${SUDO_USER:-$USER}
TARGET_HOME=$(eval echo ~"${TARGET_USER}")
U2F_DIR="${TARGET_HOME}/.config/Yubico"
U2F_KEYS_FILE="${U2F_DIR}/u2f_keys"

# Check for the enrollment tool
if ! command -v pamu2fcfg >/dev/null 2>&1; then
  echo -e "${ERROR} ${RED}pamu2fcfg not found. Please install the pam-u2f package (e.g., 'pam-u2f' on Arch/Manjaro, 'libpam-u2f' on Debian/Ubuntu) and plug in your YubiKey.${NC}"
else
  # Create config directory and set permissions
  mkdir -p "${U2F_DIR}"
  chmod 700 "${U2F_DIR}"

  # Ensure the directory is owned by the target user so they can write their mapping
  chown "${TARGET_USER}":"${TARGET_USER}" "${U2F_DIR}" 2>/dev/null || true

  # Backup existing keys file if present
  if [ -f "${U2F_KEYS_FILE}" ]; then
    cp -f "${U2F_KEYS_FILE}" "${U2F_KEYS_FILE}.bak"
    echo -e "${INFO} ${YELLOW}Existing U2F file backed up: ${U2F_KEYS_FILE}.bak${NC}"
  fi

  # Generate mapping for the primary key
  echo -e "${INFO} Touch your YubiKey when the LED blinks to complete registration..."
  if sudo -u "${TARGET_USER}" pamu2fcfg | sudo -u "${TARGET_USER}" tee "${U2F_KEYS_FILE}" >/dev/null; then
    chmod 600 "${U2F_KEYS_FILE}"
    echo -e "${INFO} ${GREEN}U2F key mapping created: ${U2F_KEYS_FILE}${NC}"

    # Optional: enroll a backup key if present (non-fatal on failure)
    if sudo -u "${TARGET_USER}" pamu2fcfg -n | sudo -u "${TARGET_USER}" tee -a "${U2F_KEYS_FILE}" >/dev/null 2>&1; then
      echo -e "${INFO} ${GREEN}Second/backup YubiKey added.${NC}"
    else
      echo -e "${INFO} ${YELLOW}No second key added (optional).${NC}"
    fi
  else
    echo -e "${ERROR} ${RED}Registration failed. Make sure a YubiKey is connected and try again.${NC}"
  fi
fi

# Test sudo configuration and log output
echo -e "${INFO} ${YELLOW}Testing sudo configuration...${NC}"
if [ -d "$HOME/.dotfiles/scripts" ]; then
  bash "$HOME/.dotfiles/scripts/sudo_diag.sh" | tee ~/sudo_diag.log
else
  echo "sudo_diag.sh not found in ~/.dotfiles/scripts; skipping diagnostic." | tee ~/sudo_diag.log
fi
echo -e "${INFO} ${GREEN}Sudo configuration test completed. Log saved to ~/sudo_diag.log.${NC}"
# Note: If you encounter issues with sudo after this change, you can remove the last line from /etc/pam.d/sudo using:
# sudo sed -i '$ d' /etc/pam.d/sudo
##################################
# END: YubiKey-PAM Configuration #
##################################