{ den, ... }:

{
  den.aspects.graphics-apps = {
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          gimp
          fontforge-gtk
          graphite
          glaxnimate
          drawio
          upscaler
          loupe
        ];
      };

    homeManager =
      { lib, ... }:
      {
        xdg.mimeApps.defaultApplications = lib.genAttrs [
          "image/avif"
          "image/bmp"
          "image/gif"
          "image/heif"
          "image/jpeg"
          "image/jxl"
          "image/png"
          "image/tiff"
          "image/webp"
        ] (_: [ "org.gnome.Loupe.desktop" ]);
      };
  };
}
