#!/bin/sh -e

. ../../common-script.sh

checkGroups() {
    groups="$1"
    available_groups="$2"
    for group in $groups; do
        if ! echo "$available_groups" | grep -q -w "$group"; then
            return 1
        fi
    done
    return 0
}

confirmAction() {
    confirm="$1"
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        printf "%b\n" "${RED}Cancelled operation...${RC}" >&2
        exit 1
    fi
}

checkEmpty() {
    if [ -z "$1" ]; then
        printf "%b\n" "${RED}Empty value is not allowed${RC}" >&2
        exit 1
    fi
}

checkEnv
