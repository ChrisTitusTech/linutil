#!/bin/bash
# Setup KDE Wallet for automatic unlocking and using PAM
set -Eeuo pipefail
# Logging helpers with color fallbacks
: "${INFO:=[INFO]}"
: "${WARN:=[WARN]}"
: "${OK:=[OK]}"
: "${YELLOW:=}"
: "${GREEN:=}"
: "${RED:=}"
: "${NC:=}"
log_info() { echo "${INFO} ${YELLOW}$*${NC}"; }
log_ok()   { echo "${OK} ${GREEN}$*${NC}"; }
log_warn() { echo "${WARN} ${RED}$*${NC}"; }
# Check for required commands
if ! command -v kwriteconfig5 >/dev/null 2>&1; then
    log_warn "kwriteconfig5 not found. This script requires KDE Plasma."
    exit 1
fi
if ! command -v kreadconfig5 >/dev/null 2>&1; then
    log_warn "kreadconfig5 not found. This script requires KDE Plasma."
    exit 1
fi
log_info "Setting up KDE Wallet for automatic unlocking with PAM..."
# Enable KDE Wallet subsystem
kwriteconfig5 --file kwalletrc --group 'Wallet' --key 'First Use' false
kwriteconfig5 --file kwalletrc --group 'Wallet' --key 'Enabled' true
# Set the default wallet to be unlocked at login
DEFAULT_WALLET=$(kreadconfig5 --file kwalletrc --group 'Wallet' --key 'Default Wallet' 'kdewallet')
if [ "$DEFAULT_WALLET" != "kdewallet" ]; then
    log_info "Setting default wallet to 'kde