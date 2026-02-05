{ pkgs }:
let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
with pkgs;
[
  (if isX86 then google-chrome else chromium)
  firefox
  (vivaldi.override {
    proprietaryCodecs = isX86;
    enableWidevine = isX86;
  })
  servo
]
