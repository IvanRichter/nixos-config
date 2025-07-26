{ config, pkgs, ... }:

{
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    packages = with pkgs; [
      syncthing
    ];
  };

  programs.zsh.enable = true;

  services.syncthing = {
    enable = true;
    user = "ivan";
    dataDir = "/home/ivan";
    configDir = "/home/ivan/.config/syncthing";
  };
}