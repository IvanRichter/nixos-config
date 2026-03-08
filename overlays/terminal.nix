final: prev:

let
  lib = prev.lib;
  pkgs = prev;
  isDesktop = prev.stdenv.hostPlatform.system == "x86_64-linux";

  rustOpt = import ./helpers/rust-opt.nix { inherit lib pkgs; };
  cOpt = import ./helpers/c-opt.nix { inherit lib pkgs; };

  rustPkgs = [
    "rio"
    "starship"
    "zellij"
  ];
in
if !isDesktop then
  { }
else
  (lib.genAttrs rustPkgs (n: rustOpt prev.${n}))
  // {
    fish = cOpt (rustOpt prev.fish);
  }
