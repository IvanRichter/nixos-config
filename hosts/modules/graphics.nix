{ config, pkgs, lib, ... }:

{
  # NVIDIA userspace + open kernel module
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;  
    modesetting.enable = true;    
    open = true;                 
    powerManagement.enable = true;  
  };

  # Mesa/VAAPI
  hardware.graphics = {
    enable = true;
    enable32Bit = true;  
    extraPackages = with pkgs; [
      nvidia-vaapi-driver  
      libva    
    ];
  };

  boot.kernelParams = [
    "nvidia_drm.modeset=1" 
    "mem_sleep_default=deep"    
  ];

  # Keep VRAM around across suspend
  boot.extraModprobeConfig = ''
    options nvidia NVreg_PreserveVideoMemoryAllocations=1
  '';
}
