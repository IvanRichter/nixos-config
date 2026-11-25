{ den, ... }:

{
  den.aspects.programs.includes = [ den.aspects.tcpdump ];

  den.aspects.programs.nixos =
    { pkgs, ... }:
    {
      programs = {
        git = {
          enable = true;
          lfs.enable = true;
        };

        npm = {
          enable = true;
          package = pkgs.nodejs_latest;
          npmrc = ''
            prefix = ''${HOME}/.npm
            update-notifier = false
          '';
        };

        obs-studio.enable = true;
      };
    };

  den.aspects.tcpdump = {
    nixos.programs.tcpdump.enable = true;
    provides.to-users.user.extraGroups = [ "pcap" ];
  };
}
