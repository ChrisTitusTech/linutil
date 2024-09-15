#!/bin/sh -e

. ../../common-script.sh

# Install virtualization tools to enable virtual machines
configureVirtualization() {
    case $PACKAGER in
        dnf)
            echo "Installing virtualization tools..."
            $ESCALATION_TOOL "$PACKAGER" install -y @virtualization 
            echo "Installed virtualization tools..."
            ;;
        *)
            echo "Unsupported distribution: $DTYPE"
            ;;
    esac
}

checkEnv () {
    checkEscalationTool
 }

configureVirtualization
