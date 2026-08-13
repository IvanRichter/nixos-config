{ den, ... }:

{
  den.aspects.ivan = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "fish")
      den.batteries.host-aspects
      den.aspects.starship
      den.aspects.rio
      den.aspects.fish
      den.aspects.vscode
      den.aspects.office
      den.aspects.rdp
      den.aspects.gcloud
      den.aspects.lazysql
      den.aspects.dbeaver
      den.aspects.tabularis
      den.aspects.macchina
      den.aspects.zellij
    ];

    user.extraGroups = [
      "docker"
      "video"
      "render"
      "plugdev"
    ];

    homeManager = {
      programs.home-manager.enable = true;
      xdg.enable = true;
    };

    provides.to-hosts.nixos = {
      programs.fish.useBabelfish = true;

      services.syncthing = {
        enable = true;
        user = "ivan";
        dataDir = "/home/ivan";
        configDir = "/home/ivan/.config/syncthing";
        openDefaultPorts = true;
        overrideDevices = false;
        overrideFolders = false;
      };

      security.sudo-rs.enable = true;
    };
  };
}
