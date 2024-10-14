#!/bin/sh -e

. ../../common-script.sh

# Install virtualization tools to enable virtual machines
configureVirtualization() {
    case "$PACKAGER" in
        dnf)
            printf "%b\n" "${YELLOW}Installing virtualization tools...${RC}"
            elevated_execution "$PACKAGER" install -y @virtualization 
            printf "%b\n" "${GREEN}Installed virtualization tools...${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Unsupported distribution: $DTYPE${RC}"
            ;;
    esac
}

checkEnv
checkEscalationTool
configureVirtualization
