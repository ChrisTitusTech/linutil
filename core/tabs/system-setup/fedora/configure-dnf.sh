#!/bin/sh -e

. ../../common-script.sh

configureDNF() {
    case "$PACKAGER" in
        dnf)
            printf "%b\n" "${YELLOW}Configuring  DNF...${RC}"
            elevated_execution sed -i '/^max_parallel_downloads=/c\max_parallel_downloads=10' /etc/dnf/dnf.conf || echo 'max_parallel_downloads=10' >> /etc/dnf/dnf.conf
            echo "fastestmirror=True" | elevated_execution tee -a /etc/dnf/dnf.conf > /dev/null
            echo "defaultyes=True" | elevated_execution tee -a /etc/dnf/dnf.conf > /dev/null            
            elevated_execution "$PACKAGER" -y install dnf-plugins-core
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
