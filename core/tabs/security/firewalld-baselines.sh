#!/bin/sh -e

. ../common-script.sh

configureFirewallD() {
    printf "%b\n" "${YELLOW}Configuring FirewallD with recommended rules${RC}"

    printf "%b\n" "${YELLOW}Setting default zone to public (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --set-default-zone=public

    printf "%b\n" "${YELLOW}Allowing SSH service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=ssh

    printf "%b\n" "${YELLOW}Allowing HTTP service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=http

    printf "%b\n" "${YELLOW}Allowing HTTPS service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=https

    printf "%b\n" "${YELLOW}Reloading FirewallD configuration${RC}"
    "$ESCALATION_TOOL" firewall-cmd --reload

    printf "%b\n" "${GREEN}Enabled FirewallD with Baselines!${RC}"
}

checkEnv
checkEscalationTool
configureFirewallD
