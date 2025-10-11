{ pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.cosmic.xwayland.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # COSMIC portal add-on
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];
}
