{ config, lib, pkgs, ... }:

let
  # Wayland-optimized Chrome with GPU + VAAPI forced on
  chromeProtected = pkgs.writeShellScriptBin "chrome-protected" ''
    # Wayland session hint
    export NIXOS_OZONE_WL=1

    # Force NVIDIA VAAPI path
    export LIBVA_DRIVER_NAME=nvidia
    export NVD_BACKEND=direct

    exec systemd-run --user --scope \
      -p MemoryLow=2G \
      -p OOMScoreAdjust=-900 \
      -p CPUWeight=90 \
      -p IOWeight=90 \
      ${pkgs.google-chrome}/bin/google-chrome \
        --ignore-gpu-blocklist \
        --enable-gpu-rasterization \
        --enable-zero-copy \
        --use-gl=desktop \
        --enable-features=VaapiVideoDecoder,CanvasOopRasterization,WaylandWindowDecorations \
        "$@"
  '';

  chromeProtectedDesktop = pkgs.makeDesktopItem {
    name = "google-chrome-protected";
    desktopName = "Google Chrome";
    genericName = "Web Browser";
    exec = "chrome-protected %U";
    icon = "google-chrome";
    categories = [ "Network" "WebBrowser" ];
  };
in
{
  systemd.oomd.enable = false;

  zramSwap = {
    enable = true;
    memoryPercent = 100;
    priority = 100;
    algorithm = "zstd";
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 140;
    "vm.vfs_cache_pressure" = 50;
  };

  environment.systemPackages = [
    chromeProtected
    chromeProtectedDesktop
  ];

  # Raw alias if you really want to bypass the wrapper
  environment.shellAliases.chrome-raw = "${pkgs.google-chrome}/bin/google-chrome";
}
