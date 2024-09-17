#!/bin/sh -e

. ../../common-script.sh

configureDNF() {
    case $PACKAGER in
        dnf)
            $ESCALATION_TOOL sed -i '/^max_parallel_downloads=/c\max_parallel_downloads=10' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf
            echo "fastestmirror=True" | $ESCALATION_TOOL tee -a /etc/dnf/dnf.conf > /dev/null
            echo "defaultyes=True" | $ESCALATION_TOOL tee -a /etc/dnf/dnf.conf > /dev/null
            
            $ESCALATION_TOOL "$PACKAGER" -y install dnf-plugins-core
            ;;
        *)
            echo "Unsupported distribution: $DTYPE"
            ;;
    esac
}

checkEnv
configureDNF
