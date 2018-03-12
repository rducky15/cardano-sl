let
  localLib = import ../../../lib.nix;
in
{ system ? builtins.currentSystem
, config ? {}
, pkgs ? (import (localLib.fetchNixPkgs) { inherit system config; })
}:

let 
  ghc = pkgs.haskellPackages.ghcWithPackages (ps: [ps.turtle ps.hnix]);

in
  pkgs.stdenv.mkDerivation {
    name = "explorer-frontend-shell";
    buildInputs = with pkgs; [ nodePackages.bower2nix nodePackages.node2nix ghc coreutils ];
    shellHook = "eval $(egrep ^export ${ghc}/bin/ghc)";
    src = null;
  }
