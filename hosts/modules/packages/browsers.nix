{ pkgs, lib, ... }:
let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  programs.firefox.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      chromium
      (vivaldi.override {
        proprietaryCodecs = true;
        enableWidevine = true;
      })
      servo
    ]
    ++ lib.optionals isX86 [
      google-chrome
      tor-browser
    ];
}
