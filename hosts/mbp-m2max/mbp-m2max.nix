{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../modules/gui.nix
    ../modules/cosmic.nix
    ../modules/graphics.nix
    ../modules/packages.nix
    ../modules/docker.nix
    ../modules/fonts.nix
    ../modules/networking.nix
    ../modules/nix.nix
    ../modules/rdp.nix
    ../modules/user.nix
    ../modules/stylix.nix
  ];

  environment.systemPackages = with pkgs; [
    triforce-lv2
  ];

  # Platform & licensing
  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  # Bootloader
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 3;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # System identity
  system.stateVersion = "25.11";
  networking.hostName = "mbp-nixos";
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Prague";

  # SSH
  services.openssh.enable = true;

  # Memory / swap
  zramSwap = {
    enable = true;
    memoryPercent = 50;
    algorithm = "zstd";
    priority = 100;
  };
  boot.kernel.sysctl = {
    "vm.swappiness" = 80;
    "vm.vfs_cache_pressure" = 50;
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  systemd.services."home-manager-ivan" = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig.TimeoutStartSec = lib.mkForce "10min";
  };

  # Firmware
  hardware.asahi.enable = true;

  # Keyboard / input
  boot.kernelModules = [
    "hid_apple"
    "uinput"
  ];

  # Fn <-> Ctrl, Opt <-> Cmd, F1–F12 as real keys
  boot.extraModprobeConfig = ''
    options hid_apple swap_fn_leftctrl=1 swap_opt_cmd=1 fnmode=2
  '';

  hardware.uinput.enable = true;

  # Right Cmd -> Delete
  services.keyd.enable = true;
  environment.etc."keyd/default.conf".text = ''
    [ids]
    *

    [main]
    rightmeta = delete
  '';

  # -- Power management & display tweaks --
  # Force s2idle + tweak PCI/USB behavior
  # Enable full native panel (disable fake black bar over notch)
  boot.kernelParams = [
    "mem_sleep_default=s2idle"
    "usbcore.autosuspend=1"
    "pci=pcie_bus_perf"
    "appledrm.show_notch=1"
  ];
  services.system76-scheduler.enable = true;

  # Align systemd sleep with kernel
  systemd.sleep.extraConfig = ''
    SuspendState=mem
    SuspendMode=s2idle
  '';

  # Lid behavior
  services.logind.settings = {
    Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "suspend";
      IdleAction = "ignore";
      LidSwitchIgnoreInhibited = false;
      KillUserProcesses = true;
    };
  };

  # Power profiles
  services.power-profiles-daemon.enable = true;

  # Disable OOM killer
  systemd.oomd.enable = false;

  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
  systemd.services.fstrim.wantedBy = lib.mkForce [ ];
  systemd.timers.fstrim.timerConfig.Persistent = false;

  # Disable USB/BT wakeups
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
    SUBSYSTEM=="bluetooth", TEST=="power/wakeup", ATTR{power/wakeup}="disabled"
  '';

  # -- Sleep hook --
  environment.etc."systemd/system-sleep/10-safe-suspend".text = ''
    #!/bin/sh
    set -eu
    case "$1" in
      pre)
        sync
        ;;
      post)
        :
        ;;
    esac
  '';
  environment.etc."systemd/system-sleep/10-safe-suspend".mode = "0755";

  # Run fsck in initrd if journal looks dirty
  boot.initrd.checkJournalingFS = true;
}
