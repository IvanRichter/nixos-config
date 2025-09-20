{ config, pkgs, lib, ... }:

{
  # Kernel + udev support for Razer
  hardware.openrazer.enable = true;

  # GUI
  environment.systemPackages = with pkgs; [
    openrazer-daemon
    polychromatic
  ];

  hardware.openrazer.users = ["ivan"];
}
