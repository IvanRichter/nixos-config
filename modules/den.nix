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
      nixos.home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
        overwriteBackup = true;
      };
    }
  ];
}
