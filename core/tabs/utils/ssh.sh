#!/bin/sh -e

. ../common-script.sh

# Check if ~/.ssh/config exists, if not, create it
if [ ! -f ~/.ssh/config ]; then
    mkdir -p "$HOME/.ssh"
    touch "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
fi

# Function to show available hosts from ~/.ssh/config
show_available_hosts() {
    printf "%b\n" "Available Systems:"
    grep -E "^Host " "$HOME/.ssh/config" | awk '{print $2}'
    printf "%b\n" "-------------------"
}

# Function to ask for host details
ask_for_host_details() {
    printf "%b" "Enter Host Alias: "
    read -r host_alias
    printf "%b" "Enter Remote Host (hostname or IP): " 
    read -r host
    printf "%b" "Enter Remote User: "
    read -r  user
    {
        printf "%b\n" "Host $host_alias"
        printf "%b\n" "    HostName $host"
        printf "%b\n" "    User $user"
        printf "%b\n" "    IdentityFile ~/.ssh/id_rsa"
        printf "%b\n" "    StrictHostKeyChecking no"
        printf "%b\n" "    UserKnownHostsFile=/dev/null"
    } >> ~/.ssh/config
    printf "%b\n" "Host $host_alias added successfully."
}

# Function to generate SSH key if not exists
generate_ssh_key() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        printf "%b\n" "SSH key not found, generating one..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "$(whoami)@$(hostname)"
    else
        printf "%b\n" "SSH key already exists."
    fi
}

# Function to share the SSH public key with the remote host
share_ssh_key() {
    printf "%b" "Enter the alias of the host to copy the key to: " 
    read -r host_alias
    printf "%b\n" "Copying SSH key to $host_alias..."
    ssh-copy-id "$host_alias"
    printf "%b\n" "SSH key copied to $host_alias successfully."
}

# Function to disable password authentication and allow only SSH keys
#repeated twice as changes should take place when in commented state or modified state.
disable_password_auth() {
    printf "%b\n" "Disabling SSH password authentication and enabling key-only login..."
    printf "%b\n" "Enter the alias of the host: " 
    read -r host_alias
    printf "\n"
    ssh "$host_alias" "
        "$ESCALATION_TOOL" -S sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S sed -i 's/^#PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S systemctl restart sshd
    "
    printf "%b\n" "PasswordAuthentication set to no and PubkeyAuthentication set to yes."
}

enable_password_auth() {
    printf "%b\n" "Disabling SSH password authentication and enabling key-only login..."
    printf "%b\n" "Enter the alias of the host: "
    read -r host_alias
    printf "\n"
    ssh "$host_alias" "
        "$ESCALATION_TOOL"  -S sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication no/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S sed -i 's/^PubkeyAuthentication yes/PubkeyAuthentication no/' /etc/ssh/sshd_config &&
        "$ESCALATION_TOOL"  -S systemctl restart sshd
    "
    printf "%b\n" "PasswordAuthentication set to yes and PubkeyAuthentication set to no."
}

# Function to check if password authentication is disabled
check_password_auth() {
    printf "%b" "Enter the alias of the host: "
    read -r host_alias
    ssh "$host_alias" "grep '^PasswordAuthentication' /etc/ssh/sshd_config"
}

# Function to run a command on a remote server
run_remote_command() {
    printf "%b" "Enter the alias of the host: " 
    read -r host_alias
    printf "%b" "Enter the command to run: " 
    read -r remote_command
    ssh "$host_alias" "$remote_command"
}

# Function to copy a file to a remote server
copy_file_to_remote() {
    printf "%b" "Enter the local file path: " 
    read -r local_file
    printf "%b" "Enter the alias of the host: " 
    read -r host_alias
    printf "%b" "Enter the remote destination path: "
    read -r remote_path
    scp "$local_file" "$host_alias:$remote_path"
}

# Function to copy a directory to a remote server
copy_directory_to_remote() {
    printf "%b" "Enter the local directory path: "
    read -r  local_dir
    printf "%b" "Enter the alias of the host: " 
    read -r host_alias
    printf "%b" "Enter the remote destination path: "
    read -r remote_path
    scp -r "$local_dir" "$host_alias:$remote_path"
}


# Function to move a file to a remote server (copy and delete local)
move_file_to_remote() {
    printf "%b" "Enter the local file path: "
    read -r local_file
    printf "%b" "Enter the alias of the host: "
    read -r host_alias
    printf "%b" "Enter the remote destination path: " 
    read -r remote_path
    scp "$local_file" "$host_alias:$remote_path" && rm "$local_file"
}

# Function to move a directory to a remote server (copy and delete local)
move_directory_to_remote() {
    printf "%b" "Enter the local directory path: " 
    read -r local_dir
    printf "%b" "Enter the alias of the host: " 
    read -r host_alias
    printf "%b" "Enter the remote destination path: "
    read -r remote_path
    scp -r "$local_dir" "$host_alias:$remote_path" && rm -r "$local_dir"
}

# Function to remove a system from SSH configuration
remove_system() {
    printf "%b\n" "Enter the alias of the host to remove: "
    read -r host_alias
    sed -i "/^Host $host_alias/,+3d" ~/.ssh/config
    printf "%b\n" "Removed $host_alias from SSH configuration."
}

# Function to view SSH configuration
view_ssh_config() {
    printf "%b\n" "Enter the alias of the host to view (or press Enter to view all): "
    read -r  host_alias
    if [ -z "$host_alias" ]; then
        cat ~/.ssh/config
    else
        grep -A 3 "^Host $host_alias" ~/.ssh/config
    fi
}

# Function to backup files from remote host
backup_files() {
    printf "%b\n" "Enter the alias of the host: "
    read -r host_alias
    printf "%b\n" "Enter the files or directories to backup on remote host: "
    read -r remote_files
    printf "%b\n" "Enter the local backup directory path: "
    read -r local_backup_dir
    scp -r "$host_alias:$remote_files" "$local_backup_dir"
}

# Function to sync directories with remote host
sync_directories() {
    printf "%b" "Enter the local directory path: " 
    read -r local_dir
    printf "%b" "Enter the alias of the host: " 
    read -r host_alias
    printf "%b" "Enter the remote directory path: " 
    read -r remote_dir
    rsync -avz "$local_dir" "$host_alias:$remote_dir"
}

# Function to check SSH key authentication status
check_ssh_key_authentication() {
    printf "%b\n" "Enter the alias of the host: "
    read -r host_alias
    ssh "$host_alias" "grep '^PubkeyAuthentication' /etc/ssh/sshd_config"
}

# Function to show options for the user
show_menu() {
    printf "%b\n" "Select an SSH operation:"
    printf "%b\n" "1. Add a new system"
    printf "%b\n" "2. Connect to a system"
    printf "%b\n" "3. Generate SSH key"
    printf "%b\n" "4. Share SSH key with remote host"
    printf "%b\n" "5. Disable password authentication on remote host"
    printf "%b\n" "6. Enable password authentication on remote host"
    printf "%b\n" "7. Check password authentication on remote host"
    printf "%b\n" "8. Check SSH key authentication status"
    printf "%b\n" "9. Run a command on remote host"
    printf "%b\n" "10. Copy a file to remote host"
    printf "%b\n" "11. Copy a directory to remote host"
    printf "%b\n" "12. Move a file to remote host (copy and delete local)"
    printf "%b\n" "13. Move a directory to remote host (copy and delete local)"
    printf "%b\n" "14. Remove a system from SSH configuration"
    printf "%b\n" "15. View SSH configuration"
    printf "%b\n" "16. Backup files from remote host"
    printf "%b\n" "17. Sync directories with remote host"
    printf "%b\n" "18. Exit"
    printf "%b" "Enter your choice: "
}

# Function to execute the selected SSH operation
main() {
    while true; do
    show_menu
    read -r choice
    case $choice in
        1) ask_for_host_details ;;
        2) show_available_hosts && printf "%b" "Enter the alias of the host to connect to: " && read -r  host_alias; ssh "$host_alias" ;;
        3) generate_ssh_key ;;
        4) share_ssh_key ;;
        5) disable_password_auth ;;
        6) enable_password_auth ;;
        7) check_password_auth ;;
        8) check_ssh_key_authentication ;;
        9) run_remote_command ;;
        10) copy_file_to_remote ;;
        11) copy_directory_to_remote ;;
        12) move_file_to_remote ;;
        13) move_directory_to_remote ;;
        14) remove_system ;;
        15) view_ssh_config ;;
        16) backup_files ;;
        17) sync_directories ;;
        18) exit ;;
        *) printf "%b\n" "Invalid choice. Please try again." ;;
    esac
done
}

checkEnv
checkEscalationTool
main