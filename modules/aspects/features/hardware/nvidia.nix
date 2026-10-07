{ den, ... }:

{
  den.aspects.nvidia.nixos =
    { ... }:

    {
      nix.settings = {
        substituters = [ "https://cache.nixos-cuda.org" ];
        trusted-public-keys = [
          "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
        ];
      };

      # Userspace and open kernel module
      hardware.nvidia = {
        branch = "bleeding_edge";
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
        "mem_sleep_default=deep"
      ];
    };
}
