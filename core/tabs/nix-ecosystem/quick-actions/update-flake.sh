#!/bin/sh -e

. ../../common-script.sh

updateFlake() {
    printf "%b\n" "${CYAN}╔════════════════════════════════════════════════════════════════╗${RC}"
    printf "%b\n" "${CYAN}║  NIX FLAKE UPDATE                                              ║${RC}"
    printf "%b\n" "${CYAN}╚════════════════════════════════════════════════════════════════╝${RC}"
    printf "%b\n" ""

    # Check if flakes are enabled
    if ! nix flake --help >/dev/null 2>&1; then
        printf "%b\n" "${RED}Flakes are not enabled on this system.${RC}"
        printf "%b\n" "${CYAN}To enable flakes, add to /etc/nix/nix.conf:${RC}"
        printf "%b\n" "${YELLOW}  experimental-features = nix-command flakes${RC}"
        return 1
    fi

    printf "%b\n" "  1) Update all flake inputs"
    printf "%b\n" "  2) Update specific input"
    printf "%b\n" "  3) Show flake info"
    printf "%b\n" "  4) Check flake"
    printf "%b\n" "  5) Show flake metadata"
    printf "%b\n" ""
    printf "%b" "Select option: "
    read -r choice

    # Get flake path
    printf "%b\n" ""
    printf "%b" "Enter flake path (default: current directory): "
    read -r flake_path
    flake_path="${flake_path:-.}"

    case "$choice" in
        1)
            printf "%b\n" "${YELLOW}Updating all flake inputs...${RC}"
            nix flake update "$flake_path"
            printf "%b\n" "${GREEN}✓ Flake updated.${RC}"
            ;;
        2)
            printf "%b" "Enter input name to update: "
            read -r input_name
            if [ -n "$input_name" ]; then
                printf "%b\n" "${YELLOW}Updating input '$input_name'...${RC}"
                nix flake update "$input_name" --flake "$flake_path"
                printf "%b\n" "${GREEN}✓ Input '$input_name' updated.${RC}"
            else
                printf "%b\n" "${RED}No input name provided.${RC}"
            fi
            ;;
        3)
            printf "%b\n" "${YELLOW}Flake outputs:${RC}"
            nix flake show "$flake_path"
            ;;
        4)
            printf "%b\n" "${YELLOW}Checking flake...${RC}"
            nix flake check "$flake_path"
            printf "%b\n" "${GREEN}✓ Flake check passed.${RC}"
            ;;
        5)
            printf "%b\n" "${YELLOW}Flake metadata:${RC}"
            nix flake metadata "$flake_path"
            ;;
        *)
            printf "%b\n" "${RED}Invalid option.${RC}"
            return 1
            ;;
    esac
}

checkArch
updateFlake
