{ config, ... }:

{
  # Userspace and open kernel module
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    open = true;
    powerManagement.enable = true;
  };

  # VAAPI on NVIDIA
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  # Kernel switches for DRM + nicer suspend
  boot.kernelParams = [
    "nvidia_drm.modeset=1"
    "nvidia.NVreg_EnableVRR=0"
    "mem_sleep_default=deep"
  ];

  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';
}
