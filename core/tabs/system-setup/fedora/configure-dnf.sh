#!/bin/sh -e

. ../../common-script.sh

configureDNF() {
    case "$PACKAGER" in
        dnf)
            printf "%b\n" "${YELLOW}Configuring  DNF...${RC}"
            "$ESCALATION_TOOL" sed -i '/^max_parallel_downloads=/c\max_parallel_downloads=10' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf
            echo "fastestmirror=True" | "$ESCALATION_TOOL" tee -a /etc/dnf/dnf.conf > /dev/null
            echo "defaultyes=True" | "$ESCALATION_TOOL" tee -a /etc/dnf/dnf.conf > /dev/null            
            "$ESCALATION_TOOL" "$PACKAGER" -y install dnf-plugins-core
            printf "%b\n" "${GREEN}DNF Configured Successfully.${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
configureDNF
