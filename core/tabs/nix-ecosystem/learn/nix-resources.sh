#!/bin/sh -e

. ../../common-script.sh

showResources() {

printf "%b" "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  NIX GUIDES & RESOURCES                                                        ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  LEARN (Start Here)                                                            ║
║    zero-to-nix.com                      # Best intro — start here              ║
║    nix.dev                              # Official tutorials                   ║
║    nixos.org/manual/nix/stable          # Nix manual                           ║
║    nix.dev/tutorials/nix-language       # Language basics                      ║
║    nixos-and-flakes.thiscute.world      # Flakes book (comprehensive)          ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  SEARCH                                                                        ║
║    search.nixos.org/packages            # Official package search              ║
║    mynixos.com                          # Options + config generator           ║
║    home-manager-options.extranix.com    # Home Manager options                 ║
║    lazamar.co.uk/nix-versions           # Old package versions                 ║
║    nixhub.io                            # Version history                      ║
║    nur.nix-community.org                # Nix User Repository                  ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  TOOLS                                                                         ║
║    cachix.org                           # Binary cache hosting                 ║
║    determinate.systems                  # Installer + FlakHub                  ║
║    lix.systems                          # Lix fork of NixPkgs                  ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  TEMPLATES & STARTERS                                                          ║
║    github.com/Misterio77/nix-starter-configs       # Config templates          ║
║    github.com/mhwombat/nix-for-numbskulls          # Beginner-friendly         ║
║    github.com/gytis-ivaskevicius/flake-utils-plus  # Better flake org.         ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  COMMUNITY & SUPPORT                                                           ║
║    discourse.nixos.org                  # Official forum                       ║
║    matrix: #nix:nixos.org               # Matrix chat                          ║
║    reddit.com/r/NixOS                   # Reddit                               ║
║    github.com/nix-community             # Community repos                      ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  VIDEO (YouTube)                                                               ║
║    @vimjoyer                            # Best Nix videos                      ║
║    @librephoenix                        # NixOS tutorials                      ║
║    @DistroTube                          # Linux + NixOS                        ║
║    @TheLinuxCast                        # NixOS content                        ║
║    @tony-btw                            # Great Nix Setup                      ║
║    @SaschaKoenig                        # Advanced NixOS                       ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  NOTABLE ECOSYSTEM PROJECTS & DISTROS                                          ║
║    snowflakeos.org                      # Beginner-friendly NixOS variant      ║
║    jovian-experiments.github.io         # SteamOS gaming experience on NixOS   ║
║    athenaos.org                         # Pentesting & InfoSec NixOS           ║
║    github/nix-overlay-guix              # Overlay for installing Guix in NixOS ║
║    blendos.co                           # Immutable OS using Nix containers    ║
║    auxolotl.org                         # An alternative to the Nix ecosystem  ║
║    spectrum-os.org                      # Step towards usable secure computing ║
║    snix.dev / tvix.dev                  # Modern re-implementations of Nix     ║
║    liminix.org                          # Nix-based OpenWrt embedded system    ║
║    NixBSD - NixNG - Plan9 - nixified.ai - Project-Ekala - GLF-OS - RedNixOS    ║
╠════════════════════════════════════════════════════════════════════════════════╣
║  CURATED LISTS                                                                 ║
║    github.com/nix-community/awesome-nix # Awesome Nix list                     ║
║    nixos.org/community                  # Official community page              ║
║    tildeverse.org                       # Interested learning about *nix       ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
printf "%b\n" "${RC}"
printf "%b\n" "${YELLOW}    ↑ PgUp to see full reference ↑${RC}"
}

checkArch
showResources