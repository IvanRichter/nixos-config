{ config, pkgs, lib, ...  }:

{
  imports = [
    ./hardware-configuration.nix
    ./razer.nix

    ../modules/nix.nix
    ../modules/user.nix
    ../modules/fonts.nix
    ../modules/graphics.nix
    ../modules/nvidia.nix
    ../modules/cosmic.nix
    ../modules/gui.nix
    ../modules/memory.nix
    ../modules/networking.nix
    ../modules/docker.nix
    ../modules/rdp.nix
    ../modules/packages.nix
  ];

  nixpkgs.config.allowUnfree = true;

  system.stateVersion = "25.05";
  networking.hostName = "nixos";
  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------------------------
  # Web eID
  # ---------------------------
  services.pcscd.enable = true;

  environment.etc."chromium/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";

  environment.etc."opt/chrome/native-messaging-hosts/eu.webeid.json".source =
    "${pkgs.web-eid-app}/share/web-eid/eu.webeid.json";

  environment.etc."pkcs11/modules/opensc-pkcs11".text = ''
    module: ${pkgs.opensc}/lib/opensc-pkcs11.so
  '';

  systemd.services."home-manager-ivan" = {
    after  = [ "network-online.target" ];
    wants  = [ "network-online.target" ];
    # HM module sets 5m, force value
    serviceConfig.TimeoutStartSec = lib.mkForce "10min";
  };
}
