{ den, ... }:

{
  den.aspects.ivan = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
      (den.batteries.user-shell "fish")
      den.batteries.host-aspects
      den.aspects.starship
      den.aspects.kitty
      den.aspects.fish
      den.aspects.vscode
      den.aspects.office
      den.aspects.rdp
      den.aspects.gcloud
      den.aspects.gws
      den.aspects.tabularis
      den.aspects.macchina
      den.aspects.zellij
    ];

    user.extraGroups = [
      "video"
      "render"
      "plugdev"
    ];

    homeManager =
      { config, ... }:
      let
        home = config.home.homeDirectory;
      in
      {
        programs.home-manager.enable = true;
        xdg.enable = true;

        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          desktop = "${home}/desktop";
          documents = "${home}/documents";
          download = "${home}/downloads";
          music = "${home}/music";
          pictures = "${home}/pictures";
          projects = "${home}/projects";
          publicShare = "${home}/public";
          templates = "${home}/templates";
          videos = "${home}/videos";
          extraConfig = {
            ANRIKU = "${home}/anriku";
            NIXOS = "${home}/nixos-config";
            WORK = "${home}/work";
          };
        };

        gtk.gtk3.bookmarks = [
          "file://${home}/anriku"
          "file://${home}/nixos-config"
          "file://${home}/work"
        ];
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
        settings.options = {
          urAccepted = -1;
          crashReportingEnabled = false;
        };
      };

      security.sudo-rs.enable = true;
    };
  };
}
