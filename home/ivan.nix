{ pkgs, lib, ... }:

{
  home.username = "ivan";
  home.homeDirectory = "/home/ivan";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  xdg.enable = true;

  imports = [
    ./ivan/stylix.nix
    ./ivan/vscode.nix
    ./ivan/vivaldi.nix
    ./ivan/rdp.nix
    ./ivan/lazysql.nix
  ];
}
