{ lib, pkgs, ... }:
let
  isX86 = pkgs.stdenv.hostPlatform.isx86_64;
in
{
  programs.chromium.enable = true;

  programs.vivaldi = {
    enable = true;
    package = pkgs.vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = true;
    };
  };

  programs.google-chrome.enable = isX86;
}
