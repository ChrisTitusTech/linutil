#!/bin/sh -e

. ../common-script.sh  

CONFIGURATION_URL="https://github.com/quickemu-project/quickget_configs/releases/download/daily/quickget_data.json"

# Function to display all available block devices
list_devices() {
    printf "%b\n" "${YELLOW} Available devices and partitions: ${RC}"
    printf "\n"
    "$ESCALATION_TOOL" lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,LABEL
    printf "\n"
}

# shellcheck disable=SC2086
installDependencies() {
    DEPENDENCIES="xz gzip bzip2 jq"
    if ! command_exists ${DEPENDENCIES}; then
        printf "%b\n" "${YELLOW}Installing dependencies...${RC}"
        case "${PACKAGER}" in
            apt-get|nala)
                "${ESCALATION_TOOL}" "${PACKAGER}" install -y xz-utils gzip bzip2 jq;;
            dnf|zypper)
                "${ESCALATION_TOOL}" "${PACKAGER}" install -y ${DEPENDENCIES};;
            pacman)
                "${ESCALATION_TOOL}" "${PACKAGER}" -S --noconfirm --needed ${DEPENDENCIES};;
            apk)
                "${ESCALATION_TOOL}" "${PACKAGER}" add ${DEPENDENCIES};;
            *)
                printf "%b\n" "${RED}Unsupported package manager.${RC}"
                exit 1
                ;;
        esac
    fi
}

# Function to ask whether to use local or online ISO
choose_iso_source() {
    printf "%b\n" "${YELLOW} Do you want to use a local ISO or download online? ${RC}"
    printf "1) Download online\n"
    printf "2) Use local ISO\n"
    printf "\n"
    printf "%b" "Select option (1-2): "
    read -r ISO_SOURCE_OPTION

    case $ISO_SOURCE_OPTION in
        1)
            get_online_iso
            ;;
        2)
            printf "Enter the path to the already downloaded ISO file: "
            read -r ISO_PATH
            if [ ! -f "$ISO_PATH" ]; then
                printf "%b\n" "${RED} ISO file not found: $ISO_PATH ${RC}"
                exit 1
            fi
            ;;
        *)
            printf "%b\n" "${RED}Invalid option selected. ${RC}"
            exit 1
            ;;
    esac
}

decompress_iso() {
    printf "%b\n" "${YELLOW}Decompressing ISO file...${RC}"
    case "${ISO_ARCHIVE_FORMAT}" in
        xz)
            xz -d "${ISO_PATH}"
            ISO_PATH="$(echo "${ISO_PATH}" | sed 's/\.xz//')";;
        gz)
            gzip -d "${ISO_PATH}"
            ISO_PATH="$(echo "${ISO_PATH}" | sed 's/\.gz//')";;
        bz2)
            bzip2 -d "${ISO_PATH}"
            ISO_PATH="$(echo "${ISO_PATH}" | sed 's/\.bz2//')";;
        *) 
            printf "%b\n" "${RED}Unsupported archive format. Try manually decompressing the ISO and choosing it as a local file instead.${RC}"
            exit 1
            ;;
    esac

    printf "%b\n" "${GREEN}ISO file decompressed successfully.${RC}"
}

check_hash() {
    case "${#ISO_CHECKSUM}" in
        32) HASH_ALGO="md5sum";;
        40) HASH_ALGO="sha1sum";;
        64) HASH_ALGO="sha256sum";;
        128) HASH_ALGO="sha512sum";;
        *) printf "%b\n" "${RED}Invalid checksum length. Skipping checksum verification.${RC}"
            return;;
    esac
    printf "%b\n" "Checking ISO integrity using ${HASH_ALGO}..."
    if ! echo "${ISO_CHECKSUM} ${ISO_PATH}" | "${HASH_ALGO}" --check --status; then
        printf "%b\n" "${RED}Checksum verification failed.${RC}"
        exit 1
    else
        printf "%b\n" "${GREEN}Checksum verification successful.${RC}"
    fi
}

download_iso() {
    printf "\n%b\n" "${YELLOW}Found URL: ${ISO_URL}${RC}"
    printf "%b\n" "${YELLOW}Downloading ISO to ${ISO_PATH}...${RC}"
    if ! curl -L -o "$ISO_PATH" "$ISO_URL"; then
        printf "%b\n" "${RED}Failed to download the ISO file.${RC}"
        exit 1
    fi
}

get_architecture() {
    printf "%b\n" "${YELLOW}Select the architecture of the ISO to flash${RC}"
    printf "%b\n" "1) x86_64"
    printf "%b\n" "2) AArch64"
    printf "%b\n" "3) riscv64"
    printf "%b" "Select an option (1-3): "
    read -r ARCH
    case "${ARCH}" in
        1) ARCH="x86_64";;
        2) ARCH="aarch64";;
        3) ARCH="riscv64";;
        *)
            printf "%b\n" "${RED}Invalid architecture selected. ${RC}"
            exit 1
            ;;
    esac
}

comma_delimited_list() {
    echo "${1}" | tr '\n' ',' | sed 's/,/, /g; s/, $//'
}

get_online_iso() {
    get_architecture
    printf "%b\n" "${YELLOW}Fetching available operating systems...${RC}"
    clear

    # Download available operating systems, filter to to those that match requirements
    # Remove entries with more than 1 ISO or any other medium, they could cause issues
    OS_JSON="$(curl -L -s "$CONFIGURATION_URL" | jq -c "[.[] | \
        .releases |= map(select( \
        (.arch // \"x86_64\") == "\"${ARCH}\"" \
        and (.iso | length == 1) and (.iso[0] | has(\"web\")) \
        and .img == null and .fixed_iso == null and .floppy == null and .disk_images == null)) \
        | select(.releases | length > 0)]")"

    if echo "${OS_JSON}" | jq -e 'length == 0' >/dev/null; then
        printf "%b\n" "${RED}No operating systems found.${RC}"
        exit 1
    fi

    printf "%b\n" "${YELLOW}Available Operating Systems:${RC}"
    comma_delimited_list "$(echo "${OS_JSON}" | jq -r '.[].name')"
    printf "\n%b" "Select an operating system: "
    read -r OS

    OS_JSON="$(echo "${OS_JSON}" | jq --arg os "${OS}" -c '.[] | select(.name == $os)')"
    if [ -z "${OS_JSON}" ]; then
        printf "%b\n" "${RED}Invalid operating system selected.${RC}"
        exit 1
    fi
    PRETTY_NAME="$(echo "${OS_JSON}" | jq -r '.pretty_name')"

    printf "\n%b\n" "${YELLOW}Available releases for ${PRETTY_NAME}:${RC}"
    comma_delimited_list "$(echo "${OS_JSON}" | jq -r '.releases[].release' | sort -Vur)"
    printf "\n%b" "Select a release: "
    read -r RELEASE
    printf "\n"

    OS_JSON="$(echo "${OS_JSON}" | jq --arg release "${RELEASE}" -c '.releases |= map(select(.release == $release))')"
    if echo "${OS_JSON}" | jq -e '.releases | length == 0' >/dev/null; then
        printf "%b\n" "${RED}Invalid release selected.${RC}"
        exit 1
    fi

    if echo "${OS_JSON}" | jq -e '.releases[] | select(.edition != null) | any' >/dev/null; then
        printf "%b\n" "${YELLOW}Available editions for ${PRETTY_NAME} ${RELEASE}:${RC}"
        comma_delimited_list "$(echo "${OS_JSON}" | jq -r '.releases[].edition' | sort -Vur)"
        printf "\n%b" "Select an edition: "
        read -r EDITION
        ENTRY="$(echo "${OS_JSON}" | jq --arg edition "${EDITION}" -c '.releases[] | select(.edition == $edition)')"
    else
        ENTRY="$(echo "${OS_JSON}" | jq -c '.releases[0]')"
    fi

    if [ -z "${ENTRY}" ]; then
        printf "%b\n" "${RED}Invalid edition selected.${RC}"
        exit 1
    fi

    WEB_DATA="$(echo "${ENTRY}" | jq -c '.iso[0].web')"

    ISO_URL="$(echo "${WEB_DATA}" | jq -r '.url')"
    ISO_CHECKSUM="$(echo "${WEB_DATA}" | jq -r '.checksum')"
    ISO_ARCHIVE_FORMAT="$(echo "${WEB_DATA}" | jq -r '.archive_format')"

    ISO_FILENAME="$(echo "${WEB_DATA}" | jq -r '.file_name')"
    if [ "${ISO_FILENAME}" = "null" ]; then
        ISO_FILENAME="$(basename "${ISO_URL}")"
    fi

    ISO_PATH="${HOME}/Downloads/${ISO_FILENAME}"
    download_iso

    if [ "${ISO_CHECKSUM}" != "null" ]; then
        check_hash
    fi
    if [ "${ISO_ARCHIVE_FORMAT}" != "null" ]; then
        decompress_iso
    fi
}

write_iso(){  
    clear

     # Ask whether to use a local or online ISO
    choose_iso_source

    clear
    # Display all available devices
    list_devices

    # Prompt user for USB device
    printf "%b" "Enter the USB device (e.g. /dev/sdX): "
    read -r USB_DEVICE

    # Verify that the USB device exists
    if [ ! -b "$USB_DEVICE" ]; then
        printf "%b\n" "${RED}USB device not found: $USB_DEVICE${RC}"
        exit 1
    fi

    # Confirm the device selection with the user
    printf "%b" "${RED}WARNING: This will erase all data on ${USB_DEVICE}. Are you sure you want to continue? (y/N): ${RC}"
    read -r CONFIRMATION

    CONFIRMATION="$(echo "$CONFIRMATION" | tr '[:upper:]' '[:lower:]')"
    if [ "${CONFIRMATION}" != "yes" ] && [ "${CONFIRMATION}" != "y" ]; then
        printf "%b\n" "${YELLOW}Operation cancelled.${RC}"
        exit 1
    fi

    # Display progress and create the bootable USB drive
    printf "%b\n" "${YELLOW}Creating bootable USB drive...${RC}"
    if ! "$ESCALATION_TOOL" dd if="$ISO_PATH" of="$USB_DEVICE" bs=4M status=progress oflag=sync; then
        printf "%b\n" "${RED}Failed to create bootable USB drive${RC}"
        exit 1
    fi

    # Sync to ensure all data is written
    if ! "$ESCALATION_TOOL" sync; then
        printf "%b\n" "${RED}Failed to sync data${RC}"                              
        exit 1
    fi

    printf "%b\n" "${GREEN}Bootable USB drive created successfully!${RC}"

    # Eject the USB device
    printf "%b\n" "${YELLOW}Ejecting ${USB_DEVICE}...${RC}"
    if ! "$ESCALATION_TOOL" umount "${USB_DEVICE}"* 2>/dev/null; then
        printf "%b\n" "${RED}Failed to unmount ${USB_DEVICE}${RC}"
    fi
    if ! "$ESCALATION_TOOL" eject "$USB_DEVICE"; then
        printf "%b\n" "${RED}Failed to eject ${USB_DEVICE}${RC}"
    fi

    printf "%b\n" "${GREEN}You can safely remove your USB drive. Reinsert the drive to be detected.${RC}"
}

checkEnv
checkEscalationTool
installDependencies
write_iso
