{ pkgs, lib, osConfig, ... }:

{
  home.username = "ivan";
  home.homeDirectory = "/home/ivan";
  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  xdg.enable = true;

  imports = [
    ./ivan/stylix.nix
    ./ivan/cosmic.nix
    ./ivan/vscode.nix
    ./ivan/vivaldi.nix
    ./ivan/vlc.nix
    ./ivan/office.nix
    ./ivan/rdp.nix
    ./ivan/lazysql.nix
    ./ivan/macchina.nix
    ./ivan/zellij.nix
  ] ++ lib.optionals (osConfig.networking.hostName == "nixos") [
    ./ivan/corsair.nix
  ];
}
