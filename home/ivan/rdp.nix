{ pkgs, ... }:
{
  home.packages = [ pkgs.freerdp ]; # ensures wrapper resolves in PATH

  xdg.desktopEntries."rdp-open" = {
    name = "RDP (FreeRDP)";
    exec = "rdp-open %u";
    icon = "computer";
    type = "Application";
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "application/x-rdp" "application/rdp" ];
  };

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/x-rdp" = [ "rdp-open.desktop" ];
    "application/rdp"   = [ "rdp-open.desktop" ];
  };
}
