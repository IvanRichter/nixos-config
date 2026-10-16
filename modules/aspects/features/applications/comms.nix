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

    homeManager.programs.vesktop.enable = true;
  };
}
