{ config, pkgs, ... }: {
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  systemd.services."NetworkManager-wait-online".enable = false;
  systemd.services.NetworkManager-dispatcher.enable = false;
}
