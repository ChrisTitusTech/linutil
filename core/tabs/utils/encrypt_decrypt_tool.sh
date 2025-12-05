#!/bin/sh -e

. ../common-script.sh
# Function to display the menu
printf "%b\n" "${YELLOW}Ensuring OpenSSL is installed...${RC}"

# Install OpenSSL
if ! command_exists openssl; then
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -S --noconfirm --needed openssl
            ;;
        apt-get|nala|dnf|eopkg)
            "$ESCALATION_TOOL" "$PACKAGER" install -y openssl
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install openssl
            ;;
        apk)
            "$ESCALATION_TOOL" "$PACKAGER" add openssl
            ;;
        xbps-install)
            "$ESCALATION_TOOL" "$PACKAGER" -Sy openssl
            ;;
        *)
            printf "%b\n" "${RED}Unsupported package manager: ""$PACKAGER""${RC}"
            exit 1
            ;;
    esac
fi

show_menu() {
    printf "%b\n" "========================================================"
    printf "%b\n" " File/Directory Encryption/Decryption"
    printf "%b\n" "========================================================"
    printf "%b\n" "How to use:-"
    printf "%b\n" "if you encrypt or decrypt a file include new file name for successful operation"
    printf "%b\n" "if you encrypt or decrypt a folder include new directory name for successful operation"
    printf "%b\n" "========================================================"
    printf "%b\n" "1. Encrypt a file or directory"
    printf "%b\n" "2. Decrypt a file or directory"
    printf "%b\n" "3. Exit"
    printf "%b\n" "========================================================"
}

# Function to encrypt a file
encrypt_file() {
    printf "%b" "Enter the path to the file or directory to encrypt: "
    read -r INPUT_PATH

    if [ ! -e "$INPUT_PATH" ]; then
        printf "%b\n" "Path does not exist!"
        return
    fi
    
    printf "%b" "Enter the path for the encrypted file or directory: "
    read -r OUTPUT_PATH

    printf "%b" "Enter the encryption password: "
    read -r PASSWORD

    if [ -d "$INPUT_PATH" ]; then
        # Encrypt each file in the directory
        find "$INPUT_PATH" -type f | while read -r FILE; do
            REL_PATH="${FILE#"$INPUT_PATH"/}"
            OUTPUT_FILE="$OUTPUT_PATH/$REL_PATH.enc"
            mkdir -p "$(dirname "$OUTPUT_FILE")"

            if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$FILE" -out "$OUTPUT_FILE" -k "$PASSWORD"; then
                printf "%b\n" "Encrypted: $OUTPUT_FILE"
            else
                printf "%b\n" "Failed to encrypt: $FILE"
            fi
        done
    else
        # Encrypt a single file
        if [ -d "$OUTPUT_PATH" ]; then
            printf "%b\n" "Output path must be a file for single file encryption."
            return
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")"

        if openssl enc -aes-256-cbc -salt -pbkdf2 -in "$INPUT_PATH" -out "$OUTPUT_PATH" -k "$PASSWORD"; then
            printf "%b\n" "Encrypted: $OUTPUT_PATH"
        else
            printf "%b\n" "Failed to encrypt: $INPUT_PATH"
        fi
    fi
}

# Function to decrypt a file
decrypt_file() {
    printf "%b" "Enter the path to the file or directory to decrypt: "
    read -r INPUT_PATH

    if [ ! -e "$INPUT_PATH" ]; then
        printf "%b\n" "Path does not exist!"
        return
    fi

    printf "%b" "Enter the path for the decrypted file or directory: "
    read -r OUTPUT_PATH

    printf "%b" "Enter the decryption password: "
    read -r PASSWORD

    if [ -d "$INPUT_PATH" ]; then
        # Decrypt each file in the directory
        find "$INPUT_PATH" -type f -name '*.enc' | while read -r FILE; do
            REL_PATH="${FILE#"$INPUT_PATH"/}"
            OUTPUT_FILE="$OUTPUT_PATH/${REL_PATH%.enc}"
            mkdir -p "$(dirname "$OUTPUT_FILE")"

            if openssl enc -aes-256-cbc -d -pbkdf2 -in "$FILE" -out "$OUTPUT_FILE" -k "$PASSWORD"; then
                printf "%b\n" "Decrypted: $OUTPUT_FILE"
            else
                printf "%b\n" "Failed to decrypt: $FILE"
            fi
        done
    else
        # Decrypt a single file
        if [ -d "$OUTPUT_PATH" ]; then
            printf "%b\n" "Output path must be a file for single file decryption."
            return
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")"

        if openssl enc -aes-256-cbc -d -pbkdf2 -in "$INPUT_PATH" -out "$OUTPUT_PATH" -k "$PASSWORD"; then
            printf "%b\n" "Decrypted: $OUTPUT_PATH"
        else
            printf "%b\n" "Failed to decrypt: $INPUT_PATH"
        fi
    fi
}

main(){
    clear
    while true; do
        show_menu
        printf "%b" "Enter your choice: "
        read -r CHOICE

        case $CHOICE in
            1) encrypt_file ;;
            2) decrypt_file ;;
            3) printf "%b\n" "Exiting..."; exit 0 ;;
            *) printf "%b\n" "Invalid choice. Please try again." ;;
        esac

        printf "%b\n" "Press [Enter] to continue..."
        read -r _
    done
}

checkEnv
checkEscalationTool
main
