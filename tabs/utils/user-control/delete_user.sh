#!/bin/sh -e

. ./utility_functions.sh

printf "%b\n" "${YELLOW}Delete a user${RC}"
printf "%b\n" "${YELLOW}=================${RC}"
read -p "Enter the username: " username

# Check if username is empty
if ! checkEmpty "$username"; then return; fi

# Check if valid user
if ! id "$username" > /dev/null 2>&1; then
    printf "%b\n" "${RED}User does not exist${RC}"
    printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
    read dummy
    return
fi

checkReservedUsername "$username" "user"

# Check if current user
if [ "$username" = "$USER" ]; then
    printf "%b\n" "${RED}Cannot delete the current user${RC}"
    printf "%b\n" "${RED}Press [Enter] to continue...${RC}"
    read dummy
    return
fi

read -p "Are you sure you want to delete user $username? [Y/N]: " confirm
confirmAction

$ESCALATION_TOOL userdel --remove "$username" 2>/dev/null
printf "%b\n" "${GREEN}User $username deleted successfully${RC}"
printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
read dummy
