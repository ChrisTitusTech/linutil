#!/bin/sh -e

. ../../common-script.sh

enableFlakes() {
    if ! command_exists nix; then
        printf "%b\n" "${RED}Nix is not installed.${RC}"
        return 1
    fi

    NIX_CONF="/etc/nix/nix.conf"
    USER_CONF="$HOME/.config/nix/nix.conf"

    # Check if already enabled
    if [ -f "$NIX_CONF" ] && grep -q "experimental-features.*flakes" "$NIX_CONF" 2>/dev/null; then
        printf "%b\n" "${GREEN}Flakes already enabled in ${NIX_CONF}${RC}"
        return 0
    fi

    if [ -f "$USER_CONF" ] && grep -q "experimental-features.*flakes" "$USER_CONF" 2>/dev/null; then
        printf "%b\n" "${GREEN}Flakes already enabled in ${USER_CONF}${RC}"
        return 0
    fi

    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════
  ENABLE NIX FLAKES
══════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"

    printf "%b\n" "Flakes are an experimental feature that provides:"
    printf "%b\n" "  • Reproducible, hermetic builds"
    printf "%b\n" "  • Standardized flake.nix interface"
    printf "%b\n" "  • Better dependency management"
    printf "%b\n" "  • nix run, nix develop, nix build commands"
    printf "%b\n" ""
    printf "%b\n" "${YELLOW}Note: Determinate installer enables flakes by default.${RC}"
    printf "%b\n" "${YELLOW}This is mainly for official Nix installer users.${RC}"
    printf "%b\n" ""

    printf "%b\n" "Where to enable flakes?"
    printf "%b\n" "  1) System-wide (/etc/nix/nix.conf) - requires root"
    printf "%b\n" "  2) User only (~/.config/nix/nix.conf)"
    printf "%b\n" "  0) Cancel"
    printf "%b" "${YELLOW}Select: ${RC}"
    read -r choice

    case "$choice" in
        1)
            printf "%b\n" "${YELLOW}Enabling flakes system-wide...${RC}"
            echo "experimental-features = nix-command flakes" | "$ESCALATION_TOOL" tee -a "$NIX_CONF" >/dev/null
            printf "%b\n" "${GREEN}✓ Flakes enabled in ${NIX_CONF}${RC}"
            ;;
        2)
            printf "%b\n" "${YELLOW}Enabling flakes for current user...${RC}"
            mkdir -p "$(dirname "$USER_CONF")"
            echo "experimental-features = nix-command flakes" >> "$USER_CONF"
            printf "%b\n" "${GREEN}✓ Flakes enabled in ${USER_CONF}${RC}"
            ;;
        0)
            printf "%b\n" "${YELLOW}Cancelled.${RC}"
            return 0
            ;;
        *)
            printf "%b\n" "${RED}Invalid option.${RC}"
            return 1
            ;;
    esac

    printf "%b\n" ""
    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════
  FLAKES ENABLED - Now you can use:
══════════════════════════════════════════════════════════════
  nix flake init          Create new flake
  nix flake update        Update flake.lock
  nix build .#package     Build from flake
  nix run nixpkgs#hello   Run without installing
  nix develop             Enter dev shell
  nix flake show          Show flake outputs
══════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"
}

checkArch
checkEscalationTool
enableFlakes
