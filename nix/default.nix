{
  lib,
  rustPlatform,
}:

let
  p = (lib.importTOML ../Cargo.toml).workspace.package;
  pTUI = (lib.importTOML ../tui/Cargo.toml).package;
in
rustPlatform.buildRustPackage {
  pname = "linutil";
  inherit (p) version;

  src = ../.;

  cargoLock.lockFile = ../Cargo.lock;

  meta = {
    inherit (pTUI) description;
    homepage = pTUI.documentation;
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ adamperkowski ];
    mainProgram = "linutil";
  };
}
