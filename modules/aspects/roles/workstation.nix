{ den, ... }:

{
  den.aspects.workstation = {
    includes = with den.aspects; [
      nix
      users
      fonts
      graphics
      stylix
      cosmic
      gui
      networking
      docker
      programs
      browsers
      iloader
      utils
      games
      ai
      claude
      codex
      cli
      comms
      development
      eid
      video
      graphics-apps
    ];

    nixos = { lib, ... }: {
      boot.loader = {
        systemd-boot.enable = false;
        efi.canTouchEfiVariables = true;
        limine = {
          enable = true;
          efiSupport = true;
          biosSupport = false;
          maxGenerations = 5;
        };
      };

      documentation.man.enable = false;

      i18n.defaultLocale = "en_US.UTF-8";
      time.timeZone = "Europe/Prague";

      services.fwupd.enable = true;
      systemd.timers.fwupd-refresh.enable = false;

      services.fstrim = {
        enable = true;
        interval = "weekly";
      };
      systemd.services.fstrim.wantedBy = lib.mkForce [ ];
      systemd.timers.fstrim.timerConfig.Persistent = false;
    };
  };
}
