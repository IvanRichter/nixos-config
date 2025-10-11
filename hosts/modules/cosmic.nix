{ pkgs, ... }:
{
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.cosmic.xwayland.enable = true;
  services.displayManager.cosmic-greeter.enable = true;

  # COSMIC portal add-on
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];

  # COSMIC apps and extensions
  environment.systemPackages = with pkgs; [
    cosmic-player
    cosmic-reader
    cosmic-ext-calculator
    cosmic-ext-tweaks
  ];

  # Clipboard manager needs zwlr_data_control_manager_v1
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = "1";
}
