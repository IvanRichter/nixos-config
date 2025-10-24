{ config, lib, pkgs, ... }:

let
  # Wayland + Vulkan + WebGPU Chrome launcher with resource protections
  chromeProtected = pkgs.writeShellScriptBin "chrome-protected" ''
    export NIXOS_OZONE_WL=1
    export LIBVA_DRIVER_NAME=nvidia
    export LIBVA_DRIVERS_PATH=/run/opengl-driver/lib/dri
    export NVD_BACKEND=direct
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __VK_LAYER_NV_optimus=NVIDIA_only
    export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/nvidia_icd.x86_64.json

    exec systemd-run --user --scope \
      -p MemoryLow=2G \
      -p CPUWeight=90 \
      -p IOWeight=90 \
      ${pkgs.google-chrome}/bin/google-chrome-stable \
        --ozone-platform=x11 \
        --use-angle=vulkan \
        --enable-vulkan \
        --ignore-gpu-blocklist \
        --enable-gpu-rasterization \
        --enable-zero-copy \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiOnNvidiaGPUs,WebGPU,UnsafeWebGPU,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,UseSkiaRenderer \
        "$@"
  '';

  
  chromeProtectedDesktop = pkgs.makeDesktopItem {
    name = "google-chrome-protected";
    desktopName = "Google Chrome (WebGPU)";
    genericName = "Web Browser";
    exec = "chrome-protected %U";
    icon = "google-chrome";
    categories = [ "Network" "WebBrowser" ];
  };
in
{
  environment.systemPackages = [
    chromeProtected
    chromeProtectedDesktop
  ];

  # Raw alias
  environment.shellAliases.chrome-raw = "${pkgs.google-chrome}/bin/google-chrome";
}
