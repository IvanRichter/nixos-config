{ den, ... }:

{
  den.aspects.regreet.nixos =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      niri = lib.getExe config.programs.niri.package;
      regreet = lib.getExe config.services.displayManager.regreet.package;
      colors = config.lib.stylix.colors.withHashtag;
      inherit (config.stylix) cursor;

      greeterKdl = pkgs.writeText "niri-greeter.kdl" ''
        // Keyboard layout comes from localed
        input {
            keyboard {
                numlock
            }
        }

        output "eDP-1" {
            scale 1.75
        }

        layout {
            background-color "${colors.base00}"
        }

        cursor {
            xcursor-theme "${cursor.name}"
            xcursor-size ${toString cursor.size}
        }

        hotkey-overlay {
            skip-at-startup
        }

        gestures {
            hot-corners {
                off
            }
        }

        // Use the center monitor on desktop
        window-rule {
            open-on-output "Acer Technologies XZ342CU P 11190678F3W01"
            open-focused true
        }

        spawn-sh-at-startup "${regreet}; ${niri} msg action quit --skip-confirmation"
      '';

      greeterConfig = pkgs.runCommandLocal "niri-greeter.kdl" { } ''
        ${niri} validate -c ${greeterKdl}
        cp ${greeterKdl} $out
      '';
    in
    {
      # Runs inside niri instead of the module's default cage
      services.displayManager.regreet.enable = true;
      services.greetd.settings.default_session.command =
        "${lib.getExe' pkgs.dbus "dbus-run-session"} ${niri} -c ${greeterConfig}";
    };
}
