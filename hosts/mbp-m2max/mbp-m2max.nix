{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../modules/gui.nix
    ../modules/packages.nix
    ../modules/docker.nix
    ../modules/fonts.nix
    ../modules/nix.nix
    ../modules/rdp.nix
    ../modules/user.nix
  ];

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
  networking.hostName = "mbp-nixos";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Prague";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  # Laptop sanity
  zramSwap.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  systemd.services."home-manager-ivan" = {
    after  = [ "network-online.target" ];
    wants  = [ "network-online.target" ];
    # HM module sets 5m, force value
    serviceConfig.TimeoutStartSec = lib.mkForce "10min";
  };
  
  # Firmware
  hardware.asahi = {
    enable = true;
  };

  # Keyboard: Ctrl, Fn, Super, Alt

  # Kernel modules
  boot.kernelModules = [ "hid_apple" "uinput" ];

  # Fn <-> Left Ctrl, Option <-> Command, make F1–F12 real keys
  boot.extraModprobeConfig = ''
    options hid_apple swap_fn_leftctrl=1 swap_opt_cmd=1 fnmode=2
  '';

  # uinput for keyd
  hardware.uinput.enable = true;

  # Right Cmd -> Delete
  services.keyd.enable = true;
  environment.etc."keyd/default.conf".text = ''
    [ids]
    *

    [main]
    rightmeta = delete
  '';
}
