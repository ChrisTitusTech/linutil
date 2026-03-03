#!/bin/sh -e

. ../../common-script.sh

DOWNLOAD_DIR="${HOME}/Downloads"

getStableVersion() {
    year=$(date +%y)
    for month in 11 05; do
        channel="nixos-${year}.${month}"
        if curl -sL "https://channels.nixos.org/${channel}" -o /dev/null -w '%{http_code}' 2>/dev/null | grep -q "200"; then
            printf "%s" "$channel"
            return 0
        fi
    done
    channel="nixos-$((year - 1)).11"
    if curl -sL "https://channels.nixos.org/${channel}" -o /dev/null -w '%{http_code}' 2>/dev/null | grep -q "200"; then
        printf "%s" "$channel"
        return 0
    fi
    printf "%b\n" "${RED}Could not resolve stable channel.${RC}" >&2
    return 1
}

resolveISO() {
    alias_url="https://channels.nixos.org/${1}/latest-nixos-${2}-aarch64-linux.iso"
    real_url=$(curl -sL -o /dev/null -w '%{url_effective}' "$alias_url")
    real_name=$(basename "$real_url")
    if [ "$real_name" = "latest-nixos-${2}-aarch64-linux.iso" ] || [ -z "$real_name" ]; then
        printf "%b\n" "${RED}Could not resolve ISO filename for ${1}.${RC}" >&2
        return 1
    fi
    printf "%s|%s" "$real_url" "$real_name"
}

downloadArmISO() {
    STABLE_CHANNEL=$(getStableVersion) || return 1

    printf "%b\n" "${CYAN}======================================${RC}"
    printf "%b\n" "${CYAN}    NixOS ISO Downloader (aarch64)${RC}"
    printf "%b\n" "${CYAN}======================================${RC}"
    printf "%b\n" "${YELLOW}For: Raspberry Pi 4/5, Apple Silicon VMs, ARM servers${RC}"
    printf "%b\n" ""
    printf "%b\n" "1) Stable Minimal      (${STABLE_CHANNEL})"
    printf "%b\n" "2) Stable Graphical    (${STABLE_CHANNEL})"
    printf "%b\n" "3) Unstable Minimal    (rolling)"
    printf "%b\n" "4) Unstable Graphical  (rolling)"
    printf "%b\n" "0) Cancel"
    printf "%b" "${YELLOW}Select [0-4]: ${RC}"
    read -r choice

    case "$choice" in
        1) ISO_TYPE="minimal"; CHANNEL="$STABLE_CHANNEL" ;;
        2) ISO_TYPE="graphical"; CHANNEL="$STABLE_CHANNEL" ;;
        3) ISO_TYPE="minimal"; CHANNEL="nixos-unstable" ;;
        4) ISO_TYPE="graphical"; CHANNEL="nixos-unstable" ;;
        0) printf "%b\n" "${YELLOW}Cancelled.${RC}"; return 0 ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}"; return 1 ;;
    esac

    printf "%b\n" "${YELLOW}Resolving latest ${ISO_TYPE} build for ${CHANNEL} (aarch64)...${RC}"

    ISO_INFO=$(resolveISO "$CHANNEL" "$ISO_TYPE") || return 1
    ISO_URL=$(printf "%s" "$ISO_INFO" | cut -d'|' -f1)
    ISO_NAME=$(printf "%s" "$ISO_INFO" | cut -d'|' -f2)
    HASH_URL="${ISO_URL}.sha256"

    printf "%b\n" "${CYAN}Resolved: ${ISO_NAME}${RC}"
    printf "%b\n" "${CYAN}Source: ${ISO_URL}${RC}"

    mkdir -p "$DOWNLOAD_DIR"
    cd "$DOWNLOAD_DIR" || return 1

    printf "%b\n" "${YELLOW}Downloading ISO...(this may take several minutes)...${RC}"
    curl -L -C - --progress-bar -o "$ISO_NAME" "$ISO_URL" || { printf "%b\n" "${RED}ISO download failed.${RC}"; return 1; }

    printf "%b\n" "${YELLOW}Downloading checksum...${RC}"
    curl -sL -o "${ISO_NAME}.sha256" "$HASH_URL" || { printf "%b\n" "${RED}Checksum download failed.${RC}"; return 1; }

    printf "%b\n" "${YELLOW}Verifying SHA256...${RC}"
    if sha256sum -c "${ISO_NAME}.sha256" >/dev/null 2>&1; then
        rm -f "${ISO_NAME}.sha256"

        if [ "$CHANNEL" = "nixos-unstable" ] && [ "$ISO_TYPE" = "minimal" ]; then
            printf "%b\n" "${GREEN}🦊🔥🔥🔥 SHA PASSED 🔥🔥🔥🦊${RC}"
            printf "%b\n" "${CYAN}❄ ⋆。°✩ ISO ACQUIRED ✩°。⋆ ❄${RC}"
        else
            printf "%b\n" "${GREEN}✓ SHA256 verified${RC}"
        fi

        printf "%b\n" ""
        printf "%b\n" "${GREEN}✓ Saved: ${DOWNLOAD_DIR}/${ISO_NAME} [aarch64]${RC}"
        printf "%b\n" ""
        printf "%b\n" "${CYAN}Next: Use 'Burn ISO to USB' in LinUtil or:${RC}"
        printf "%b\n" "  sudo dd if=${ISO_NAME} of=/dev/sdX bs=4M status=progress conv=fsync"
    else
        printf "%b\n" "${RED}✗ Checksum mismatch. Download corrupted.${RC}"
        rm -f "$ISO_NAME" "${ISO_NAME}.sha256"
        return 1
    fi
}

checkArch
checkCommandRequirements "curl sha256sum"
downloadArmISO
