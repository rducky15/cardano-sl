{ nodejs ? pkgs."nodejs-6_x", pkgs ? import <nixpkgs> {
  inherit system;
}, src, system ? builtins.currentSystem }:
let
    nodeEnv = import ./node-env.nix {
      inherit (pkgs) stdenv python2
      utillinux runCommand
      writeTextFile;
      inherit nodejs;
    };
    in import ./node-packages.nix {
      inherit src;
      inherit (pkgs) fetchurl
      fetchgit;
      inherit nodeEnv;
    }