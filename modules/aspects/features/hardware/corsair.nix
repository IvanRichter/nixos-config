{ den, ... }:

{
  den.aspects.corsair = {
    nixos =
      { pkgs, ... }:

      {
        hardware.ckb-next = {
          enable = true;
        };

        systemd.services.ckb-next = {
          after = [ "display-manager.service" ];
          wants = [ "display-manager.service" ];
        };
      };
    homeManager =
      { lib, pkgs, ... }:

      {
        # ckb-next.conf also stores device profiles
        home.activation.ckbNextFirmwareCheck = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          conf="''${XDG_CONFIG_HOME:-$HOME/.config}/ckb-next/ckb-next.conf"

          if [ ! -e "$conf" ]; then
            install -D -m 644 /dev/null "$conf"
            printf '[Program]\nDisableAutoFWCheck=true\n' > "$conf"
          elif ! grep -qx 'DisableAutoFWCheck=true' "$conf"; then
            tmp=$(mktemp "$conf.XXXXXX")
            ${lib.getExe pkgs.gawk} '
              /^\[/ { program = ($0 == "[Program]") }
              program && /^DisableAutoFWCheck=/ { next }
              { print }
              $0 == "[Program]" { print "DisableAutoFWCheck=true"; found = 1 }
              END { if (!found) print "\n[Program]\nDisableAutoFWCheck=true" }
            ' "$conf" > "$tmp"
            mv "$tmp" "$conf"
          fi
        '';

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
      };
  };
}
