{ pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.cosmic.xwayland.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # COSMIC portal add-on
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];

  # COSMIC apps and extensions
  environment.systemPackages = with pkgs; [
    cosmic-reader
    cosmic-ext-tweaks
    cosmic-ext-applet-weather
    cosmic-ext-applet-caffeine
    cosmic-ext-applet-sysinfo
  ];

  # Remove unneeded packages
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-store
    cosmic-term
    adwaita-icon-theme
    pop-icon-theme
    pulseaudio
    playerctl
  ];

  # Clipboard manager needs zwlr_data_control_manager_v1
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = "1";
}
