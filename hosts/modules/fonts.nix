{ pkgs, ... }: {
  fonts = {
    packages = with pkgs; [
      roboto
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      dejavu_fonts
      liberation_ttf
      nerd-fonts.meslo-lg
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
        sansSerif = [ "Roboto" "Noto Sans" "DejaVu Sans" ];
        serif     = [ "Noto Serif" "DejaVu Serif" ];
        monospace = [ "JetBrains Mono" "DejaVu Sans Mono" ];
        emoji     = [ "Noto Color Emoji" ];
      };

      # Route common stacks to Roboto
      localConf = ''
        <fontconfig>
          <!-- Route common stacks to Roboto -->
          <match target="pattern">
            <test name="family"><string>system-ui</string></test>
            <edit name="family" mode="assign"><string>Roboto</string></edit>
          </match>
          <match target="pattern">
            <test name="family"><string>Segoe UI</string></test>
            <edit name="family" mode="assign"><string>Roboto</string></edit>
          </match>
          <match target="pattern">
            <test name="family"><string>Helvetica</string></test>
            <edit name="family" mode="assign"><string>Roboto</string></edit>
          </match>
          <match target="pattern">
            <test name="family"><string>Arial</string></test>
            <edit name="family" mode="assign"><string>Roboto</string></edit>
          </match>
        </fontconfig>
      '';
    };
  };

  # Slightly crisper TrueType metrics
  environment.sessionVariables.FREETYPE_PROPERTIES = 
    "truetype:interpreter-version=40 cff:no-stem-darkening=1 autofitter:warping=1";
}
