{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Wayland + Vulkan + WebGPU Vivaldi launcher with resource protections
  vivaldiProtected = pkgs.writeShellScriptBin "vivaldi-protected" ''
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
      "${pkgs.vivaldi}/bin/vivaldi" \
        --ozone-platform=x11 \
        --use-gl=angle \
        --use-angle=vulkan \
        --enable-vulkan \
        --enable-unsafe-webgpu \
        --ignore-gpu-blocklist \
        --enable-gpu-rasterization \
        --enable-zero-copy \
        --enable-features=UseOzonePlatform,WaylandWindowDecorations,VaapiVideoDecoder,VaapiOnNvidiaGPUs,WebGPU,UnsafeWebGPU,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,UseSkiaRenderer \
        "$@"
  '';

  vivaldiProtectedDesktop = pkgs.makeDesktopItem {
    name = "vivaldi-protected";
    desktopName = "Vivaldi (WebGPU)";
    genericName = "Web Browser";
    exec = "vivaldi-protected %U";
    icon = "vivaldi";
    categories = [
      "Network"
      "WebBrowser"
    ];
  };
in
{
  environment.systemPackages = [
    vivaldiProtected
    vivaldiProtectedDesktop
  ];

  # Raw alias
  environment.shellAliases.vivaldi-raw = "${pkgs.vivaldi}/bin/vivaldi";
}
