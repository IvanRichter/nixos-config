{
  den,
  inputs,
  lib,
  ...
}:

{
  imports = [ inputs.den.flakeModule ];

  den.default = {
    includes = [ den.batteries.hostname ];

    nixos.system.stateVersion = "26.11";
    homeManager.home.stateVersion = "26.11";
  };

  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.schema.host = {
    includes = [ den.batteries.mutual-provider ];

    options.sharedHomePkgs = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether Home Manager uses the host's package set";
    };
  };

  den.hosts.x86_64-linux.desktop = {
    hostName = "nixos";
    users.ivan = { };
  };

  den.hosts.aarch64-linux.mbp-m2max = {
    hostName = "mbp-nixos";
    users.ivan = { };
  };

  den.schema.hm-host.includes = [
    {
      nixos = { host, ... }: {
        home-manager = {
          useGlobalPkgs = host.sharedHomePkgs;
          useUserPackages = true;
          backupFileExtension = "bak";
          overwriteBackup = true;
        };
      };
    }
    {
      name = "home-manager-service";

      nixos =
        {
          user,
          config,
          lib,
          utils,
          ...
        }:
        lib.mkIf (lib.elem "homeManager" user.classes && !config.home-manager.startAsUserService) {
          systemd.services."home-manager-${utils.escapeSystemdPath user.userName}" = {
            serviceConfig.TimeoutStartSec = lib.mkForce "10min";
          };
        };
    }
  ];
}
