{ config, pkgs, ... }:

{
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    open = false;
    powerManagement.enable = false;
  };

  hardware.graphics.enable = true;

  # Video decode path for Chrome on NVIDIA
  hardware.graphics.extraPackages = with pkgs; [
    nvidia-vaapi-driver
  ];
}