{ pkgs, lib, ... }:

let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
{
  hardware.graphics = {
    enable = true;
    enable32Bit = isX86;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };

  environment.systemPackages = with pkgs; [
    vulkan-tools
    libva-utils
    vdpauinfo
  ];
}
