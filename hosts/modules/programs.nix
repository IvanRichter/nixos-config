{ pkgs, ... }:
{
  programs = {
    bat.enable = true;

    git = {
      enable = true;
      lfs.enable = true;
    };

    npm = {
      enable = true;
      package = pkgs.nodejs_latest;
    };

    obs-studio.enable = true;

    skim = {
      enable = true;
      keybindings = true;
    };

    tcpdump.enable = true;
    yazi.enable = true;
  };

  users.users.ivan.extraGroups = [ "pcap" ];
}
