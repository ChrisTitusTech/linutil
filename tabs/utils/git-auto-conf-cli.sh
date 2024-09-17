#!/bin/sh -e

# Import common utilities
. ../common-script.sh

# Install Git if it's not already present
installGit() {
    if ! command_exists git; then
        printf "Git is not installed. Installing it now...\n"

        case $PACKAGER in
            pacman|xbps-install)
                $ESCALATION_TOOL "$PACKAGER" -S --needed --noconfirm git
                ;;
            apt-get|nala|dnf|zypper)
                $ESCALATION_TOOL "$PACKAGER" install -y git
                ;;
            nix-env)
                nix-env -iA nixpkgs.git
                ;;
            *)
                printf "${RED}Git installation not supported for this package manager${RC}\n"
                exit 1
                ;;
        esac

        printf "${GREEN}Git installed successfully.${RC}\n"
    else
        printf "Git is already installed.\n"
    fi
}

# Function to prompt for GitHub configuration
setup_git_config() {
    # Prompt for GitHub email
    printf "Enter your GitHub email address: "
    read -r email

    # Prompt for SSH key type
    printf "Choose your SSH key type:\n"
    printf "1. Ed25519 (recommended)\n"
    printf "2. RSA (legacy)\n"
    printf "Enter your choice (1 or 2): "
    read -r key_type

    # Set key algorithm based on user choice
    case "$key_type" in
        1) key_algo="ed25519" ;;
        2) key_algo="rsa" ;;
        *)
            printf "Invalid choice. Exiting.\n"
            exit 1
            ;;
    esac

    # Prompt for custom key name
    printf "Enter a custom SSH key name (leave blank for default): "
    read -r key_name

    # Set the SSH key path based on user input
    ssh_key_path="${HOME}/.ssh/${key_name:-id_$key_algo}"

    # Generate SSH key with specified type and email
    ssh-keygen -t "$key_algo" -C "$email" -f "$ssh_key_path"

    # Prompt for passphrase usage
    printf "Do you want to use a passphrase? (y/n): "
    read -r use_passphrase

    # If user opts for a passphrase, add key to SSH agent
    if [ "$use_passphrase" = "y" ]; then
        if ! ssh-add -l >/dev/null 2>&1; then
            eval "$(ssh-agent -s)"
        fi
        ssh-add "$ssh_key_path"
    else
        printf "Skipping passphrase setup.\n"
    fi

    printf "SSH key generation and setup completed.\n"
    printf "Please copy the SSH key and add it to your GitHub account.\n"
    printf "Then run this command to verify the SSH connection:\n"
    printf "ssh -T git@github.com\n"
}

# Main execution
checkEnv
installGit
setup_git_config
