{
  config,
  pkgs,
  lib,
  ...
}:
{
  networking = {
    networkmanager.enable = true;
    dhcpcd.enable = false;
  };

  systemd.network.enable = true;

  systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
  systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
}
