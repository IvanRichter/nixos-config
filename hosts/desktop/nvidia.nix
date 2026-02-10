{ config, ... }:

{
  # Userspace and open kernel module
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    modesetting.enable = true;
    open = true;
    powerManagement.enable = true;
    videoAcceleration = true;
  };

  # VAAPI on NVIDIA
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    NVD_BACKEND = "direct";
  };

  # Kernel switches for DRM and suspend
  boot.kernelParams = [
    "nvidia.NVreg_EnableVRR=0"
    "mem_sleep_default=deep"
  ];
}
