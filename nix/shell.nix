{ pkgs }:

let
  mainPkg = if builtins.pathExists ./default.nix then pkgs.callPackage ./default.nix { } else { };

  pkgInputs =
    with pkgs;
    [
      clippy
      rustfmt
      rust-analyzer
      bash-language-server
      checkbashisms
      shellcheck
      typos
      vhs
    ]
    ++ (mainPkg.nativeBuildInputs or [ ])
    ++ (mainPkg.buildInputs or [ ]);
in
pkgs.mkShell {
  packages = pkgInputs;

  shellHook = ''
    echo -ne "-----------------------------------\n "

    echo -n "${toString (map (pkg: "• ${pkg.name}\n") pkgInputs)}"

    echo "-----------------------------------"
  '';
}
