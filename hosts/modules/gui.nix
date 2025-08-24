{ config, pkgs, ... }:

{
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us,cz";
      variant = ",qwerty";
      options = "grp:alt_shift_toggle";
    };
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  services.flatpak.enable = true;
  programs.xwayland.enable = true;

  # Fix blurry Chrome on Wayland by disabling scaling
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";

    # Tell Chrome to use Wayland window decorations
    CHROME_VERSION_EXTRA_FLAGS = "--force-device-scale-factor=1 --enable-features=WaylandWindowDecorations \
                                  --ignore-gpu-blocklist --enable-gpu-rasterization --enable-zero-copy --use-gl=desktop \
                                  --enable-features=VaapiVideoDecoder,CanvasOopRasterization";

    # VAAPI on NVIDIA needs this
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  environment.variables = {
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1.0";
    XCURSOR_SIZE = "24";
  };
}