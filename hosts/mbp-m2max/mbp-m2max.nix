{ config, pkgs, lib, ... }:
{
  imports = [
	./hardware-configuration.nix
	../modules/gui.nix
	../modules/packages.nix
  ../modules/docker.nix
  ../modules/fonts.nix
  ../modules/nix.nix
  ../modules/rdp.nix
  ../modules/user.nix
 ];

  nixpkgs.hostPlatform = "aarch64-linux";
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  system.stateVersion = "25.11";
  networking.hostName = "mbp-nixos";
  i18n.defaultLocale = "en_US.UTF-8"; 
  time.timeZone = "Europe/Prague";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  # Laptop sanity
  zramSwap.enable = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
}
