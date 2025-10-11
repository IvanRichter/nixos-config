{ config, lib, pkgs, ... }:

let
  isX86   = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in {
  services.xserver = {
    enable = isX86;
    videoDrivers = lib.optionals isX86 [ "nvidia" ];
    xkb = {
      layout = "us,cz";
      variant = ",qwerty";
    };
  };

  services.flatpak.enable = true;
  xdg.portal.enable = true;
  programs.xwayland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    MOZ_ENABLE_WAYLAND = "1";
  };

  environment.variables = {
    GDK_SCALE = "1";
    GDK_DPI_SCALE = "1.0";
    XCURSOR_SIZE = "24";
  };
}
