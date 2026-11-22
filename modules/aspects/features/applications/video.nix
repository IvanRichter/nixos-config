{ den, ... }:

{
  den.aspects.video = {
    nixos = { host, pkgs, ... }: {
      programs.vlc = {
        enable = true;
        chromecast.openFirewall = host.hasAspect den.aspects.laptop;
      };

      environment.systemPackages = with pkgs; [
        ffmpeg-full
        stremio-linux-shell
      ];
    };

    homeManager = {
      xdg.mimeApps.enable = true;
      xdg.mimeApps.defaultApplications."video/*" = [ "vlc.desktop" ];

      xdg.configFile."vlc/vlcrc".text = ''
        qt-privacy-ask=0
        metadata-network-access=0
      '';
    };
  };
}
