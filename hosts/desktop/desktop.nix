{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./razer.nix
    ./vivaldi.nix
    ./memory.nix
    ./chrome.nix
    ./corsair.nix
    ./eid.nix

    ../modules/nix.nix
    ../modules/user.nix
    ../modules/fonts.nix
    ../modules/graphics.nix
    ../modules/nvidia.nix
    ../modules/stylix.nix
    ../modules/cosmic.nix
    ../modules/gui.nix
    ../modules/networking.nix
    ../modules/docker.nix
    ../modules/rdp.nix
    ../modules/packages.nix
  ];

  nixpkgs.config.allowUnfree = true;
  boot.kernelPackages = pkgs.linuxPackages_lqx_v4;

  system.stateVersion = "25.11";
  networking.hostName = "nixos";
  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Desktop tuning
  services.system76-scheduler.enable = true;
  powerManagement.cpuFreqGovernor = "performance";
  boot.kernelParams = [
    "amd_pstate=active"
    "amd_iommu=on"
    "iommu=pt"
  ];

  services.fstrim.enable = true;
  services.fstrim.interval = "weekly";
  systemd.services.fstrim.wantedBy = lib.mkForce [ ];
  systemd.timers.fstrim.timerConfig.Persistent = false;

  systemd.services."home-manager-ivan" = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    # HM module sets 5m, force value
    serviceConfig.TimeoutStartSec = lib.mkForce "10min";
  };
}
