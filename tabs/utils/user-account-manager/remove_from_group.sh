#!/bin/sh -e

. ../../common-script.sh
. ./utility_functions.sh

clear
printf "%b\n" "${YELLOW}Remove from group${RC}"
printf "%b\n" "${YELLOW}=================${RC}"

username=$(promptUsername "" "non-root") || exit 1
user_groups=$(groups "$username" | cut -d: -f2 | sort | tr '\n' ' ')

printf "%b\n" "${YELLOW}Groups user $username is in:${RC} $user_groups"
printf "%b\n" "${YELLOW}=================${RC}"

read -p "Enter the groups you want to remove user from $username (space-separated): " groups

checkEmpty "$groups" || exit 1
checkGroupAvailabe "$groups" "$user_groups" || exit 1

groups_to_remove=$(echo "$groups" | tr ' ' ',')

printf "Are you sure you want to remove user $username from $groups_to_remove? [Y/N]: "
read -r confirm
confirmAction || exit 1

$ESCALATION_TOOL usermod -rG $groups_to_remove "$username"

printf "%b\n" "${GREEN}User successfully removed from $groups_to_remove${RC}"

checkEnv