{ config, pkgs, starshipToml, ... }:

{
  environment.etc."starship.toml".source = starshipToml;

  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    packages = with pkgs; [
      syncthing
      fish
      starship
    ];
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      starship init fish | source
    '';
    shellAliases = {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
      neofetch = "macchina";
    };
  };

  services.syncthing = {
    enable = true;
    user = "ivan";
    dataDir = "/home/ivan";
    configDir = "/home/ivan/.config/syncthing";
  };
}
