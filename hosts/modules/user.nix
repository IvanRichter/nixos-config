{ config, pkgs, ... }:

{
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  programs.zsh.enable = true;
}