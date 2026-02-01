{ pkgs, ... }:

{
  home.packages = [
    pkgs.ckb-next
  ];

  systemd.user.services.ckb-next = {
    Unit = {
      Description = "Corsair Keyboards and Mice (ckb-next UI)";
      After = [ "graphical-session.target" ];
      Wants = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.ckb-next}/bin/ckb-next --background";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
