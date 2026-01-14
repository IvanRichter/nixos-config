{ config, pkgs, ... }:

{
  users.users.ivan = {
    isNormalUser = true;
    shell = pkgs.fish;
    ignoreShellProgramCheck = true;
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
      fish
    ];
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      starship init fish | source
      zoxide init fish --cmd cd | source

    '';
    shellAliases = {
      pbcopy = "wl-copy";
      pbpaste = "wl-paste";
      neofetch = "macchina";
      ls = "eza --group-directories-first";
      cat = "bat -pp";
      grep = "rg --no-heading --color=auto";
      find = "fd";
      top = "btm";
      dig = "doggo";
      jq = "jaq";
      du = "dust";
      cd = "z";
    };
  };

  services.syncthing = {
    enable = true;
    user = "ivan";
    dataDir = "/home/ivan";
    configDir = "/home/ivan/.config/syncthing";
  };

  security.sudo-rs = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
    '';
  };
}
