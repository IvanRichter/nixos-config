{ den, ... }:

{
  den.aspects.desktop.includes = with den.aspects; [
    workstation
    razer
    memory
    corsair
    crypto
    desktop-eid
    nvidia
  ];

  den.aspects.desktop.nixos =
    {
      pkgs,
      lib,
      ...
    }:

    {
      imports = [ ../../../hosts/desktop/hardware-configuration.nix ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

      programs.nh.flake = "/home/ivan/nixos-config#desktop";
      time.timeZone = "Europe/Prague";
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";

      boot.loader = {
        systemd-boot.enable = false;
        efi.canTouchEfiVariables = true;
        limine = {
          enable = true;
          efiSupport = true;
          biosSupport = false;
        };
      };

      services.fwupd.enable = true;

      # Desktop tuning
      services.system76-scheduler = {
        useStockConfig = false;

        settings = {
          # CFS latency tuning
          cfsProfiles = {
            default = {
              latency = 4;
              wakeup-granularity = 0.5;
              bandwidth-size = 3;
              preempt = "full";
            };

            responsive = {
              latency = 2;
              nr-latency = 6;
              wakeup-granularity = 0.25;
              bandwidth-size = 2;
            };
          };

          # Per-process scheduler control
          processScheduler = {
            refreshInterval = 30;

            # Foreground always wins
            foregroundBoost = {
              foreground.nice = -2;

              background = {
                nice = 8;
                ioClass = "best-effort";
                ioPrio = 4;
              };
            };

            # Audio must never glitch
            pipewireBoost.profile = {
              nice = -10;
              class = "rr";
              prio = 20;
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
    };
}
