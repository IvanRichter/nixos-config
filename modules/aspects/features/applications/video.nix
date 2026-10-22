{ den, ... }:

{
  den.aspects.video = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = with pkgs; [
        ffmpeg-full
        vlc
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
