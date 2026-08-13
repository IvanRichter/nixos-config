{ den, ... }:

{
  den.aspects.networking.nixos =
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

      programs.openvpn3.enable = true;

      systemd.network.enable = true;

      systemd.services.systemd-networkd-wait-online.enable = lib.mkForce false;
      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    };
}
