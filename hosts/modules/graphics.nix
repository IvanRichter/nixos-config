{ config, pkgs, ... }:

{
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    open = false;
    powerManagement.enable = true;
  };

  hardware.graphics.enable = true;
}