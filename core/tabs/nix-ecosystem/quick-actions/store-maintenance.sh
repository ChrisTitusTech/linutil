#!/bin/sh -e

. ../../common-script.sh

storeMaintenance() {
    if ! command_exists nix; then
        printf "%b\n" "${RED}Nix is not installed.${RC}"
        return 1
    fi

    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════
  NIX STORE MAINTENANCE
══════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"
    printf "%b\n" "  1) Quick clean (unused paths only)"
    printf "%b\n" "  2) Full clean (delete all old generations)"
    printf "%b\n" "  3) Clean older than 7 days"
    printf "%b\n" "  4) Clean older than 30 days"
    printf "%b\n" "  5) Optimize store (deduplicate with hard links)"
    printf "%b\n" "  0) Cancel"
    printf "%b\n" ""
    printf "%b" "${YELLOW}Select option: ${RC}"
    read -r choice

    case "$choice" in
        1)
            printf "%b\n" "${YELLOW}Running: nix-collect-garbage${RC}"
            "$ESCALATION_TOOL" nix-collect-garbage
            ;;
        2)
            printf "%b\n" "${YELLOW}Running: nix-collect-garbage -d${RC}"
            "$ESCALATION_TOOL" nix-collect-garbage -d
            ;;
        3)
            printf "%b\n" "${YELLOW}Running: nix-collect-garbage --delete-older-than 7d${RC}"
            "$ESCALATION_TOOL" nix-collect-garbage --delete-older-than 7d
            ;;
        4)
            printf "%b\n" "${YELLOW}Running: nix-collect-garbage --delete-older-than 30d${RC}"
            "$ESCALATION_TOOL" nix-collect-garbage --delete-older-than 30d
            ;;
        5)
            printf "%b\n" "${YELLOW}Running: nix-store --optimize${RC}"
            printf "%b\n" "${CYAN}This may take a while depending on store size...${RC}"
            "$ESCALATION_TOOL" nix-store --optimize
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
    printf "%b\n" "${GREEN}✓ Done.${RC}"
}

checkArch
checkEscalationTool
storeMaintenance
