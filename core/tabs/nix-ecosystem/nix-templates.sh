#!/bin/sh -e

. ../common-script.sh

TEMPLATE_DIR="${HOME}/Downloads/nix-templates"

# ═══════════════════════════════════════════════════════════════════════════════
# TEMPLATE GENERATORS
# ═══════════════════════════════════════════════════════════════════════════════

generateFlakeMinimal() {
    cat > "$TEMPLATE_DIR/flake-minimal.nix" << 'EOF'
# Minimal Flake - Single system, no frills
{
  description = "Minimal NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: {
    nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        ./hardware-configuration.nix
      ];
    };
  };
}
EOF
}

generateFlakeHomeManager() {
    cat > "$TEMPLATE_DIR/flake-home-manager.nix" << 'EOF'
# Flake with Home Manager - System + User config
{
  description = "NixOS + Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      nixosConfigurations.hostname = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./hardware-configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.username = import ./home.nix;
          }
        ];
      };

      # Standalone home-manager (for non-NixOS)
      homeConfigurations."username" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
EOF
}

generateFlakeSnowfall() {
    cat > "$TEMPLATE_DIR/flake-snowfall.nix" << 'EOF'
# Snowfall Lib Flake - Structured, scalable configuration
{
  description = "NixOS configuration with Snowfall Lib";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Optional but recommended
    # nixos-hardware.url = "github:NixOS/nixos-hardware";
    # disko.url = "github:nix-community/disko";
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "myconfig";
        meta = {
          name = "my-nixos-config";
          title = "My NixOS Configuration";
        };
      };

      channels-config = {
        allowUnfree = true;
      };
    };
}

# Expected directory structure:
# .
# ├── flake.nix
# ├── systems/
# │   └── x86_64-linux/
# │       └── hostname/
# │           └── default.nix
# ├── homes/
# │   └── x86_64-linux/
# │       └── username@hostname/
# │           └── default.nix
# ├── modules/
# │   ├── nixos/
# │   ├── home/
# │   └── shared/
# ├── overlays/
# ├── packages/
# └── lib/
EOF
}

generateHomeManagerTemplate() {
    cat > "$TEMPLATE_DIR/home.nix" << 'EOF'
# Home Manager Configuration
{ config, pkgs, lib, ... }:

{
  home.username = "username";  # CHANGE THIS
  home.homeDirectory = "/home/username";  # CHANGE THIS

  # Packages for this user
  home.packages = with pkgs; [
    # CLI essentials
    ripgrep fd eza bat fzf jq
    htop btop
    
    # Development
    git lazygit
    # neovim
    # vscode
    
    # Add more packages here
  ];

  # Program configurations
  programs.git = {
    enable = true;
    userName = "Your Name";  # CHANGE THIS
    userEmail = "you@example.com";  # CHANGE THIS
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
  };

  # programs.zsh.enable = true;
  # programs.fish.enable = true;
  # programs.starship.enable = true;

  # Dotfile management (example)
  # home.file.".config/example".source = ./config/example;
  # home.file.".config/example".text = ''
  #   configuration content here
  # '';

  # Environment variables
  home.sessionVariables = {
    EDITOR = "nvim";
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;

  home.stateVersion = "24.11";
}
EOF
}

generateNixOSModuleTemplate() {
    cat > "$TEMPLATE_DIR/nixos-module.nix" << 'EOF'
# NixOS Module Template
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.mymodule;  # CHANGE: modules.mymodule
in {
  options.modules.mymodule = {  # CHANGE: modules.mymodule
    enable = mkEnableOption "my module description";

    setting = mkOption {
      type = types.str;
      default = "default value";
      description = "Description of this setting";
    };

    package = mkOption {
      type = types.package;
      default = pkgs.hello;
      description = "Package to use";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Extra configuration";
    };
  };

  config = mkIf cfg.enable {
    # System packages
    environment.systemPackages = [ cfg.package ];

    # Systemd service example
    # systemd.services.myservice = {
    #   description = "My Service";
    #   wantedBy = [ "multi-user.target" ];
    #   serviceConfig = {
    #     ExecStart = "${cfg.package}/bin/hello";
    #     Restart = "always";
    #   };
    # };

    # Configuration file example
    # environment.etc."myconfig.conf".text = ''
    #   setting = ${cfg.setting}
    #   ${cfg.extraConfig}
    # '';
  };
}

# Usage in configuration.nix:
# {
#   imports = [ ./modules/mymodule.nix ];
#   modules.mymodule = {
#     enable = true;
#     setting = "custom value";
#   };
# }
EOF
}

generateHomeModuleTemplate() {
    cat > "$TEMPLATE_DIR/home-module.nix" << 'EOF'
# Home Manager Module Template
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.modules.mymodule;  # CHANGE: modules.mymodule
in {
  options.modules.mymodule = {  # CHANGE: modules.mymodule
    enable = mkEnableOption "my home module";

    theme = mkOption {
      type = types.enum [ "dark" "light" ];
      default = "dark";
      description = "Color theme";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Additional packages";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      # Base packages
    ] ++ cfg.extraPackages;

    # Program configuration
    # programs.myprogram = {
    #   enable = true;
    #   settings = {
    #     theme = cfg.theme;
    #   };
    # };

    # Dotfile
    # home.file.".config/myapp/config".text = ''
    #   theme=${cfg.theme}
    # '';
  };
}
EOF
}

generateDerivationTemplate() {
    cat > "$TEMPLATE_DIR/derivation.nix" << 'EOF'
# Package Derivation Template
{ lib, stdenv, fetchFromGitHub, fetchurl, makeWrapper
, pkg-config, cmake  # build tools
# , dependency1, dependency2  # runtime deps
}:

stdenv.mkDerivation rec {
  pname = "mypackage";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "username";
    repo = pname;
    rev = "v${version}";
    sha256 = lib.fakeSha256;  # Run once, get real hash from error
  };

  # Or fetch tarball:
  # src = fetchurl {
  #   url = "https://example.com/${pname}-${version}.tar.gz";
  #   sha256 = lib.fakeSha256;
  # };

  nativeBuildInputs = [
    pkg-config
    cmake
    makeWrapper
  ];

  buildInputs = [
    # dependency1
    # dependency2
  ];

  # For simple Makefiles:
  # buildPhase = ''
  #   make PREFIX=$out
  # '';
  # installPhase = ''
  #   make install PREFIX=$out
  # '';

  # Post-install wrapper (for PATH/env):
  # postInstall = ''
  #   wrapProgram $out/bin/${pname} \
  #     --prefix PATH : ${lib.makeBinPath [ dependency1 ]}
  # '';

  meta = with lib; {
    description = "Short description";
    longDescription = ''
      Longer description of the package.
    '';
    homepage = "https://example.com";
    license = licenses.mit;  # or gpl3, asl20, etc.
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;  # or platforms.all
  };
}

# Usage in flake:
# packages.x86_64-linux.mypackage = pkgs.callPackage ./derivation.nix { };
#
# Or in configuration.nix:
# environment.systemPackages = [
#   (pkgs.callPackage ./mypackage.nix { })
# ];
EOF
}

generateOverlayTemplate() {
    cat > "$TEMPLATE_DIR/overlay.nix" << 'EOF'
# Overlay Template
# Overlays modify or extend nixpkgs

final: prev: {
  # Add a new package
  mypackage = final.callPackage ./packages/mypackage.nix { };

  # Override existing package version
  # htop = prev.htop.overrideAttrs (old: rec {
  #   version = "3.3.0";
  #   src = prev.fetchFromGitHub {
  #     owner = "htop-dev";
  #     repo = "htop";
  #     rev = version;
  #     sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  #   };
  # });

  # Override package inputs
  # myapp = prev.myapp.override {
  #   someFlag = true;
  #   someDep = final.alternativeDep;
  # };

  # Add package to existing set
  # pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
  #   (python-final: python-prev: {
  #     my-python-package = python-final.callPackage ./my-python-package.nix { };
  #   })
  # ];
}

# Usage in flake.nix:
# nixpkgs.overlays = [ (import ./overlay.nix) ];
#
# Or multiple overlays:
# nixpkgs.overlays = [
#   (import ./overlays/packages.nix)
#   (import ./overlays/modifications.nix)
# ];
EOF
}

generateDevshellTemplate() {
    cat > "$TEMPLATE_DIR/devshell.nix" << 'EOF'
# Development Shell Template
# Use with: nix develop

{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  name = "my-dev-shell";

  # Build inputs (available in shell)
  buildInputs = with pkgs; [
    # Languages
    # python3
    # nodejs
    # rustc cargo
    # go

    # Tools
    git
    # docker-compose
    # kubectl
    
    # LSP/Formatters
    # nil nixfmt  # Nix
    # pyright black  # Python
    # nodePackages.typescript-language-server  # TypeScript
  ];

  # Native build inputs (build tools)
  nativeBuildInputs = with pkgs; [
    pkg-config
    # cmake
    # gnumake
  ];

  # Environment variables
  shellHook = ''
    echo "Entering dev environment..."
    export PROJECT_ROOT="$(pwd)"
    # export DATABASE_URL="postgres://localhost/mydb"
    
    # Aliases for this shell
    alias build="cargo build"
    alias test="cargo test"
  '';

  # For Rust projects
  # RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  # For Python projects
  # LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.cc ];
}

# Usage:
#   nix-shell devshell.nix
#   # or with flakes:
#   nix develop

# Flake integration (in flake.nix outputs):
# devShells.x86_64-linux.default = import ./devshell.nix { inherit pkgs; };
EOF
}

generateDiskoExt4() {
    cat > "$TEMPLATE_DIR/disko-ext4.nix" << 'EOF'
# Disko: Simple ext4 layout
# Best for: Quick installs, VMs, traditional setups
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/CHANGE_ME";  # Run: ls /dev/disk/by-id/
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" "umask=0077" ];
            };
          };
          swap = {
            size = "8G";  # Adjust to RAM size
            content = {
              type = "swap";
              resumeDevice = true;  # For hibernation
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "defaults" "noatime" ];
            };
          };
        };
      };
    };
  };
}

# Apply with:
# sudo nix --experimental-features "nix-command flakes" run \
#   github:nix-community/disko -- --mode disko ./disko-ext4.nix
EOF
}

generateDiskoBtrfs() {
    cat > "$TEMPLATE_DIR/disko-btrfs.nix" << 'EOF'
# Disko: Btrfs with subvolumes
# Best for: Snapshots, compression, modern workstations
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/CHANGE_ME";  # Run: ls /dev/disk/by-id/
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [ "-f" ];  # Force overwrite
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
                "@swap" = {
                  mountpoint = "/swap";
                  swap.swapfile.size = "8G";
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = [ "compress=zstd" "noatime" ];
                };
              };
            };
          };
        };
      };
    };
  };
}
EOF
}

generateDiskoZFS() {
    cat > "$TEMPLATE_DIR/disko-zfs.nix" << 'EOF'
# Disko: ZFS with datasets
# Best for: Data integrity, snapshots, advanced features
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/CHANGE_ME";  # Run: ls /dev/disk/by-id/
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    zpool.rpool = {
      type = "zpool";
      options = {
        ashift = "12";
        autotrim = "on";
      };
      rootFsOptions = {
        compression = "zstd";
        atime = "off";
        xattr = "sa";
        dnodesize = "auto";
      };

      datasets = {
        "root" = {
          type = "zfs_fs";
          mountpoint = "/";
          options.mountpoint = "legacy";
        };
        "nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options = {
            mountpoint = "legacy";
            atime = "off";
          };
        };
        "home" = {
          type = "zfs_fs";
          mountpoint = "/home";
          options.mountpoint = "legacy";
        };
        "persist" = {
          type = "zfs_fs";
          mountpoint = "/persist";
          options.mountpoint = "legacy";
        };
      };
    };
  };
}

# Note: Add to configuration.nix:
# boot.supportedFilesystems = [ "zfs" ];
# networking.hostId = "$(head -c 8 /etc/machine-id)";
EOF
}

generateDiskoLUKS() {
    cat > "$TEMPLATE_DIR/disko-luks-ext4.nix" << 'EOF'
# Disko: LUKS encrypted ext4
# Best for: Laptops, security-focused setups
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/disk/by-id/CHANGE_ME";  # Run: ls /dev/disk/by-id/
      content = {
        type = "gpt";
        partitions = {
          boot = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              settings = {
                allowDiscards = true;
                fallbackToPassword = true;
              };
              # Optional: keyfile for auto-unlock
              # passwordFile = "/tmp/disk-password";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}

# Note: You'll be prompted for encryption password during install
EOF
}

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN MENU
# ═══════════════════════════════════════════════════════════════════════════════

generateTemplates() {
    printf "%b" "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  NIX TEMPLATES GENERATOR                                                       ║
║  Reference templates for NixOS, Home Manager, Flakes, and more                 ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "%b\n" "${RC}"

    printf "%b\n" "${YELLOW}Select templates to generate:${RC}"
    printf "%b\n" ""
    printf "%b\n" "  ${CYAN}FLAKES${RC}"
    printf "%b\n" "  1) Minimal flake (single system)"
    printf "%b\n" "  2) Flake + Home Manager"
    printf "%b\n" "  3) Snowfall Lib flake (scalable)"
    printf "%b\n" ""
    printf "%b\n" "  ${CYAN}CONFIGURATIONS${RC}"
    printf "%b\n" "  4) Home Manager config (home.nix)"
    printf "%b\n" "  5) NixOS module template"
    printf "%b\n" "  6) Home Manager module template"
    printf "%b\n" ""
    printf "%b\n" "  ${CYAN}PACKAGES & DEV${RC}"
    printf "%b\n" "  7) Package derivation template"
    printf "%b\n" "  8) Overlay template"
    printf "%b\n" "  9) Development shell template"
    printf "%b\n" ""
    printf "%b\n" "  ${CYAN}DISKO (Partitioning)${RC}"
    printf "%b\n" "  10) ext4 simple layout"
    printf "%b\n" "  11) Btrfs with subvolumes"
    printf "%b\n" "  12) ZFS with datasets"
    printf "%b\n" "  13) LUKS encrypted ext4"
    printf "%b\n" ""
    printf "%b\n" "  ${GREEN}A) Generate ALL templates${RC}"
    printf "%b\n" "  0) Cancel"
    printf "%b\n" ""
    printf "%b" "${YELLOW}Select [1-13, A, or 0]: ${RC}"
    read -r choice

    case "$choice" in
        0)
            printf "%b\n" "${YELLOW}Cancelled.${RC}"
            return 0
            ;;
        [Aa])
            mkdir -p "$TEMPLATE_DIR"
            generateFlakeMinimal
            generateFlakeHomeManager
            generateFlakeSnowfall
            generateHomeManagerTemplate
            generateNixOSModuleTemplate
            generateHomeModuleTemplate
            generateDerivationTemplate
            generateOverlayTemplate
            generateDevshellTemplate
            generateDiskoExt4
            generateDiskoBtrfs
            generateDiskoZFS
            generateDiskoLUKS
            printf "%b\n" "${GREEN}✓ All templates generated.${RC}"
            ;;
        1)
            mkdir -p "$TEMPLATE_DIR"
            generateFlakeMinimal
            printf "%b\n" "${GREEN}✓ Generated: flake-minimal.nix${RC}"
            ;;
        2)
            mkdir -p "$TEMPLATE_DIR"
            generateFlakeHomeManager
            printf "%b\n" "${GREEN}✓ Generated: flake-home-manager.nix${RC}"
            ;;
        3)
            mkdir -p "$TEMPLATE_DIR"
            generateFlakeSnowfall
            printf "%b\n" "${GREEN}✓ Generated: flake-snowfall.nix${RC}"
            ;;
        4)
            mkdir -p "$TEMPLATE_DIR"
            generateHomeManagerTemplate
            printf "%b\n" "${GREEN}✓ Generated: home.nix${RC}"
            ;;
        5)
            mkdir -p "$TEMPLATE_DIR"
            generateNixOSModuleTemplate
            printf "%b\n" "${GREEN}✓ Generated: nixos-module.nix${RC}"
            ;;
        6)
            mkdir -p "$TEMPLATE_DIR"
            generateHomeModuleTemplate
            printf "%b\n" "${GREEN}✓ Generated: home-module.nix${RC}"
            ;;
        7)
            mkdir -p "$TEMPLATE_DIR"
            generateDerivationTemplate
            printf "%b\n" "${GREEN}✓ Generated: derivation.nix${RC}"
            ;;
        8)
            mkdir -p "$TEMPLATE_DIR"
            generateOverlayTemplate
            printf "%b\n" "${GREEN}✓ Generated: overlay.nix${RC}"
            ;;
        9)
            mkdir -p "$TEMPLATE_DIR"
            generateDevshellTemplate
            printf "%b\n" "${GREEN}✓ Generated: devshell.nix${RC}"
            ;;
        10)
            mkdir -p "$TEMPLATE_DIR"
            generateDiskoExt4
            printf "%b\n" "${GREEN}✓ Generated: disko-ext4.nix${RC}"
            ;;
        11)
            mkdir -p "$TEMPLATE_DIR"
            generateDiskoBtrfs
            printf "%b\n" "${GREEN}✓ Generated: disko-btrfs.nix${RC}"
            ;;
        12)
            mkdir -p "$TEMPLATE_DIR"
            generateDiskoZFS
            printf "%b\n" "${GREEN}✓ Generated: disko-zfs.nix${RC}"
            ;;
        13)
            mkdir -p "$TEMPLATE_DIR"
            generateDiskoLUKS
            printf "%b\n" "${GREEN}✓ Generated: disko-luks-ext4.nix${RC}"
            ;;
        *)
            printf "%b\n" "${RED}Invalid option.${RC}"
            return 1
            ;;
    esac

    printf "%b\n" ""
    printf "%b\n" "${CYAN}Templates saved to: ${YELLOW}${TEMPLATE_DIR}${RC}"
    printf "%b\n" ""
    printf "%b\n" "${CYAN}These are reference files — copy and modify for your config.${RC}"
}

checkArch
generateTemplates
