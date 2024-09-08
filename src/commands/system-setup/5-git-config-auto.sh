#!/bin/sh -e

# Import common utilities
. ./common-script.sh

# Function to prompt for GitHub configuration
setup_git_config() {
    # Prompt for GitHub email
    read -p "Enter your GitHub email address: " email

    # Prompt for SSH key type
    echo "Choose your SSH key type:"
    echo "1. Ed25519 (recommended)"
    echo "2. RSA (legacy)"
    read -p "Enter your choice (1 or 2): " key_type

    # Set key algorithm based on user choice
    case $key_type in
        1) key_algo="ed25519" ;;
        2) key_algo="rsa" ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    # Prompt for custom key name
    read -p "Enter a custom SSH key name (leave blank for default): " key_name

    # Set the SSH key path based on user input
    ssh_key_path="${HOME}/.ssh/${key_name:-id_$key_algo}"

    # Generate SSH key with specified type and email
    ssh-keygen -t "$key_algo" -C "$email" -f "$ssh_key_path"

    # Prompt for passphrase usage
    read -p "Do you want to use a passphrase? (y/n): " use_passphrase

    # If user opts for a passphrase, add key to SSH agent
    if [ "$use_passphrase" = "y" ]; then
        ssh-add -l &>/dev/null || eval "$(ssh-agent -s)"
        ssh-add "$ssh_key_path"
    else
        echo "Skipping passphrase setup."
    fi

    echo "SSH key generation and setup completed."
}

# Function to copy the SSH key to the clipboard and prompt user to add it to GitHub
copy_and_confirm_ssh_key() {
    # Check if xclip is installed
    checkCommandRequirements "xclip"

    # Copy the generated public key to the clipboard using xclip
    cat "${ssh_key_path}.pub" | xclip -selection clipboard
    echo "Your SSH public key has been copied to the clipboard."

    # Prompt user to confirm they've added the key to GitHub
    while true; do
        read -p "Have you pasted your SSH public key into your GitHub account? (y/n): " yn
        case $yn in
            [Yy]* ) echo "Proceeding..."; break ;;
            [Nn]* ) echo "Please paste your SSH public key into GitHub and try again."; exit ;;
            * ) echo "Please answer yes (y) or no (n)." ;;
        esac
    done

    # Test the SSH connection with GitHub
    ssh -T git@github.com
}

# Check environment and necessary tools
checkEnv

# Main execution
setup_git_config
copy_and_confirm_ssh_key
