#!/bin/sh -e

. ../../common-script.sh
. ./utility_functions.sh

clear
printf "%b\n" "${YELLOW}Delete a user${RC}"
printf "%b\n" "${YELLOW}=================${RC}"

username=$(promptUsername "" "non-root") || exit 1

# Check if current user
if [ "$username" = "$USER" ]; then
    printf "%b\n" "${RED}Cannot delete the current user${RC}"
    printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
    read dummy
    return
fi

read -p "Are you sure you want to delete user $username? [Y/N]: " confirm
confirmAction || exit 1

$ESCALATION_TOOL userdel --remove "$username" 2>/dev/null
printf "%b\n" "${GREEN}User $username deleted successfully${RC}"

checkEnv