{ config, lib, pkgs, ... }:

let
  chromeProtected = pkgs.writeShellScriptBin "chrome-protected" ''
    exec systemd-run --user --scope \
      -p MemoryLow=2G \
      -p OOMScoreAdjust=-900 \
      -p CPUWeight=90 \
      -p IOWeight=90 \
      ${pkgs.google-chrome}/bin/google-chrome "$@"
  '';

  chromeProtectedDesktop = pkgs.makeDesktopItem {
    name = "google-chrome-protected";
    desktopName = "Google Chrome";
    genericName = "Web Browser";
    exec = "chrome-protected %U";
    icon = "google-chrome";
    categories = [ "Network" "WebBrowser" ];
  };

  chromeRawDesktop = pkgs.makeDesktopItem {
    name = "google-chrome-raw";
    desktopName = "Google Chrome (Raw)";
    exec = "${pkgs.google-chrome}/bin/google-chrome %U";
    icon = "google-chrome";
    categories = [ "Network" "WebBrowser" ];
    noDisplay = true;
  };
in
{
  systemd.oomd.enable = false;

  zramSwap = {
    enable = true;
    memoryPercent = 100;
    priority = 100;
    algorithm = "zstd";
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 140;
    "vm.vfs_cache_pressure" = 50;
  };

  environment.systemPackages = [
    chromeProtected
    chromeProtectedDesktop
    chromeRawDesktop
  ];

  environment.shellAliases.chrome-raw = "${pkgs.google-chrome}/bin/google-chrome";
}
