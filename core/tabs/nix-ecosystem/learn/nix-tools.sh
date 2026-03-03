#!/bin/sh -e

. ../../common-script.sh

showTools() {

printf "%b" "${CYAN}"
cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  NIX TOOLS & INPUTS                                                            ║
║  Curated ecosystem tools for NixOS and Nix                                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║                                                                                ║
║  ┌─ DAILY DRIVERS ─────────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  nh                    Better nixos-rebuild & home-manager switch       │   ║
║  │                        Search, diff, cleaner output                     │   ║
║  │                        github.com/viperML/nh                            │   ║
║  │                                                                         │   ║
║  │  nix-direnv            Auto-activate shells per directory               │   ║
║  │                        Cached environments, instant switching           │   ║
║  │                        github.com/nix-community/nix-direnv              │   ║
║  │                                                                         │   ║
║  │  comma                 Run programs without installing                  │   ║
║  │                        Usage: , cowsay hello                            │   ║
║  │                        github.com/nix-community/comma                   │   ║
║  │                                                                         │   ║
║  │  nix-index-database    Pre-built package index (weekly updates)         │   ║
║  │                        Instant nix-locate without local indexing        │   ║
║  │                        github.com/nix-community/nix-index-database      │   ║
║  │                                                                         │   ║
║  │  nix-output-monitor    Pretty build progress with dependency tree       │   ║
║  │                        Alias: nom build, nom develop                    │   ║
║  │                        github.com/maralorn/nix-output-monitor           │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ LANGUAGE SERVERS & FORMATTERS ─────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  nixd                  Modern LSP: completion, hover, diagnostics       │   ║
║  │                        Supports flake & home-manager options            │   ║
║  │                        github.com/nix-community/nixd           [REC]    │   ║
║  │                                                                         │   ║
║  │  nil                   Lighter alternative LSP                          │   ║
║  │                        github.com/oxalica/nil                           │   ║
║  │                                                                         │   ║
║  │  alejandra             Fast, opinionated formatter (no config)          │   ║
║  │                        github.com/kamadorueda/alejandra        [REC]    │   ║
║  │                                                                         │   ║
║  │  nixfmt                Official RFC-166 formatter (as of 25.11)         │   ║
║  │                        github.com/NixOS/nixfmt                          │   ║
║  │                                                                         │   ║
║  │  statix                Anti-pattern detection & suggestions             │   ║
║  │                        github.com/nerdypepper/statix                    │   ║
║  │                                                                         │   ║
║  │  deadnix               Find unused code in .nix files                   │   ║
║  │                        github.com/astro/deadnix                         │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ SYSTEM SETUP ──────────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  disko                 Declarative disk partitioning                    │   ║
║  │                        Supports: ZFS, LUKS, LVM, btrfs subvols          │   ║
║  │                        github.com/nix-community/disko       [ESSENTIAL] │   ║
║  │                                                                         │   ║
║  │  impermanence          Ephemeral root filesystem with /persist          │   ║
║  │                        Clean system state, security benefits            │   ║
║  │                        github.com/nix-community/impermanence            │   ║
║  │                                                                         │   ║
║  │  nixos-hardware        Hardware-specific NixOS modules                  │   ║
║  │                        ThinkPad, Framework, Dell, Apple configs         │   ║
║  │                        github.com/NixOS/nixos-hardware                  │   ║
║  │                                                                         │   ║
║  │  nixos-anywhere        Install NixOS over SSH to any Linux              │   ║
║  │                        Works on VPS, bare metal, rescue systems         │   ║
║  │                        github.com/numtide/nixos-anywhere                │   ║
║  │                                                                         │   ║
║  │  nixos-generators      Generate ISOs, VMs, cloud images                 │   ║
║  │                        Formats: qcow2, vmware, azure, gce, etc.         │   ║
║  │                        github.com/nix-community/nixos-generators        │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ SECRETS & SECURITY ────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  sops-nix              YAML/JSON secrets with age/GPG/cloud KMS         │   ║
║  │                        Best for teams & enterprise                      │   ║
║  │                        github.com/Mic92/sops-nix               [REC]    │   ║
║  │                                                                         │   ║
║  │  agenix                Simple age-based secrets using SSH keys          │   ║
║  │                        Best for personal use, simple setups             │   ║
║  │                        github.com/ryantm/agenix                         │   ║
║  │                                                                         │   ║
║  │  lanzaboote            UEFI Secure Boot for NixOS                       │   ║
║  │                        TPM2 measured boot, custom keys                  │   ║
║  │                        github.com/nix-community/lanzaboote              │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ FLAKE ORGANIZATION (pick one) ─────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  flake-parts           Modular flake framework                          │   ║
║  │                        Best for complex multi-output flakes             │   ║
║  │                        flake.parts                             [REC]    │   ║
║  │                                                                         │   ║
║  │  snowfall-lib          Opinionated structure, batteries-included        │   ║
║  │                        Convention-based, less boilerplate               │   ║
║  │                        snowfall.org/lib                                 │   ║
║  │                                                                         │   ║
║  │  ez-configs            Auto-discovery from folder structure             │   ║
║  │                        flake-parts module, 6 standard directories       │   ║
║  │                        github.com/ehllie/ez-configs                     │   ║
║  │                                                                         │   ║
║  │  blueprint             Convention-over-configuration (numtide)          │   ║
║  │                        Maps: packages/, devshells/, hosts/              │   ║
║  │                        github.com/numtide/blueprint                     │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ DEV ENVIRONMENTS ──────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  devenv                Full development environments                    │   ║
║  │                        Services, processes, languages, scripts          │   ║
║  │                        devenv.sh                               [REC]    │   ║
║  │                                                                         │   ║
║  │  devshell              Simple, fast dev shells                          │   ║
║  │                        Lightweight alternative to devenv                │   ║
║  │                        github.com/numtide/devshell                      │   ║
║  │                                                                         │   ║
║  │  pre-commit-hooks      Git hooks in Nix                                 │   ║
║  │                        Formatters, linters, tests on commit             │   ║
║  │                        github.com/cachix/pre-commit-hooks.nix           │   ║
║  │                                                                         │   ║
║  │  treefmt-nix           Multi-language formatter config                  │   ║
║  │                        One command formats all file types               │   ║
║  │                        github.com/numtide/treefmt-nix                   │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ DEPLOYMENT ────────────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  deploy-rs             Remote NixOS deployment with rollback            │   ║
║  │                        Simple multi-profile deploys                     │   ║
║  │                        github.com/serokell/deploy-rs                    │   ║
║  │                                                                         │   ║
║  │  colmena               Stateless fleet deployment (Rust)                │   ║
║  │                        Parallel deployment, tagging system              │   ║
║  │                        github.com/zhaofengli/colmena          [REC]     │   ║
║  │                                                                         │   ║
║  │  clan-core             Full-stack fleet management                      │   ║
║  │                        VPN mesh, secrets, Web UI, VM manager            │   ║
║  │                        clan.lol                                         │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ BINARY CACHES ─────────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  cachix                Hosted binary cache service                      │   ║
║  │                        Easy setup, free tier available                  │   ║
║  │                        cachix.org                             [REC]     │   ║
║  │                                                                         │   ║
║  │  attic                 Self-hosted cache server                         │   ║
║  │                        Full control, private infrastructure             │   ║
║  │                        github.com/zhaofengli/attic                      │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ EDITORS ───────────────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  nixvim                Declarative Neovim configuration                 │   ║
║  │                        Large community, good docs                       │   ║
║  │                        github.com/nix-community/nixvim        [REC]     │   ║
║  │                                                                         │   ║
║  │  nvf                   Modern Neovim framework (alt to nixvim)          │   ║
║  │                        github.com/notashelf/nvf                         │   ║
║  │                                                                         │   ║
║  │  nix-vscode-extensions All VS Code marketplace extensions in Nix        │   ║
║  │                        Daily updates from marketplace                   │   ║
║  │                        github.com/nix-community/nix-vscode-extensions   │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  ┌─ EXTRAS & REPOS ────────────────────────────────────────────────────────┐   ║
║  │                                                                         │   ║
║  │  NUR                   Nix User Repository - community packages         │   ║
║  │                        Access: pkgs.nur.repos.<user>.<pkg>              │   ║
║  │                        nur.nix-community.org                            │   ║
║  │                                                                         │   ║
║  │  chaotic-nyx           Gaming, performance, bleeding-edge pkgs          │   ║
║  │                        mesa-git, linux-cachyos, gamescope               │   ║
║  │                        github.com/chaotic-cx/nyx                        │   ║
║  │                                                                         │   ║
║  │  home-manager          Declarative user environment management          │   ║
║  │                        Dotfiles, user packages, services                │   ║
║  │                        github.com/nix-community/home-manager [ESSENTIAL]│   ║
║  │                                                                         │   ║
║  │  nix-darwin            NixOS-style config for macOS                     │   ║
║  │                        System defaults, services, launchd               │   ║
║  │                        github.com/LnL7/nix-darwin                       │   ║
║  │                                                                         │   ║
║  └─────────────────────────────────────────────────────────────────────────┘   ║
║                                                                                ║
║  [REC] = Recommended   [ESSENTIAL] = Almost everyone needs this                ║
║                                                                                ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
printf "%b\n" "${RC}"
printf "%b\n" "${YELLOW}    ↑ PgUp to see full reference ↑${RC}"
}

checkArch
showTools