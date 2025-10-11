{ pkgs, ... }:

let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in {
  hardware.graphics = {
    enable = true;
    enable32Bit = isX86;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      libva
    ];
  };
}
