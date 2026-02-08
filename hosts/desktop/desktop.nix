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
    ../modules/uutils.nix
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
  services.system76-scheduler = {
    enable = true;
    useStockConfig = false;

    settings = {
      # CFS latency tuning
      cfsProfiles = {
        enable = true;

        default = {
          latency = 4;
          nr-latency = 8;
          wakeup-granularity = 0.5;
          bandwidth-size = 3;
          preempt = "full";
        };

        responsive = {
          latency = 2;
          nr-latency = 6;
          wakeup-granularity = 0.25;
          bandwidth-size = 2;
          preempt = "full";
        };
      };

      # Per-process scheduler control
      processScheduler = {
        enable = true;
        useExecsnoop = true;
        refreshInterval = 30;

        # Foreground always wins
        foregroundBoost = {
          enable = true;

          foreground = {
            nice = -2;
            ioClass = "best-effort";
            ioPrio = 0;
          };

          background = {
            nice = 8;
            ioClass = "best-effort";
            ioPrio = 4;
          };
        };

        # Audio must never glitch
        pipewireBoost = {
          enable = true;
          profile = {
            nice = -10;
            class = "rr";
            prio = 20;
            ioClass = "best-effort";
            ioPrio = 0;
          };
        };
      };
    };

    # Explicit process assignments
    assignments = {
      browsers = {
        nice = -2;
        ioClass = "best-effort";
        ioPrio = 0;
        matchers = [
          "vivaldi"
          "vivaldi-bin"
          "chrome"
          "chromium"
          "firefox"
        ];
      };

      vscode = {
        nice = -2;
        ioClass = "best-effort";
        ioPrio = 0;
        matchers = [
          "code"
          "code-insiders"
          "code-oss"
          "electron"
        ];
      };
    };

    exceptions = [
      "system76-scheduler"
      "schedtool"
    ];
  };

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
