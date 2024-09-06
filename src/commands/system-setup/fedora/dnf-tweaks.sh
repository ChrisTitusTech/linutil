#!/bin/sh -e

. "$(dirname "$0")/../../common-script.sh"

DNFtweaks() {
    case $PACKAGER in
        dnf)
            # defaults the prompt to Yes instead  of No
             if grep -q "^defaultyes=" /etc/dnf/dnf.conf; then
                $ESCALATION_TOOL sed -i 's/^defaultyes=.*/defaultyes=True/' /etc/dnf/dnf.conf
            else
                $ESCALATION_TOOL echo "defaultyes=True" >> /etc/dnf/dnf.conf
            fi
            # sets the number of parallel downloads to 10
            if grep -q "^max_parallel_downloads=" /etc/dnf/dnf.conf ; then
               $ESCALATION_TOOL sed -i 's/^max_parallel_downloads=.*/max_parallel_downloads=10/' /etc/dnf/dnf.conf 
            else
                $ESCALATION_TOOL echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf 
            fi
            ;;
        *)
            echo "Unsupported distribution: $DTYPE"
            ;;
    esac
}

checkEnv
DNFtweaks