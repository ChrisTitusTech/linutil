#!/bin/sh -e

. ../common-script.sh
# Function to display the menu
printf "%b\n" "${YELLOW}Ensuring OpenSSL is installed...${RC}"

# Install OpenSSL
if ! command_exists openssl; then
    case $PACKAGER in
        pacman)
            $ESCALATION_TOOL ${PACKAGER} -Syu --noconfirm openssl
            ;;
        apt-get)
            $ESCALATION_TOOL ${PACKAGER} update && $ESCALATION_TOOL ${PACKAGER} install -y openssl
            ;;
        dnf)
            $ESCALATION_TOOL ${PACKAGER} install -y openssl
            ;;
        zypper)
            $ESCALATION_TOOL ${PACKAGER} install openssl
            ;;
        *)
            printf "%b\n" "${RED}Your Linux distribution is not supported by this script.${RC}"
            printf "%b\n" "${YELLOW}You can try installing OpenSSL manually:${RC}"
            printf "1. Refer to your distribution's documentation.\n"
            ;;
    esac
fi

show_menu() {
    printf "========================================================\n"
    printf " File/Directory Encryption/Decryption\n"
    printf "========================================================\n"
    printf "How to use:-\n"
    printf "if you encrypt or decrypt a file include new file name for successful operation\n"
    printf "if you encrypt or decrypt a folder include new directory name for successful operation\n"
    printf "========================================================\n"
    printf "1. Encrypt a file or directory\n"
    printf "2. Decrypt a file or directory\n"
    printf "3. Exit\n"
    printf "========================================================\n"
}

# Function to encrypt a file
encrypt_file() {
    printf "Enter the path to the file or directory to encrypt:\n"
    read -r INPUT_PATH

    if [ ! -e "$INPUT_PATH" ]; then
        printf "Path does not exist!\n"
        return
    fi

    printf "Enter the path for the encrypted file or directory:\n"
    read -r OUTPUT_PATH

    printf "Enter the encryption password:\n"
    read -s -r PASSWORD

    if [ -d "$INPUT_PATH" ]; then
        # Encrypt each file in the directory
        find "$INPUT_PATH" -type f | while read -r FILE; do
            REL_PATH="${FILE#$INPUT_PATH/}"
            OUTPUT_FILE="$OUTPUT_PATH/$REL_PATH.enc"
            mkdir -p "$(dirname "$OUTPUT_FILE")"
            openssl enc -aes-256-cbc -salt -pbkdf2 -in "$FILE" -out "$OUTPUT_FILE" -k "$PASSWORD"
            if [ $? -eq 0 ]; then
                printf "Encrypted: %s\n" "$OUTPUT_FILE"
            else
                printf "Failed to encrypt: %s\n" "$FILE"
            fi
        done
    else
        # Encrypt a single file
        if [ -d "$OUTPUT_PATH" ]; then
            printf "Output path must be a file for single file encryption.\n"
            return
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")"
        openssl enc -aes-256-cbc -salt -pbkdf2 -in "$INPUT_PATH" -out "$OUTPUT_PATH" -k "$PASSWORD"
        if [ $? -eq 0 ]; then
            printf "Encrypted: %s\n" "$OUTPUT_PATH"
        else
            printf "Failed to encrypt: %s\n" "$INPUT_PATH"
        fi
    fi
}

# Function to decrypt a file
decrypt_file() {
    printf "Enter the path to the file or directory to decrypt:\n"
    read -r INPUT_PATH

    if [ ! -e "$INPUT_PATH" ]; then
        printf "Path does not exist!\n"
        return
    fi

    printf "Enter the path for the decrypted file or directory:\n"
    read -r OUTPUT_PATH

    printf "Enter the decryption password:\n"
    read -s -r PASSWORD

    if [ -d "$INPUT_PATH" ]; then
        # Decrypt each file in the directory
        find "$INPUT_PATH" -type f -name '*.enc' | while read -r FILE; do
            REL_PATH="${FILE#$INPUT_PATH/}"
            OUTPUT_FILE="$OUTPUT_PATH/${REL_PATH%.enc}"
            mkdir -p "$(dirname "$OUTPUT_FILE")"
            openssl enc -aes-256-cbc -d -pbkdf2 -in "$FILE" -out "$OUTPUT_FILE" -k "$PASSWORD"
            if [ $? -eq 0 ]; then
                printf "Decrypted: %s\n" "$OUTPUT_FILE"
            else
                printf "Failed to decrypt: %s\n" "$FILE"
            fi
        done
    else
        # Decrypt a single file
        if [ -d "$OUTPUT_PATH" ]; then
            printf "Output path must be a file for single file decryption.\n"
            return
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")"
        openssl enc -aes-256-cbc -d -pbkdf2 -in "$INPUT_PATH" -out "$OUTPUT_PATH" -k "$PASSWORD"
        if [ $? -eq 0 ]; then
            printf "Decrypted: %s\n" "$OUTPUT_PATH"
        else
            printf "Failed to decrypt: %s\n" "$INPUT_PATH"
        fi
    fi
}

main(){
    clear
    while true; do
        show_menu
        printf "Enter your choice:\n"
        read -r CHOICE

        case $CHOICE in
            1) encrypt_file ;;
            2) decrypt_file ;;
            3) printf "Exiting...\n"; exit 0 ;;
            *) printf "Invalid choice. Please try again.\n" ;;
        esac

        printf "Press [Enter] to continue...\n"
        read -r
    done
}

checkEnv
checkEscalationTool
main