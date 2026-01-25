{ pkgs, lib, ... }:

let
  vlcDesktop = [ "vlc.desktop" ];
  # Derive all video/* MIME types from shared-mime-info
  videoMimeTypes =
    let
      typesFile = "${pkgs.shared-mime-info}/share/mime/types";
      lines = lib.splitString "\n" (builtins.readFile typesFile);
    in
    lib.filter (t: lib.hasPrefix "video/" t) lines;
in
{
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = lib.genAttrs videoMimeTypes (_: vlcDesktop);

  xdg.configFile."vlc/vlcrc".text = ''
    qt-privacy-ask=0
    metadata-network-access=0
  '';
}
