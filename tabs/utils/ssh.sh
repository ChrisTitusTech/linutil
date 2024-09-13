#!/bin/sh -e

. ../common-script.sh

# Check if ~/.ssh/config exists, if not, create it
if [ ! -f ~/.ssh/config ]; then
    touch ~/.ssh/config
    chmod 600 ~/.ssh/config
fi

# Function to show available hosts from ~/.ssh/config
show_available_hosts() {
    echo "Available Systems:"
    grep -E "^Host " ~/.ssh/config | awk '{print $2}'
    echo "-------------------"
}

# Function to ask for host details
ask_for_host_details() {
    read -p "Enter Host Alias: " host_alias
    read -p "Enter Remote Host (hostname or IP): " host
    read -p "Enter Remote User: " user
    printf "%b\n" "Host $host_alias" >> ~/.ssh/config
    echo "    HostName $host" >> ~/.ssh/config
    echo "    User $user" >> ~/.ssh/config
    echo "    IdentityFile ~/.ssh/id_rsa" >> ~/.ssh/config
    echo "    StrictHostKeyChecking no" >> ~/.ssh/config
    echo "    UserKnownHostsFile=/dev/null" >> ~/.ssh/config
    echo "Host $host_alias added successfully."
}

# Function to generate SSH key if not exists
generate_ssh_key() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "SSH key not found, generating one..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" -C "$(whoami)@$(hostname)"
    else
        echo "SSH key already exists."
    fi
}

# Function to share the SSH public key with the remote host
share_ssh_key() {
    read -p "Enter the alias of the host to copy the key to: " host_alias
    echo "Copying SSH key to $host_alias..."
    ssh-copy-id "$host_alias"
    echo "SSH key copied to $host_alias successfully."
}

# Function to disable password authentication and allow only SSH keys
#repeated twice as changes should take place when in commented state or modified state.
disable_password_auth() {
    echo "Disabling SSH password authentication and enabling key-only login..."
    read -p "Enter the alias of the host: " host_alias
    echo
    ssh $host_alias "
        $ESCALATION_TOOL -S sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S sed -i 's/^#PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S sed -i 's/^PubkeyAuthentication no/PubkeyAuthentication yes/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S systemctl restart sshd
    "
    echo "PasswordAuthentication set to no and PubkeyAuthentication set to yes."
}

enable_password_auth() {
    echo "Disabling SSH password authentication and enabling key-only login..."
    read -p "Enter the alias of the host: " host_alias
    echo
    ssh $host_alias "
        $ESCALATION_TOOL  -S sed -i 's/^#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication no/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S sed -i 's/^PubkeyAuthentication yes/PubkeyAuthentication no/' /etc/ssh/sshd_config &&
        $ESCALATION_TOOL  -S systemctl restart sshd
    "
    echo "PasswordAuthentication set to yes and PubkeyAuthentication set to no."
}

# Function to check if password authentication is disabled
check_password_auth() {
    read -p "Enter the alias of the host: " host_alias
    ssh $host_alias "grep '^PasswordAuthentication' /etc/ssh/sshd_config"
}

# Function to run a command on a remote server
run_remote_command() {
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the command to run: " remote_command
    ssh $host_alias "$remote_command"
}

# Function to copy a file to a remote server
copy_file_to_remote() {
    read -p "Enter the local file path: " local_file
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the remote destination path: " remote_path
    scp $local_file $host_alias:$remote_path
}

# Function to copy a directory to a remote server
copy_directory_to_remote() {
    read -p "Enter the local directory path: " local_dir
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the remote destination path: " remote_path
    scp -r $local_dir $host_alias:$remote_path
}


# Function to move a file to a remote server (copy and delete local)
move_file_to_remote() {
    read -p "Enter the local file path: " local_file
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the remote destination path: " remote_path
    scp $local_file $host_alias:$remote_path && rm $local_file
}

# Function to move a directory to a remote server (copy and delete local)
move_directory_to_remote() {
    read -p "Enter the local directory path: " local_dir
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the remote destination path: " remote_path
    scp -r $local_dir $host_alias:$remote_path && rm -r $local_dir
}

# Function to remove a system from SSH configuration
remove_system() {
    read -p "Enter the alias of the host to remove: " host_alias
    sed -i "/^Host $host_alias/,+3d" ~/.ssh/config
    echo "Removed $host_alias from SSH configuration."
}

# Function to view SSH configuration
view_ssh_config() {
    read -p "Enter the alias of the host to view (or press Enter to view all): " host_alias
    if [ -z "$host_alias" ]; then
        cat ~/.ssh/config
    else
        grep -A 3 "^Host $host_alias" ~/.ssh/config
    fi
}

# Function to backup files from remote host
backup_files() {
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the files or directories to backup on remote host: " remote_files
    read -p "Enter the local backup directory path: " local_backup_dir
    scp -r $host_alias:$remote_files $local_backup_dir
}

# Function to sync directories with remote host
sync_directories() {
    read -p "Enter the local directory path: " local_dir
    read -p "Enter the alias of the host: " host_alias
    read -p "Enter the remote directory path: " remote_dir
    rsync -avz $local_dir $host_alias:$remote_dir
}

# Function to check SSH key authentication status
check_ssh_key_authentication() {
    read -p "Enter the alias of the host: " host_alias
    ssh $host_alias "grep '^PubkeyAuthentication' /etc/ssh/sshd_config"
}

# Function to show options for the user
show_menu() {
    echo "Select an SSH operation:"
    echo "1. Add a new system"
    echo "2. Connect to a system"
    echo "3. Generate SSH key"
    echo "4. Share SSH key with remote host"
    echo "5. Disable password authentication on remote host"
    echo "6. Enable password authentication on remote host"
    echo "7. Check password authentication on remote host"
    echo "8. Check SSH key authentication status"
    echo "9. Run a command on remote host"
    echo "10. Copy a file to remote host"
    echo "11. Copy a directory to remote host"
    echo "12. Move a file to remote host (copy and delete local)"
    echo "13. Move a directory to remote host (copy and delete local)"
    echo "14. Remove a system from SSH configuration"
    echo "15. View SSH configuration"
    echo "16. Backup files from remote host"
    echo "17. Sync directories with remote host"
    echo "18. Exit"
    echo -n "Enter your choice: "
}

# Function to execute the selected SSH operation
main() {
    while true; do
    show_menu
    read choice
    case $choice in
        1) ask_for_host_details ;;
        2) show_available_hosts && read -p "Enter the alias of the host to connect to: " host_alias; ssh $host_alias ;;
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
        *) echo "Invalid choice. Please try again." ;;
    esac
done
}

checkEnv
checkEscalationTool
main