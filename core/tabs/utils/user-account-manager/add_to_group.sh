#!/bin/sh -e

. ../../common-script.sh
. ./utility_functions.sh

clear
printf "%b\n" "${YELLOW}Add to group${RC}"
printf "%b\n" "${YELLOW}=================${RC}"

username=$(promptUsername "" "non-root") || exit 1
user_groups=$(groups "$username" | cut -d: -f2 | sort | tr '\n' ' ')

printf "%b\n" "${YELLOW}Groups user $username is in:${RC} $user_groups"
printf "%b\n" "${YELLOW}=================${RC}"

available_groups=$(cut -d: -f1 /etc/group | sort | tr '\n' ' ')

printf "%b\n" "${YELLOW}Available groups:${RC} $available_groups"
printf "%b\n" "${YELLOW}=================${RC}"

printf "%b\n" "${YELLOW}Enter the groups you want to add user $username to (space-separated):${RC} "
read -r groups

checkEmpty "$groups" || exit 1
checkGroupAvailabe "$groups" "$available_groups" || exit 1

groups_to_add=$(echo "$groups" | tr ' ' ',')

printf "Are you sure you want to add user $username to $groups_to_add? [Y/N]: "
read -r confirm
confirmAction || exit 1

$ESCALATION_TOOL usermod -aG $groups_to_add "$username"

printf "%b\n" "${GREEN}User successfully added to the $groups_to_add${RC}"

checkEnv