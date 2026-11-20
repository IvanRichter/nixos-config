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

      systemd.services.NetworkManager-wait-online.enable = lib.mkForce false;
    };
}
