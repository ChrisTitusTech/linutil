#!/bin/sh -e

. ../common-script.sh

removeSnaps() {
    case $PACKAGER in
        pacman)
            sudo ${PACKAGER} -Rns snapd
            ;;
        apt-get|nala)
            sudo ${PACKAGER} autoremove --purge snapd
            if [ "$ID" = ubuntu ]; then
                sudo apt-mark hold snapd
            fi
            ;;
        dnf)
            sudo ${PACKAGER} remove snapd
            ;;
        zypper)
            sudo ${PACKAGER} remove snapd
            ;;
        *)
            echo "removing snapd not implemented for this package manager"
    esac
}

checkEnv
removeSnaps
