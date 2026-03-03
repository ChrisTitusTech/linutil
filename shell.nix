# shell.nix — Drop this in any folder, run: nix-shell
# For LinUtil testing and contribution
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "linutil-dev";

  packages = with pkgs; [
    # Rust (required to build LinUtil)
    rustc
    cargo
    rustfmt
    clippy

    # Build deps
    pkg-config
    openssl
    gcc

    # Script linting (LinUtil CI requires these)
    shellcheck
    checkbashisms
    typos

    # Git workflow
    git
    gh
  ];

  env = {
    RUST_BACKTRACE = "1";
  };

  shellHook = ''
    echo ""
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  🦀 LinUtil Dev Shell                                ║"
    echo "  ╠══════════════════════════════════════════════════════╣"
    echo "  ║  cargo run          → Test LinUtil TUI               ║"
    echo "  ║  shellcheck -s sh -e SC1091 script.sh  → Lint        ║"
    echo "  ║  ./sort-tomlfiles.sh  → Sort TOML before commit      ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo ""
  '';
}
