#!/bin/sh -e

# Import common utilities
. ../common-script.sh

# Function to prompt for GitHub configuration
setup_git_config() {
    # Prompt for GitHub email
    printf "Enter your GitHub email address: "
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
    printf "Do you want to use a passphrase? (y/n): "
    read use_passphrase

    # If user opts for a passphrase, add key to SSH agent
    if [ "$use_passphrase" = "y" ]; then
        ssh-add -l >/dev/null 2>&1 || eval "$(ssh-agent -s)"
        ssh-add "$ssh_key_path"
    else
        echo "Skipping passphrase setup."
    fi
    echo "SSH key generation and setup completed.\nPlease copy the key from your ssh dir and paste it to your corresponding account ssh key add section of your github settings page.\nThen run this command to verify ssh connection:\nssh -T git@github.com"
}

# Main execution
checkEnv
checkCommandRequirements "git"
setup_git_config
