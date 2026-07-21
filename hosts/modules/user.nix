{
  config,
  lib,
  pkgs,
  ...
}:

{
  users.users.ivan = {
    isNormalUser = true;
    shell = lib.getExe pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "render"
      "plugdev"
    ];
    packages = with pkgs; [
      syncthing
    ];
  };

  programs.fish = {
    enable = true;
    useBabelfish = true;
  };

  services.syncthing = {
    enable = true;
    user = "ivan";
    dataDir = "/home/ivan";
    configDir = "/home/ivan/.config/syncthing";
    openDefaultPorts = true;
    overrideDevices = false;
    overrideFolders = false;
  };

  security.sudo-rs = {
    enable = true;
  };
}
