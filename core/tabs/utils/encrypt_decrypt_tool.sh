#!/bin/sh -e

. ../common-script.sh
# Function to display the menu
printf "%b\n" "${YELLOW}Ensuring OpenSSL is installed...${RC}"

# Install OpenSSL
if ! command_exists openssl; then
    case "$PACKAGER" in
        pacman)
            "$ESCALATION_TOOL" "$PACKAGER" -Syu --noconfirm openssl
            ;;
        apt-get)
            "$ESCALATION_TOOL" "$PACKAGER" update && "$ESCALATION_TOOL" "$PACKAGER" install -y openssl
            ;;
        dnf)
            "$ESCALATION_TOOL" "$PACKAGER" install -y openssl
            ;;
        zypper)
            "$ESCALATION_TOOL" "$PACKAGER" install openssl
            ;;
        *)
            printf "%b\n" "${RED}Your Linux distribution is not supported by this script.${RC}"
            printf "%b\n" "${YELLOW}You can try installing OpenSSL manually:${RC}"
            echo "1. Refer to your distribution's documentation."
            ;;
    esac
fi

show_menu() {
    echo "========================================================"
    echo " File/Directory Encryption/Decryption"
    echo "========================================================"
    echo "How to use:-"
    echo "if you encrypt or decrypt a file include new file name for successful operation"
    echo "if you encrypt or decrypt a folder include new directory name for successful operation"
    echo "========================================================"
    echo "1. Encrypt a file or directory"
    echo "2. Decrypt a file or directory"
    echo "3. Exit"
    echo "========================================================"
}

# Function to encrypt a file
encrypt_file() {
    echo "Enter the path to the file or directory to encrypt:"
    read -r INPUT_PATH

    if [ ! -e "$INPUT_PATH" ]; then
        echo "Path does not exist!"
        return
    fi

    echo "Enter the path for the encrypted file or directory:"
    read -r OUTPUT_PATH

    printf "Enter the encryption password: "
    read -r PASSWORD

    if [ -d "$INPUT_PATH" ]; then
        # Encrypt each file in the directory
        find "$INPUT_PATH" -type f | while read -r FILE; do
            REL_PATH="${FILE#$INPUT_PATH/}"
            OUTPUT_FILE="$OUTPUT_PATH/$REL_PATH.enc"
            mkdir -p "$(dirname "$OUTPUT_FILE")"
            openssl enc -aes-256-cbc -salt -pbkdf2 -in "$FILE" -out "$OUTPUT_FILE" -k "$PASSWORD"
            if [ $? -eq 0 ]; then
                echo "Encrypted: $OUTPUT_FILE"
            else
                echo "Failed to encrypt: $FILE"
            fi
        done
    else
        # Encrypt a single file
        if [ -d "$OUTPUT_PATH" ]; then
            echo "Output path must be a file for single file encryption."
            return
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")"
        openssl enc -aes-256-cbc -salt -pbkdf2 -in "$INPUT_PATH" -out "$OUTPUT_PATH" -k "$PASSWORD"
        if [ $? -eq 0 ]; then
            echo "Encrypted: $OUTPUT_PATH"
        else
            echo "Failed to encrypt: $INPUT_PATH"
        fi
    fi
}

# Function to decrypt a file
decrypt_file() {
    echo "Enter the path to the file or directory to decrypt:"
    read -r INPUT_PATH

    if [ ! -e "$INPUT_PATH" ]; then
        echo "Path does not exist!"
        return
    fi

    echo "Enter the path for the decrypted file or directory:"
    read -r OUTPUT_PATH

    printf "Enter the decryption password: "
    read -r PASSWORD

    if [ -d "$INPUT_PATH" ]; then
        # Decrypt each file in the directory
        find "$INPUT_PATH" -type f -name '*.enc' | while read -r FILE; do
            REL_PATH="${FILE#$INPUT_PATH/}"
            OUTPUT_FILE="$OUTPUT_PATH/${REL_PATH%.enc}"
            mkdir -p "$(dirname "$OUTPUT_FILE")"
            openssl enc -aes-256-cbc -d -pbkdf2 -in "$FILE" -out "$OUTPUT_FILE" -k "$PASSWORD"
            if [ $? -eq 0 ]; then
                echo "Decrypted: $OUTPUT_FILE"
            else
                echo "Failed to decrypt: $FILE"
            fi
        done
    else
        # Decrypt a single file
        if [ -d "$OUTPUT_PATH" ]; then
            echo "Output path must be a file for single file decryption."
            return
        fi
        mkdir -p "$(dirname "$OUTPUT_PATH")"
        openssl enc -aes-256-cbc -d -pbkdf2 -in "$INPUT_PATH" -out "$OUTPUT_PATH" -k "$PASSWORD"
        if [ $? -eq 0 ]; then
            echo "Decrypted: $OUTPUT_PATH"
        else
            echo "Failed to decrypt: $INPUT_PATH"
        fi
    fi
}

main(){
    clear
    while true; do
        show_menu
        echo "Enter your choice:"
        read -r CHOICE

        case $CHOICE in
            1) encrypt_file ;;
            2) decrypt_file ;;
            3) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid choice. Please try again." ;;
        esac

        printf "Press [Enter] to continue..."
        read -r dummy
    done
}

checkEnv
checkEscalationTool
main