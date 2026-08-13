{ den, ... }:

{
  den.aspects.comms = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        slacky
        telegram-desktop
      ];
    };

    homeManager.programs.vesktop.enable = true;
  };
}
