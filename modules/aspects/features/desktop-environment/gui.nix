{ den, ... }:

{
  den.aspects.gui.nixos =
    { config, ... }:

    {
      services.xserver = {
        xkb = {
          layout = "us,cz";
          variant = ",qwerty";
        };
      };

      services.flatpak.enable = false;
      xdg.portal.enable = true;

      environment.sessionVariables.NIXOS_OZONE_WL = "1";

      environment.variables = {
        GDK_SCALE = "1";
        GDK_DPI_SCALE = "1.0";
        XCURSOR_THEME = config.stylix.cursor.name;
      };
    };
}
