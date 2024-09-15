#!/bin/sh -e

. ../common-script.sh

# Snapd is not a valid package on Arch.
removeSnaps() {
    case $PACKAGER in
        apt-get|nala)
            $ESCALATION_TOOL ${PACKAGER} autoremove --purge snapd
            if [ "$ID" = ubuntu ]; then
                $ESCALATION_TOOL apt-mark hold snapd
            fi
            ;;
        dnf)
            $ESCALATION_TOOL ${PACKAGER} remove snapd
            ;;
        zypper)
            $ESCALATION_TOOL ${PACKAGER} remove snapd
            ;;
        *)
            echo "Removing snapd is not implemented for this package manager"
            ;;
    esac
}

revertSnapRemoval() {
    echo "Reverting snapd removal..."
    case $PACKAGER in
        apt-get|nala)
            $ESCALATION_TOOL ${PACKAGER} install -y snapd
            ;;
        dnf)
            $ESCALATION_TOOL ${PACKAGER} install snapd
            ;;
        zypper)
            $ESCALATION_TOOL ${PACKAGER} install snapd
            ;;
        *)
            echo "Reverting snapd is not implemented for this package manager"
            ;;
    esac
}

run() {
    checkEnv
    checkEscalationTool
    removeSnaps
}

revert() {
    checkEnv
    checkEscalationTool
    revertSnapRemoval
}