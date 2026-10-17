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

  den.schema.host = { lib, ... }: {
    options.isLaptop = lib.mkEnableOption "laptop-specific configuration";

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
    isLaptop = true;
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
    (
      { user, ... }:
      {
        name = "home-manager-service/${user.userName}";

        nixos =
          {
            config,
            lib,
            utils,
            ...
          }:
          lib.mkIf (lib.elem "homeManager" user.classes && !config.home-manager.startAsUserService) {
            systemd.services."home-manager-${utils.escapeSystemdPath user.userName}" = {
              after = [ "network-online.target" ];
              wants = [ "network-online.target" ];
              serviceConfig.TimeoutStartSec = lib.mkForce "10min";
            };
          };
      }
    )
  ];
}
