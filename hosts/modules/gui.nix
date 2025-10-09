{ config, lib, pkgs, ... }:

let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
  isAarch = pkgs.stdenv.hostPlatform.system == "aarch64-linux";
in 
{
  services.xserver = {
    enable = isX86;
    videoDrivers = lib.optionals isX86 [ "nvidia" ];
    xkb = {
      layout = "us,cz";
      variant = ",qwerty";
    };
  };

  # COSMIC
  services.desktopManager.cosmic.enable = true;
  services.desktopManager.cosmic.xwayland.enable = true;
  services.displayManager.cosmic-greeter.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-cosmic ];


  services.flatpak.enable = true;
  programs.xwayland.enable = true;

  # Graphics toggle
  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = with pkgs; [
    vulkan-loader        
    vulkan-validation-layers
  ];

  # Fix Wayland things
  environment.sessionVariables =
 {
    NIXOS_OZONE_WL = "1";

    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
}
  // lib.optionalAttrs isX86 {
    # VAAPI on NVIDIA needs this
    LIBVA_DRIVER_NAME = "nvidia";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";

    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    NVD_BACKEND = "direct";
  };

  environment.variables = {
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1.0";
    XCURSOR_SIZE = "24";
  };
}
