{ pkgs ? import <nixpkgs> {} }:

let
  # Use sdflow from parameter (flake) or fetch directly (nix-shell standalone)
  sdflowPkg = (builtins.getFlake "github:whacked/sdflow").packages.${pkgs.system}.default;
in

pkgs.mkShell {
  buildInputs = [
    pkgs.nodejs
    sdflowPkg
  ];  # join lists with ++

  # User-specific shell extensions can be sourced in shellHook if available
  nativeBuildInputs = [
  ];

  name = "yamdb-go";

  shellHook = ''
  '' + ''
    export PATH=$PWD:$PATH
    unset TMP TMPDIR TEMP TEMPDIR
    type echo-shortcuts &>/dev/null && echo-shortcuts ${__curPos.file}
  '';  # join strings with +
}
