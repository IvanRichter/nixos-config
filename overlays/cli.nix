final: prev:

let
  lib = prev.lib;
  pkgs = prev;
  isDesktop = prev.stdenv.hostPlatform.system == "x86_64-linux";

  rustOpt = import ./helpers/rust-opt.nix { inherit lib pkgs; };

  rustPkgs = [
    "zoxide"
    "skim"
  ];
in
if !isDesktop then { } else lib.genAttrs rustPkgs (n: rustOpt prev.${n})
