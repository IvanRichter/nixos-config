{ den, ... }:

{
  den.aspects.workstation = {
    includes = with den.aspects; [
      nix
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
      codex
      cli
      comms
      development
      eid
      video
      graphics-apps
    ];

    nixos = { lib, ... }: {
      documentation.man.enable = false;

      i18n.defaultLocale = "en_US.UTF-8";
      time.timeZone = "Europe/Prague";

      services.fwupd.enable = true;

      services.fstrim = {
        enable = true;
        interval = "weekly";
      };
      systemd.services.fstrim.wantedBy = lib.mkForce [ ];
      systemd.timers.fstrim.timerConfig.Persistent = false;
    };
  };
}
