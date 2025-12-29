{ pkgs, ... }:

{
  hardware.ckb-next = {
    enable = true;
    # Temporary workaround pending PR #446679
    package = pkgs.ckb-next.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or [ ]) ++ [ "-DUSE_DBUS_MENU=0" ];
    });
  };
}
