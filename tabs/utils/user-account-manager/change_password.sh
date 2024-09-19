#!/bin/sh -e

. ../../common-script.sh
. ./utility_functions.sh

clear
printf "%b\n" "${YELLOW}Change password${RC}"
printf "%b\n" "${YELLOW}=================${RC}"

username=$(promptUsername "" "root") || exit 1
password=$(promptPassword) || exit 1

printf "Are you sure you want to change password for $username? [Y/N]: "
read -r confirm
confirmAction || exit 1

echo "$username:$password" | $ESCALATION_TOOL chpasswd
printf "%b\n" "${GREEN}Password changed successfully${RC}"

checkEnv