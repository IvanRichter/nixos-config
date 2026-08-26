{ den, ... }:

{
  den.aspects.iloader.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.iloader ];
    services.usbmuxd.enable = true;
  };
}
