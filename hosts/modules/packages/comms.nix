{ pkgs }:
let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
with pkgs;
[
  vesktop
]
++  (if isX86 then [slack] else [])
