#!/bin/sh -e

. ../common-script.sh

installTailscale() {
    if command_exists tailscale; then
        printf "%b\n" "${GREEN}Tailscale is already installed.${RC}"
        return 0
    fi

    printf "%b\n" "${YELLOW}Installing Tailscale VPN...${RC}"
    
    # Use official Tailscale installation script
    if ! curl -fsSL https://tailscale.com/install.sh | sh; then
        printf "%b\n" "${RED}Failed to install Tailscale!${RC}"
        exit 1
    fi
    
    printf "%b\n" "${GREEN}Tailscale installed successfully.${RC}"
}

enableTailscale() {
    printf "%b\n" "${YELLOW}Enabling Tailscale service...${RC}"
    
    if command_exists systemctl; then
        "$ESCALATION_TOOL" systemctl enable --now tailscaled || {
            printf "%b\n" "${YELLOW}Could not enable Tailscale service automatically.${RC}"
            return 1
        }
        printf "%b\n" "${GREEN}Tailscale service enabled.${RC}"
    else
        printf "%b\n" "${YELLOW}systemctl not found. Please enable Tailscale manually.${RC}"
    fi
}

connectTailscale() {
    printf "%b\n" "${CYAN}To connect to Tailscale, run: ${YELLOW}tailscale up${RC}"
    printf "%b\n" "${CYAN}To check status, run: ${YELLOW}tailscale status${RC}"
    
    printf "%b" "${GREEN}Would you like to connect to Tailscale now? [y/N]: ${RC}"
    read -r response
    
    if [ "$response" = "y" ] || [ "$response" = "Y" ]; then
        "$ESCALATION_TOOL" tailscale up
    else
        printf "%b\n" "${YELLOW}You can connect later by running: ${CYAN}sudo tailscale up${RC}"
    fi
}

checkEnv
checkEscalationTool
installTailscale
enableTailscale
connectTailscale
