#!/bin/sh -e

. ../common-script.sh

# ═══════════════════════════════════════════════════════════════════════════════
# NIX FLAKE SCAFFOLD GENERATOR
# Creates a Snowfall-style directory structure for NixOS/Home Manager configs
# ═══════════════════════════════════════════════════════════════════════════════

scaffoldFlake() {
    printf "%b" "${CYAN}"
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════════╗
║  NIX FLAKE SCAFFOLD GENERATOR                                                  ║
║  Creates a Snowfall-style directory structure                                  ║
╚════════════════════════════════════════════════════════════════════════════════╝
EOF
    printf "%b\n" "${RC}"

    # Get project location
    printf "%b" "${YELLOW}Project path [~/dotfiles]: ${RC}"
    read -r PROJECT_PATH
    PROJECT_PATH="${PROJECT_PATH:-$HOME/dotfiles}"
    
    # Expand tilde safely (no eval)
    case "$PROJECT_PATH" in
        ~/*) PROJECT_PATH="$HOME/${PROJECT_PATH#\~/}" ;;
        ~) PROJECT_PATH="$HOME" ;;
    esac

    if [ -d "$PROJECT_PATH" ] && [ "$(ls -A "$PROJECT_PATH" 2>/dev/null)" ]; then
        printf "%b\n" "${RED}Directory exists and is not empty: ${PROJECT_PATH}${RC}"
        printf "%b" "${YELLOW}Continue anyway? [y/N]: ${RC}"
        read -r confirm
        case "$confirm" in
            [yY]|[yY][eE][sS]) : ;;
            *) printf "%b\n" "${YELLOW}Cancelled.${RC}"; return 0 ;;
        esac
    fi

    # Get hostname
    CURRENT_HOST=$(hostname 2>/dev/null || cat /etc/hostname 2>/dev/null || echo "nixos")
    printf "%b" "${YELLOW}Hostname [${CURRENT_HOST}]: ${RC}"
    read -r HOSTNAME
    HOSTNAME="${HOSTNAME:-$CURRENT_HOST}"

    # Get username
    CURRENT_USER=$(whoami)
    printf "%b" "${YELLOW}Username [${CURRENT_USER}]: ${RC}"
    read -r USERNAME
    USERNAME="${USERNAME:-$CURRENT_USER}"

    # Get architecture
    CURRENT_ARCH=$(uname -m)
    case "$CURRENT_ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *) ARCH="x86_64" ;;
    esac
    printf "%b" "${YELLOW}Architecture [${ARCH}]: ${RC}"
    read -r INPUT_ARCH
    ARCH="${INPUT_ARCH:-$ARCH}"

    # What to include
    printf "%b\n" ""
    printf "%b\n" "${CYAN}Include support for:${RC}"
    printf "%b" "${YELLOW}  NixOS system config? [Y/n]: ${RC}"
    read -r INCLUDE_NIXOS
    case "$INCLUDE_NIXOS" in
        [nN]|[nN][oO]) INCLUDE_NIXOS="no" ;;
        *) INCLUDE_NIXOS="yes" ;;
    esac

    printf "%b" "${YELLOW}  Home Manager? [Y/n]: ${RC}"
    read -r INCLUDE_HOME
    case "$INCLUDE_HOME" in
        [nN]|[nN][oO]) INCLUDE_HOME="no" ;;
        *) INCLUDE_HOME="yes" ;;
    esac

    printf "%b" "${YELLOW}  macOS/Darwin? [y/N]: ${RC}"
    read -r INCLUDE_DARWIN
    case "$INCLUDE_DARWIN" in
        [yY]|[yY][eE][sS]) INCLUDE_DARWIN="yes" ;;
        *) INCLUDE_DARWIN="no" ;;
    esac

    printf "%b" "${YELLOW}  Generate starter flake.nix? [Y/n]: ${RC}"
    read -r GEN_FLAKE
    case "$GEN_FLAKE" in
        [nN]|[nN][oO]) GEN_FLAKE="no" ;;
        *) GEN_FLAKE="yes" ;;
    esac

    # ═══════════════════════════════════════════════════════════════════════════
    # CREATE STRUCTURE
    # ═══════════════════════════════════════════════════════════════════════════
    
    printf "%b\n" ""
    printf "%b\n" "${YELLOW}Creating scaffold...${RC}"

    mkdir -p "$PROJECT_PATH"
    cd "$PROJECT_PATH"

    # Core directories (always)
    mkdir -p lib
    mkdir -p modules/shared
    mkdir -p overlays
    mkdir -p packages

    # NixOS
    if [ "$INCLUDE_NIXOS" = "yes" ]; then
        mkdir -p "systems/${ARCH}-linux/${HOSTNAME}"
        mkdir -p modules/nixos
    fi

    # Home Manager
    if [ "$INCLUDE_HOME" = "yes" ]; then
        mkdir -p "homes/${ARCH}-linux/${USERNAME}@${HOSTNAME}"
        mkdir -p modules/home
    fi

    # Darwin
    if [ "$INCLUDE_DARWIN" = "yes" ]; then
        mkdir -p "systems/${ARCH}-darwin/${HOSTNAME}"
        mkdir -p modules/darwin
    fi

    # ═══════════════════════════════════════════════════════════════════════════
    # CREATE STARTER FILES
    # ═══════════════════════════════════════════════════════════════════════════

    # lib/default.nix
    cat > lib/default.nix << 'LIBEOF'
# Custom library functions
# Called with: inputs, snowfall-inputs, lib
# Returns: attribute set merged with lib
{ inputs, snowfall-inputs, lib }:

{
  # Add custom lib functions here
  # example = x: x + 1;
}
LIBEOF

    # NixOS system config
    if [ "$INCLUDE_NIXOS" = "yes" ]; then
        cat > "systems/${ARCH}-linux/${HOSTNAME}/default.nix" << SYSEOF
# System configuration for ${HOSTNAME}
{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.hostName = "${HOSTNAME}";
  networking.networkmanager.enable = true;

  # Timezone
  time.timeZone = "America/New_York";  # Change this

  # Users
  users.users.${USERNAME} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
  ];

  # Enable flakes (if not using Determinate installer)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  system.stateVersion = "25.11";
}
SYSEOF

        # Placeholder hardware-configuration.nix
        cat > "systems/${ARCH}-linux/${HOSTNAME}/hardware-configuration.nix" << 'HWEOF'
# Hardware configuration
# Replace this with output from: nixos-generate-config --show-hardware-config
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # TODO: Run nixos-generate-config and copy hardware-configuration.nix here
  # Or run: nixos-generate-config --show-hardware-config > hardware-configuration.nix

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.kernelModules = [ "kvm-intel" ];  # or kvm-amd

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };
}
HWEOF
    fi

    # Home Manager config
    if [ "$INCLUDE_HOME" = "yes" ]; then
        cat > "homes/${ARCH}-linux/${USERNAME}@${HOSTNAME}/default.nix" << HOMEEOF
# Home configuration for ${USERNAME}@${HOSTNAME}
{ config, pkgs, lib, ... }:

{
  home.username = "${USERNAME}";
  home.homeDirectory = "/home/${USERNAME}";

  # Packages for this user
  home.packages = with pkgs; [
    # CLI tools
    ripgrep
    fd
    eza
    bat
    fzf

    # Dev tools
    # nodejs
    # python3
  ];

  # Dotfile management
  # home.file.".config/example".source = ./config/example;

  # Program configurations
  programs.git = {
    enable = true;
    userName = "${USERNAME}";
    userEmail = "you@example.com";  # Change this
  };

  programs.bash.enable = true;
  # programs.zsh.enable = true;
  # programs.fish.enable = true;

  home.stateVersion = "25.11";
}
HOMEEOF
    fi

    # Darwin config
    if [ "$INCLUDE_DARWIN" = "yes" ]; then
        cat > "systems/${ARCH}-darwin/${HOSTNAME}/default.nix" << DARWINEOF
# Darwin configuration for ${HOSTNAME}
{ config, pkgs, lib, ... }:

{
  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
  ];

  # Enable nix-daemon
  services.nix-daemon.enable = true;

  # Shells
  programs.zsh.enable = true;

  # System defaults
  system.defaults = {
    dock.autohide = true;
    finder.AppleShowAllExtensions = true;
  };

  system.stateVersion = 4;
}
DARWINEOF
    fi

    # Module templates
    if [ "$INCLUDE_NIXOS" = "yes" ]; then
        cat > modules/nixos/.gitkeep << 'EOF'
# NixOS modules go here
# Example: modules/nixos/desktop/default.nix
EOF
    fi

    if [ "$INCLUDE_HOME" = "yes" ]; then
        cat > modules/home/.gitkeep << 'EOF'
# Home Manager modules go here
# Example: modules/home/shell/default.nix
EOF
    fi

    cat > modules/shared/.gitkeep << 'EOF'
# Shared modules (used by both NixOS and Home Manager)
EOF

    cat > overlays/.gitkeep << 'EOF'
# Custom overlays go here
# Example: overlays/my-overlay/default.nix
EOF

    cat > packages/.gitkeep << 'EOF'
# Custom packages go here
# Example: packages/my-app/default.nix
EOF

    # ═══════════════════════════════════════════════════════════════════════════
    # GENERATE FLAKE.NIX
    # ═══════════════════════════════════════════════════════════════════════════

    if [ "$GEN_FLAKE" = "yes" ]; then
        cat > flake.nix << FLAKEEOF
{
  description = "NixOS configuration with Snowfall Lib";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };
FLAKEEOF

        if [ "$INCLUDE_HOME" = "yes" ]; then
            cat >> flake.nix << 'FLAKEEOF'

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
FLAKEEOF
        fi

        if [ "$INCLUDE_DARWIN" = "yes" ]; then
            cat >> flake.nix << 'FLAKEEOF'

    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
FLAKEEOF
        fi

        cat >> flake.nix << 'FLAKEEOF'
  };

  outputs = inputs:
    inputs.snowfall-lib.mkFlake {
      inherit inputs;
      src = ./.;

      snowfall = {
        namespace = "custom";  # Change this to your namespace
        meta = {
          name = "my-flake";
          title = "My NixOS Configuration";
        };
      };

      channels-config = {
        allowUnfree = true;
      };
    };
}
FLAKEEOF
    fi

    # README
    cat > README.md << READMEEOF
# NixOS Configuration

Snowfall Lib-based NixOS/Home Manager configuration.

## Structure

\`\`\`
.
├── flake.nix              # Flake definition
├── lib/                   # Custom library functions
├── systems/               # System configurations
│   └── ${ARCH}-linux/
│       └── ${HOSTNAME}/
├── homes/                 # Home Manager configurations
│   └── ${ARCH}-linux/
│       └── ${USERNAME}@${HOSTNAME}/
├── modules/
│   ├── nixos/             # NixOS modules
│   ├── home/              # Home Manager modules
│   └── shared/            # Shared modules
├── overlays/              # Package overlays
└── packages/              # Custom packages
\`\`\`

## Usage

### Build system
\`\`\`bash
sudo nixos-rebuild switch --flake .#${HOSTNAME}
\`\`\`

### Build home
\`\`\`bash
home-manager switch --flake .#${USERNAME}@${HOSTNAME}
\`\`\`

### Update flake
\`\`\`bash
nix flake update
\`\`\`

## Resources

- [Snowfall Lib](https://snowfall.org)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
READMEEOF

    # .gitignore
    cat > .gitignore << 'GITEOF'
result
result-*
.direnv/
.pre-commit-config.yaml
GITEOF

    # ═══════════════════════════════════════════════════════════════════════════
    # DONE
    # ═══════════════════════════════════════════════════════════════════════════

    printf "%b\n" ""
    printf "%b\n" "${GREEN}✓ Scaffold created at: ${PROJECT_PATH}${RC}"
    printf "%b\n" ""
    
    printf "%b" "${CYAN}"
    cat << EOF
══════════════════════════════════════════════════════════════════════════════
  STRUCTURE CREATED
══════════════════════════════════════════════════════════════════════════════
EOF
    
    # Show tree if available, otherwise basic ls
    if command_exists tree; then
        tree -a -I '.git' --dirsfirst "$PROJECT_PATH" 2>/dev/null || ls -la "$PROJECT_PATH"
    else
        find "$PROJECT_PATH" -type f | head -20 | sed "s|$PROJECT_PATH|.|g"
    fi
    
    printf "%b\n" "${RC}"
    printf "%b" "${CYAN}"
    cat << 'EOF'
══════════════════════════════════════════════════════════════════════════════
  NEXT STEPS
══════════════════════════════════════════════════════════════════════════════
  1. cd ~/dotfiles  (or your chosen path)
  
  2. Copy your hardware config:
     sudo nixos-generate-config --show-hardware-config > \
       systems/x86_64-linux/<host>/hardware-configuration.nix
  
  3. Edit your configs:
     - systems/<arch>-linux/<host>/default.nix    (system config)
     - homes/<arch>-linux/<user>@<host>/default.nix (user config)
  
  4. Initialize git:
     git init && git add -A && git commit -m "Initial scaffold"
  
  5. Build:
     sudo nixos-rebuild switch --flake .#<hostname>
     home-manager switch --flake .#<user>@<hostname>
══════════════════════════════════════════════════════════════════════════════
EOF
    printf "%b\n" "${RC}"
}

checkArch
scaffoldFlake
