{ pkgs, ... }:

{
  hardware.ckb-next = {
    enable = true;
  };

  systemd.services.ckb-next = {
    after = [ "display-manager.service" ];
    wants = [ "display-manager.service" ];
  };
}
