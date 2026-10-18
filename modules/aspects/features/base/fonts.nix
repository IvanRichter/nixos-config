{ den, ... }:

{
  den.aspects.fonts.nixos =
    { config, pkgs, ... }:
    {
      fonts = {
        # Fallback and compatibility fonts
        packages = with pkgs; [
          noto-fonts
          noto-fonts-cjk-sans
          dejavu_fonts
          liberation_ttf
          corefonts
        ];

        fontconfig = {
          antialias = true;
          hinting.enable = true;
          hinting.style = "slight";
          subpixel.rgba = "rgb";
          subpixel.lcdfilter = "light";
          allowBitmaps = false;

          defaultFonts = {
            sansSerif = [
              "Noto Sans"
              "DejaVu Sans"
            ];
            serif = [ "DejaVu Serif" ];
            monospace = [ "DejaVu Sans Mono" ];
          };

          # Route common stacks to the primary sans-serif font
          localConf = ''
            <fontconfig>
              <!-- Route common stacks to the primary sans-serif font -->
              <match target="pattern">
                <test name="family"><string>system-ui</string></test>
                <edit name="family" mode="assign"><string>${config.stylix.fonts.sansSerif.name}</string></edit>
              </match>
              <match target="pattern">
                <test name="family"><string>Segoe UI</string></test>
                <edit name="family" mode="assign"><string>${config.stylix.fonts.sansSerif.name}</string></edit>
              </match>
              <match target="pattern">
                <test name="family"><string>Helvetica</string></test>
                <edit name="family" mode="assign"><string>${config.stylix.fonts.sansSerif.name}</string></edit>
              </match>
              <match target="pattern">
                <test name="family"><string>Arial</string></test>
                <edit name="family" mode="assign"><string>${config.stylix.fonts.sansSerif.name}</string></edit>
              </match>
            </fontconfig>
          '';
        };
      };

      # Slightly crisper TrueType metrics
      environment.sessionVariables.FREETYPE_PROPERTIES = "truetype:interpreter-version=40 cff:no-stem-darkening=1 autofitter:warping=1";
    };
}
