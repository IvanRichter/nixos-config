{ den, ... }:

{
  den.aspects.comms = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        slacky
        telegram-desktop
        whatsie
      ];
    };

    homeManager.programs.vesktop = {
      enable = true;
      vencord = {
        useSystem = true;
        mutableSettings = true;
        settings = {
          autoUpdate = false;
          autoUpdateNotification = false;
          plugins.NoTrack.disableAnalytics = true;
        };
      };
    };
  };
}
