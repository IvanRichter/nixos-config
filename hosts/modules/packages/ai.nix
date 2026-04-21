{ pkgs }:
let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
with pkgs;
[
  beads
]
++ lib.optionals isX86 [
  lmstudio
  openclaw
]
