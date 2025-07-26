{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix

    ../modules/nix.nix
    ../modules/user.nix
    ../modules/fonts.nix
    ../modules/graphics.nix
    ../modules/gui.nix
    ../modules/networking.nix
    ../modules/docker.nix
    ../modules/packages.nix
  ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
  networking.hostName = "nixos";
  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}