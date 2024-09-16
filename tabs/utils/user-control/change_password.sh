printf "%b\n" "${YELLOW}Change password${RC}"
printf "%b\n" "${YELLOW}=================${RC}"

password=$(promptPassword)

read -p "Are you sure you want to change password for $username? [Y/N]: " confirm
confirmAction

echo "$1:$password" | $ESCALATION_TOOL chpasswd
printf "%b\n" "${GREEN}Password changed successfully${RC}"
printf "%b\n" "${GREEN}Press [Enter] to continue...${RC}"
read dummy
