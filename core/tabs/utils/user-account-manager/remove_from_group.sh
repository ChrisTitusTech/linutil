#!/bin/sh -e

. ../../common-script.sh

. ../utility_functions.sh

removeFromGroup() {
    clear
    printf "%b\n" "${YELLOW}Remove from group${RC}"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the username: ${RC}"
    read -r username

    if ! id "$username" > /dev/null 2>&1; then
        printf "%b\n" "${RED}User $username does not exist.${RC}"
        exit 1
    fi

    user_groups=$(groups "$username" | cut -d: -f2 | sort | tr '\n' ' ')

    printf "%b\n" "${YELLOW}Groups user $username is in:${RC} $user_groups"
    printf "%b\n" "${YELLOW}=================${RC}"

    printf "%b" "${YELLOW}Enter the groups you want to remove user $username from (space-separated): ${RC} "
    read -r groups

    checkEmpty "$groups" || exit 1
    if ! checkGroups "$groups" "$user_groups"; then
        printf "%b\n" "${RED}One or more specified groups do not exist.${RC}"
        exit 1
    fi

    groups_to_remove=$(echo "$groups" | tr ' ' ',')

    printf "%b" "${YELLOW}Are you sure you want to remove user $username from $groups_to_remove? [Y/n]: ${RC}"
    read -r _
    confirmAction || exit 1

    $ESCALATION_TOOL usermod -rG "$groups_to_remove" "$username"

    printf "%b\n" "${GREEN}User successfully removed from $groups_to_remove${RC}"
}

checkEnv
checkEscalationTool
removeFromGroup
