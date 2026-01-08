{ pkgs, ... }:
{
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    # Web pages and schemes
    "text/html" = [ "vivaldi-stable.desktop" ];
    "application/xhtml+xml" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/ftp" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/about" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/unknown" = [ "vivaldi-stable.desktop" ];

    # Common file extensions
    "application/x-extension-htm" = [ "vivaldi-stable.desktop" ];
    "application/x-extension-html" = [ "vivaldi-stable.desktop" ];
    "application/x-extension-shtml" = [ "vivaldi-stable.desktop" ];
    "application/x-extension-xhtml" = [ "vivaldi-stable.desktop" ];

    # PDFs in browser
    "application/pdf" = [ "vivaldi-stable.desktop" ];

    # XML/SVG
    "application/xml" = [ "vivaldi-stable.desktop" ];
    "text/xml" = [ "vivaldi-stable.desktop" ];
    "image/svg+xml" = [ "vivaldi-stable.desktop" ];
  };
}
