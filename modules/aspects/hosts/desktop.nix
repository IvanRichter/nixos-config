{ den, inputs, ... }:

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

  den.aspects.desktop.nixpkgs-overlays = _: {
    kernel-stock = import "${inputs.self}/overlays/kernel/stock.nix";
  };

  den.aspects.desktop.nixos =
    {
      pkgs,
      ...
    }:

    {
      imports = [ "${inputs.self}/hardware/desktop/hardware-configuration.nix" ];

      boot.kernelPackages = pkgs.linuxPackages_latest;

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

      # Desktop tuning
      services.system76-scheduler = {
        useStockConfig = false;

        settings = {
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
    };
}
