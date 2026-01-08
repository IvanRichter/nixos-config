{
  config,
  pkgs,
  lib,
  ...
}:

{
  # Kernel + udev support for Razer
  hardware.openrazer.enable = true;

  # Avoid loading unused Razer kernel modules
  boot.blacklistedKernelModules = [
    "razercore"
    "razerfirefly"
    "razermug"
  ];
  boot.extraModprobeConfig = ''
    install razercore /bin/true
    install razerfirefly /bin/true
    install razermug /bin/true
  '';

  # GUI
  environment.systemPackages = with pkgs; [
    openrazer-daemon
    polychromatic
  ];

  hardware.openrazer.users = [ "ivan" ];
}
