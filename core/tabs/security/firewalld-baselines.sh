#!/bin/sh -e

. ../common-script.sh

configureFirewallD() {
    printf "%b\n" "${YELLOW}Configuring FirewallD with recommended rules${RC}"

    printf "%b\n" "${YELLOW}Setting default zone to public (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --set-default-zone=public

    printf "%b\n" "${YELLOW}Allowing SSH service (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --add-service=ssh

    printf "%b\n" "${YELLOW}Implementing SSH brute force protection (FirewallD)${RC}"
    "$ESCALATION_TOOL" firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT_direct 0 -p tcp --dport 22 \
        -m state --state NEW -m recent --set
    "$ESCALATION_TOOL" firewall-cmd --permanent --direct --add-rule ipv4 filter INPUT_direct 1 -p tcp --dport 22 \
        -m state --state NEW -m recent --update --seconds 30 --hitcount 6 \
        -j REJECT --reject-with tcp-reset
    "$ESCALATION_TOOL" firewall-cmd --permanent --direct --add-rule ipv6 filter INPUT_direct 0 -p tcp --dport 22 \
        -m state --state NEW -m recent --set
    "$ESCALATION_TOOL" firewall-cmd --permanent --direct --add-rule ipv6 filter INPUT_direct 1 -p tcp --dport 22 \
        -m state --state NEW -m recent --update --seconds 30 --hitcount 6 \
        -j REJECT --reject-with tcp-reset

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
