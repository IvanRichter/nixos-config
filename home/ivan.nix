{ pkgs, lib, ... }:

{
  home.username = "ivan";
  home.homeDirectory = "/home/ivan";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  xdg.enable = true;

  imports = [
    ./ivan/vscode.nix
    ./ivan/vivaldi.nix
    ./ivan/rdp.nix
  ];

  # WezTerm
  home.file.".config/wezterm/wezterm.lua".source = ../dotfiles/wezterm.lua;
}
