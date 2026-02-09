#!/bin/sh -e

. ../../common-script.sh

showQuickReference() {
    clear
    printf "%b\n" "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  NIX QUICK REFERENCE                                                           ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  INSTALL PACKAGES                                                              ║
║    nix-env -iA nixpkgs.pkg              # Imperative (old way)                 ║
║    nix profile install nixpkgs#pkg      # Flakes (new way)                     ║
║    nix-shell -p pkg                     # Temporary shell                      ║
║    nix run nixpkgs#pkg                  # Run without installing               ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  MANAGE                                                                        ║
║    nix-channel --update                 # Update channels                      ║
║    nix-collect-garbage -d               # Clean old generations                ║
║    nix-store --optimize                 # Deduplicate store                    ║
║    nix search nixpkgs pkg               # Find packages                        ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  FLAKES (if enabled)                                                           ║
║    nix flake update                     # Update flake.lock                    ║
║    nix develop                          # Enter dev shell                      ║
║    nix build .#pkg                      # Build from flake                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  HOME MANAGER                                                                  ║
║    ~/.config/home-manager/home.nix      # Config location                      ║
║    home-manager switch                  # Apply changes                        ║
║    home-manager generations             # List generations                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  LEARN MORE                                                                    ║
║    https://zero-to-nix.com              # Best intro tutorial                  ║
║    https://search.nixos.org/packages    # Package search                       ║
║    https://nix.dev                      # Official docs                        ║
║    https://mynixos.com                  # Options search                       ║
║    https://nixos-and-flakes.thiscute.world  # Flakes book                      ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "%b\n" "${RC}"
    printf "%b" "${YELLOW}Press Enter to exit...${RC}"
    read -r _
}

showQuickReference
