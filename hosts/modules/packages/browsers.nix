{ pkgs, lib, ... }:
let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  programs.firefox.enable = true;

  environment.systemPackages =
    with pkgs;
    [
      servo
    ]
    ++ lib.optionals isX86 [
      tor-browser
    ];
}
