{
  config,
  lib,
  pkgs,
  ...
}:

{
  systemd.oomd.enable = false;

  zramSwap = {
    enable = true;
    memoryPercent = 50;
    priority = 100;
    algorithm = "lz4";
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.vfs_cache_pressure" = 50;
  };
}
