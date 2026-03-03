#!/bin/sh -e

. ../../common-script.sh

showCheatsheet() {

printf "%b" "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  NIX COMMANDS CHEATSHEET                                                       ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  INSTALL PACKAGES                                                              ║
║    nix-env -iA nixpkgs.pkg              # Imperative install                   ║
║    nix-env -e pkg                       # Imperative uninstall                 ║
║    nix-env -q                           # List installed                       ║
║    nix profile install nixpkgs#pkg      # Flakes install                       ║
║    nix profile remove pkg               # Flakes uninstall                     ║
║    nix profile list                     # Flakes list installed                ║
║    nix-shell -p pkg1 pkg2               # Temporary shell                      ║
║    nix run nixpkgs#pkg                  # Run without installing               ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  SEARCH & INFO                                                                 ║
║    nix search nixpkgs pkg               # Search packages                      ║
║    nix-env -qaP '.*pkg.*'               # Search (old way)                     ║
║    nix eval nixpkgs#pkg.meta            # Package metadata                     ║
║    nix path-info nixpkgs#pkg            # Store path info                      ║
║    nix why-depends .#a .#b              # Dependency chain                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  CHANNELS & UPDATES                                                            ║
║    nix-channel --list                   # List channels                        ║
║    nix-channel --add <url> <name>       # Add channel                          ║
║    nix-channel --update                 # Update all channels                  ║
║    nix-channel --remove <name>          # Remove channel                       ║
║    nix registry list                    # List flake registry                  ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  GARBAGE COLLECTION                                                            ║
║    nix-collect-garbage                  # Remove unused paths                  ║
║    nix-collect-garbage -d               # Delete old generations               ║
║    nix-collect-garbage --delete-older-than 30d   # Keep 30 days                ║
║    nix-store --gc                       # Lower level GC                       ║
║    nix-store --optimize                 # Deduplicate (hard links)             ║
║    nix store gc                         # Flakes GC                            ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  GENERATIONS & ROLLBACK                                                        ║
║    nix-env --list-generations           # List user generations                ║
║    nix-env --rollback                   # Rollback user profile                ║
║    nix-env -G 42                        # Switch to generation 42              ║
║    nixos-rebuild list-generations       # List system generations    [NIXOS]   ║
║    nixos-rebuild switch --rollback      # Rollback system            [NIXOS]   ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  FLAKES                                                                        ║
║    nix flake init                       # Create flake.nix template            ║
║    nix flake update                     # Update flake.lock                    ║
║    nix flake update <input>             # Update single input                  ║
║    nix flake lock --update-input <x>    # Same as above                        ║
║    nix flake show                       # Show flake outputs                   ║
║    nix flake check                      # Validate flake                       ║
║    nix flake metadata                   # Flake info + inputs                  ║
║    nix develop                          # Enter devShell                       ║
║    nix develop -c <cmd>                 # Run cmd in devShell                  ║
║    nix build .#pkg                      # Build from flake                     ║
║    nix run .#pkg                        # Run from flake                       ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  NIXOS                                                                         ║
║    nixos-rebuild switch                 # Apply config                         ║
║    nixos-rebuild test                   # Test (no bootloader)                 ║
║    nixos-rebuild boot                   # Apply on next boot                   ║
║    nixos-rebuild build                  # Build only (no apply)                ║
║    nixos-rebuild --flake .#host switch  # Flake-based rebuild                  ║
║    nixos-option <option>                # Query option value                   ║
║    nixos-generate-config                # Generate hardware config             ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  HOME MANAGER                                                                  ║
║    home-manager switch                  # Apply config                         ║
║    home-manager generations             # List generations                     ║
║    home-manager packages                # List installed packages              ║
║    home-manager news                    # Show news/changelog                  ║
║    home-manager expire-generations 30d  # Clean old generations                ║
║    ~/.config/home-manager/home.nix      # Config location (standalone)         ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  DEBUGGING                                                                     ║
║    nix repl                             # Interactive Nix REPL                 ║
║    nix repl '<nixpkgs>'                 # REPL with nixpkgs loaded             ║
║    nix log nixpkgs#pkg                  # Build logs                           ║
║    nix derivation show nixpkgs#pkg      # Show derivation                      ║
║    nix-instantiate --eval -E '...'      # Evaluate expression                  ║
║    nix eval --raw nixpkgs#pkg.version   # Get specific attr                    ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  STORE                                                                         ║
║    nix-store -q --references /nix/...   # Direct dependencies                  ║
║    nix-store -q --requisites /nix/...   # All dependencies (closure)           ║
║    nix-store -q --referrers /nix/...    # What depends on this                 ║
║    nix-store --verify --check-contents  # Verify store integrity               ║
║    nix copy --to ssh://host /nix/...    # Copy to remote                       ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
printf "%b\n" "${RC}"
printf "%b\n" "${YELLOW}    ↑ PgUp to see full reference ↑${RC}"
}

checkArch
showCheatsheet