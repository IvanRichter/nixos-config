{
  config,
  pkgs,
  lib,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    mission-center
    modprobed-db
  ];

  services.rqbit = {
    enable = true;
    user = "ivan";
    group = "users";
    downloadDir = "/home/ivan/Downloads";
  };
}
