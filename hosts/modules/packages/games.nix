{ pkgs, lib, ... }:

let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
lib.mkMerge [
  {
    environment.systemPackages = with pkgs; [
      bottles
    ];
  }

  (lib.mkIf isX86 {
    programs.steam = {
      enable = true;
      extest.enable = true;
      protontricks.enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };

    programs.gamemode.enable = true;
  })
]
