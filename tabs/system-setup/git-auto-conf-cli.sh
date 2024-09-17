#!/bin/sh -e

# Import common utilities
. ../common-script.sh

# Function to prompt for GitHub configuration
setup_git_config() {
    printf "Enter your email address: "
    read email

    # Prompt for SSH key type
    echo "Choose your SSH key type:"
    echo "1. Ed25519 (recommended)"
    echo "2. RSA (legacy)"
    printf "Enter your choice (1 or 2): "
    read key_type

    # Set key algorithm based on user choice
    case "$key_type" in
        1) key_algo="ed25519" ;;
        2) key_algo="rsa" ;;
        *)
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac

    # Prompt for custom key name
    printf "Enter a custom SSH key name (leave blank for default): "
    read key_name

    # Set the SSH key path based on user input
    ssh_key_path="${HOME}/.ssh/${key_name:-id_$key_algo}"

    # Generate SSH key with specified type and email
    ssh-keygen -t "$key_algo" -C "$email" -f "$ssh_key_path"

    # Prompt for passphrase usage
    printf "Do you want to use a passphrase? (Y/n): "
    read use_passphrase
    
    case "$use_passphrase" in
        n|N)
            echo "Skipping passphrase setup."
            ;;
        *)
            ssh-add -l >/dev/null 2>&1 || eval "$(ssh-agent -s)"
            ssh-add "$ssh_key_path"
            ;;
    esac

    echo "SSH key generation and setup completed."
}

# Function to copy the SSH key to the clipboard and prompt user to add it to GitHub
copy_and_confirm_ssh_key() {
    # Check if xclip is installed
    checkCommandRequirements "xclip"

    # Copy the generated public key to the clipboard using xclip
    if command -v xclip >/dev/null 2>&1; then
        cat "${ssh_key_path}.pub" | xclip -selection clipboard
        echo "Your SSH public key has been copied to the clipboard."
    else
        echo "xclip not found. Please manually copy the SSH key."
        cat "${ssh_key_path}.pub"
    fi

    # Prompt user to confirm they've added the key to GitHub
    while true; do
        printf "Have you pasted your SSH public key into your GitHub account? (y/n): "
        read yn
        case "$yn" in
            [Yy]* ) echo "Proceeding..."; break ;;
            [Nn]* ) echo "Please paste your SSH public key into GitHub and try again."; exit ;;
            * ) echo "Please answer yes (y) or no (n)." ;;
        esac
    done

    # Test the SSH connection with GitHub
    ssh -T git@github.com
}

# Main execution
checkEnv
setup_git_config
copy_and_confirm_ssh_key
