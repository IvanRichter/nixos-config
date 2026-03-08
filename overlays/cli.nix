final: prev:

let
  lib = prev.lib;
  pkgs = prev;
  isDesktop = prev.stdenv.hostPlatform.system == "x86_64-linux";

  rustOpt = import ./helpers/rust-opt.nix { inherit lib pkgs; };
  cOpt = import ./helpers/c-opt.nix { inherit lib pkgs; };

  rustPkgs = [
    "ripgrep"
    "fd"
    "zoxide"
    "skim"
    "sd"
    "jaq"
    "wl-clipboard-rs"
    "eza"
    "ast-grep"
  ];

  cPkgs = [
    "tree"
    "lsof"
  ];

in
if !isDesktop then
  { }
else
  (lib.genAttrs rustPkgs (n: rustOpt prev.${n})) // (lib.genAttrs cPkgs (n: cOpt prev.${n}))
