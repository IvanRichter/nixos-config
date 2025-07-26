{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "25.05";
  nixpkgs.config.allowUnfree = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Europe/Prague";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };

  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  environment.systemPackages = with pkgs; [
    wget git curl nano htop google-chrome vscode slack
  ];

  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-emoji
    liberation_ttf dejavu_fonts corefonts
    nerd-fonts.meslo-lg
  ];
  
  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
    xkb = {
      layout = "us,cz";
      variant = ",qwerty";
      options = "grp:alt_shift_toggle";
    };
  };

  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = true;

  services.flatpak.enable = true;

  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    open = false;
    powerManagement.enable = true;
  };

  hardware.graphics.enable = true;

  programs.xwayland.enable = true;
  programs.zsh.enable = true;

  virtualisation.docker.enable = true;
}