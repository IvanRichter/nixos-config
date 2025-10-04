{ pkgs, lib, ... }:

{
  home.username = "ivan";
  home.homeDirectory = "/home/ivan";
  home.stateVersion = "25.05";

  programs.home-manager.enable = true;

  # Make sure XDG dirs are managed so HM writes to ~/.local/share/applications
  xdg.enable = true;

  imports = [
    ./ivan/vscode.nix
  ];

  # Ensure tools to refresh caches are present
  home.packages = [
    pkgs.freerdp
    pkgs.shared-mime-info        # update-mime-database
    pkgs.desktop-file-utils      # update-desktop-database
  ];
  
  # WezTerm
  home.file.".config/wezterm/wezterm.lua".source = ../dotfiles/wezterm.lua;

  # Desktop entry that launches FreeRDP with sane flags
  xdg.desktopEntries."rdp-open" = {
    name = "RDP (FreeRDP)";
    exec = "${pkgs.freerdp}/bin/xfreerdp %u /cert:ignore /dynamic-resolution +clipboard /sound:sys:pulse";
    icon = "computer";
    type = "Application";
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "application/x-rdp" "application/rdp" ];
    terminal = false;
  };

  # *.rdp mime-info
  home.file.".local/share/mime/packages/rdp.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-rdp">
        <comment>Remote Desktop Protocol</comment>
        <glob pattern="*.rdp"/>
      </mime-type>
      <mime-type type="application/rdp">
        <comment>Remote Desktop Protocol</comment>
        <glob pattern="*.rdp"/>
      </mime-type>
    </mime-info>
  '';

  # Make rdp-open the default handler for RDP files
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/x-rdp" = [ "rdp-open.desktop" ];
    "application/rdp"   = [ "rdp-open.desktop" ];
  };

  # Rebuild the MIME + desktop caches on activation
  home.activation.refreshXdgDBs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.shared-mime-info}/bin/update-mime-database "$HOME/.local/share/mime" || true
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$HOME/.local/share/applications" || true
  '';

  # Hard-create the desktop file
  home.file.".local/share/applications/rdp-open.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=RDP (FreeRDP)
    Exec=${pkgs.freerdp}/bin/xfreerdp %u /cert:ignore /dynamic-resolution +clipboard /sound:sys:pulse
    Icon=computer
    Categories=Network;RemoteAccess;
    MimeType=application/x-rdp;application/rdp;
    Terminal=false
  '';
}
