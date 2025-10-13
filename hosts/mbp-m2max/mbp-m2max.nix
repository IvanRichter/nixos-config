{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../modules/gui.nix
    ../modules/cosmic.nix
    ../modules/graphics.nix
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

  # Make s2idle as safe as it can be on Asahi

  # Force s2idle explicitly
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
  ];

  # Lid close uses suspend (s2idle)
  services.logind.settings = {
    Login = {
      # close lid = suspend
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "suspend";

      # never idle-suspend, respect app inhibitors
      IdleAction = "ignore";
      LidSwitchIgnoreInhibited = "no";
    };
  };

  # Pre/post sleep guardrails:
  #  - pre: sync writes, drop caches, remount / read-only
  #  - post: remount / read-write
  # This prevents unclean unmount on resume
  environment.etc."systemd/system-sleep/10-safe-suspend".text = ''
    #!/bin/sh
    set -eu
    case "$1" in
      pre)
        sync
        echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
        mount -o remount,ro / 2>/dev/null || true
        ;;
      post)
        mount -o remount,rw / 2>/dev/null || true
        ;;
    esac
  '';
  environment.etc."systemd/system-sleep/10-safe-suspend".mode = "0755";

  # Run fsck in initrd if journal looks dirty
  boot.initrd.checkJournalingFS = true;
}
