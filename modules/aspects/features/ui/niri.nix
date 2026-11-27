{ den, ... }:

{
  den.aspects.niri = {
    includes = [ den.aspects.ironbar ];

    nixos =
      { pkgs, ... }:
      {
        programs.niri = {
          enable = true;
          useNautilus = false;
        };

        environment.systemPackages = [ pkgs.xwayland-satellite ];

        # Polkit password prompts
        security.soteria.enable = true;

        programs.nm-applet.enable = true;
        security.pam.services.swaylock = { };

        # Lets swayosd set the backlight
        services.udev.packages = [ pkgs.swayosd ];

        services.keyd = {
          enable = true;

          # Super alone sends Super+D
          keyboards.default.settings.main.leftmeta = "overload(meta, M-d)";
        };
      };

    homeManager =
      {
        config,
        lib,
        osConfig,
        pkgs,
        ...
      }:
      let
        colors = config.lib.stylix.colors.withHashtag;
        inherit (config.stylix) cursor;
        inherit (osConfig.services.xserver) xkb;

        kitty = lib.getExe config.programs.kitty.package;
        swaylock = lib.getExe config.programs.swaylock.package;
        swayncClient = "${config.services.swaync.package}/bin/swaync-client";
        swayosdClient = "${config.services.swayosd.package}/bin/swayosd-client";
        vicinae = lib.getExe config.programs.vicinae.package;
        wleave = lib.getExe config.programs.wleave.package;

        workspaceBinds = lib.concatMapStrings (n: ''
          Mod+${n} { focus-workspace ${n}; }
          Mod+Ctrl+${n} { move-column-to-workspace ${n}; }
        '') (map toString (lib.range 1 9));

        niriConfig = pkgs.writeText "niri-config.kdl" ''
          input {
              keyboard {
                  xkb {
                      layout "${xkb.layout}"
                      variant "${xkb.variant}"
                  }
                  numlock
              }

              touchpad {
                  click-method "clickfinger"
                  accel-profile "flat"
                  accel-speed -0.1028
                  scroll-method "two-finger"
                  scroll-factor 0.5
              }

              mouse {
                  accel-profile "flat"
              }
          }

          output "PNP(BNQ) BenQ XL2730Z J8B03622SL0" {
              mode "2560x1440"
              position x=0 y=0
          }

          output "Acer Technologies XZ342CU P 11190678F3W01" {
              mode "3440x1440"
              position x=2560 y=0
          }

          output "PNP(BNQ) BenQ XL2720T 72D00092SL0" {
              mode "1920x1080"
              position x=6000 y=0
          }

          output "eDP-1" {
              scale 1.75
          }

          layout {
              gaps 10
              default-column-width { proportion 0.5; }

              // Workspaces show the wallpaper in the backdrop behind them
              background-color "transparent"

              focus-ring {
                  width 2
                  active-color "${colors.base0D}"
                  inactive-color "${colors.base02}"
              }
          }

          layer-rule {
              match namespace="^wpaperd"
              place-within-backdrop true
          }

          blur {
              passes 2
              offset 2.5
          }

          // Blur the wallpaper behind the bar and launcher
          layer-rule {
              match namespace="^ironbar$"
              match namespace="^vicinae$"
              background-effect {
                  blur true
              }
          }

          prefer-no-csd

          screenshot-path "${config.xdg.userDirs.pictures}/screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

          cursor {
              xcursor-theme "${cursor.name}"
              xcursor-size ${toString cursor.size}
          }

          window-rule {
              geometry-corner-radius 12
              clip-to-geometry true

              // Focus ring only around windows
              draw-border-with-background false
          }

          window-rule {
              match app-id=r#"firefox$"# title="^Picture-in-Picture$"
              open-floating true
          }

          // Opened from the bar's network and volume pills
          window-rule {
              match app-id="^nm-connection-editor$"
              match app-id=r#"^com\.saivert\.pwvucontrol$"#
              open-floating true
              default-column-width { fixed 720; }
              default-window-height { fixed 560; }
          }

          binds {
              Mod+Shift+Slash { show-hotkey-overlay; }

              Mod+T hotkey-overlay-title="Open a Terminal: kitty" { spawn "${kitty}"; }
              Mod+D hotkey-overlay-title="Run an Application: Vicinae" { spawn "${vicinae}" "toggle"; }
              Super+Alt+L hotkey-overlay-title="Lock the Screen: swaylock" { spawn "${swaylock}"; }
              Mod+Shift+N hotkey-overlay-title="Notifications: swaync" { spawn "${swayncClient}" "-t" "-sw"; }
              Mod+Shift+E hotkey-overlay-title="Power Menu: wleave" { spawn "${wleave}"; }

              XF86AudioRaiseVolume allow-when-locked=true { spawn "${swayosdClient}" "--output-volume" "raise"; }
              XF86AudioLowerVolume allow-when-locked=true { spawn "${swayosdClient}" "--output-volume" "lower"; }
              XF86AudioMute allow-when-locked=true { spawn "${swayosdClient}" "--output-volume" "mute-toggle"; }
              XF86AudioMicMute allow-when-locked=true { spawn "${swayosdClient}" "--input-volume" "mute-toggle"; }
              XF86AudioPlay allow-when-locked=true { spawn "${swayosdClient}" "--playerctl" "play-pause"; }
              XF86AudioStop allow-when-locked=true { spawn "${swayosdClient}" "--playerctl" "stop"; }
              XF86AudioPrev allow-when-locked=true { spawn "${swayosdClient}" "--playerctl" "prev"; }
              XF86AudioNext allow-when-locked=true { spawn "${swayosdClient}" "--playerctl" "next"; }
              XF86MonBrightnessUp allow-when-locked=true { spawn "${swayosdClient}" "--brightness" "raise"; }
              XF86MonBrightnessDown allow-when-locked=true { spawn "${swayosdClient}" "--brightness" "lower"; }

              Mod+O repeat=false { toggle-overview; }
              Mod+Q repeat=false { close-window; }

              Mod+Left { focus-column-or-monitor-left; }
              Mod+Down { focus-window-or-workspace-down; }
              Mod+Up { focus-window-or-workspace-up; }
              Mod+Right { focus-column-or-monitor-right; }
              Mod+H { focus-column-or-monitor-left; }
              Mod+J { focus-window-or-workspace-down; }
              Mod+K { focus-window-or-workspace-up; }
              Mod+L { focus-column-or-monitor-right; }

              Mod+Shift+Left { move-column-left-or-to-monitor-left; }
              Mod+Shift+Down { move-window-down-or-to-workspace-down; }
              Mod+Shift+Up { move-window-up-or-to-workspace-up; }
              Mod+Shift+Right { move-column-right-or-to-monitor-right; }
              Mod+Shift+H { move-column-left-or-to-monitor-left; }
              Mod+Shift+J { move-window-down-or-to-workspace-down; }
              Mod+Shift+K { move-window-up-or-to-workspace-up; }
              Mod+Shift+L { move-column-right-or-to-monitor-right; }

              Mod+Home { focus-column-first; }
              Mod+End { focus-column-last; }
              Mod+Ctrl+Home { move-column-to-first; }
              Mod+Ctrl+End { move-column-to-last; }

              Mod+Ctrl+Left { focus-monitor-left; }
              Mod+Ctrl+Down { focus-monitor-down; }
              Mod+Ctrl+Up { focus-monitor-up; }
              Mod+Ctrl+Right { focus-monitor-right; }
              Mod+Ctrl+H { focus-monitor-left; }
              Mod+Ctrl+J { focus-monitor-down; }
              Mod+Ctrl+K { focus-monitor-up; }
              Mod+Ctrl+L { focus-monitor-right; }

              Mod+Shift+Ctrl+Left { move-column-to-monitor-left; }
              Mod+Shift+Ctrl+Down { move-column-to-monitor-down; }
              Mod+Shift+Ctrl+Up { move-column-to-monitor-up; }
              Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }
              Mod+Shift+Ctrl+H { move-column-to-monitor-left; }
              Mod+Shift+Ctrl+J { move-column-to-monitor-down; }
              Mod+Shift+Ctrl+K { move-column-to-monitor-up; }
              Mod+Shift+Ctrl+L { move-column-to-monitor-right; }

              Mod+Page_Down { focus-workspace-down; }
              Mod+Page_Up { focus-workspace-up; }
              Mod+U { focus-workspace-down; }
              Mod+I { focus-workspace-up; }
              Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
              Mod+Ctrl+Page_Up { move-column-to-workspace-up; }
              Mod+Ctrl+U { move-column-to-workspace-down; }
              Mod+Ctrl+I { move-column-to-workspace-up; }

              Mod+Shift+Page_Down { move-workspace-down; }
              Mod+Shift+Page_Up { move-workspace-up; }
              Mod+Shift+U { move-workspace-down; }
              Mod+Shift+I { move-workspace-up; }

              Mod+WheelScrollDown cooldown-ms=150 { focus-workspace-down; }
              Mod+WheelScrollUp cooldown-ms=150 { focus-workspace-up; }
              Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
              Mod+Ctrl+WheelScrollUp cooldown-ms=150 { move-column-to-workspace-up; }

              Mod+WheelScrollRight { focus-column-right; }
              Mod+WheelScrollLeft { focus-column-left; }
              Mod+Ctrl+WheelScrollRight { move-column-right; }
              Mod+Ctrl+WheelScrollLeft { move-column-left; }

              Mod+Shift+WheelScrollDown { focus-column-right; }
              Mod+Shift+WheelScrollUp { focus-column-left; }
              Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
              Mod+Ctrl+Shift+WheelScrollUp { move-column-left; }

              ${workspaceBinds}

              Mod+BracketLeft { consume-or-expel-window-left; }
              Mod+BracketRight { consume-or-expel-window-right; }
              Mod+Comma { consume-window-into-column; }
              Mod+Period { expel-window-from-column; }

              Mod+R { switch-preset-column-width; }
              Mod+Shift+R { switch-preset-column-width-back; }
              Mod+Ctrl+Shift+R { switch-preset-window-height; }
              Mod+Ctrl+R { reset-window-height; }

              Mod+F { maximize-column; }
              Mod+Shift+F { fullscreen-window; }
              Mod+M { maximize-window-to-edges; }
              Mod+Ctrl+F { expand-column-to-available-width; }
              Mod+C { center-column; }
              Mod+Ctrl+C { center-visible-columns; }

              Mod+Minus { set-column-width "-10%"; }
              Mod+Equal { set-column-width "+10%"; }
              Mod+Shift+Minus { set-window-height "-10%"; }
              Mod+Shift+Equal { set-window-height "+10%"; }

              Mod+V { toggle-window-floating; }
              Mod+Shift+V { switch-focus-between-floating-and-tiling; }
              Mod+W { toggle-column-tabbed-display; }

              Mod+Space { switch-layout "next"; }
              Mod+Shift+Space { switch-layout "prev"; }

              Print { screenshot; }
              Mod+Shift+S { screenshot; }
              Ctrl+Print { screenshot-screen; }
              Alt+Print { screenshot-window; }

              Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
              Ctrl+Alt+Delete { quit; }
              Mod+Shift+P { power-off-monitors; }
          }
        '';
      in
      {
        xdg.configFile."niri/config.kdl".source = pkgs.runCommandLocal "niri-config.kdl" { } ''
          ${lib.getExe pkgs.niri} validate -c ${niriConfig}
          cp ${niriConfig} $out
        '';

        # Launcher
        programs.vicinae = {
          enable = true;
          systemd.enable = true;
          mutableSettings = true;
          settings.tray.enabled = false;
        };

        programs.yazi.enable = true;
        xdg.mimeApps.defaultApplications."inode/directory" = [ "yazi.desktop" ];

        # Volume mixer
        home.packages = [ pkgs.pwvucontrol ];

        # Notifications, volume/brightness popups, power menu
        services.swaync.enable = true;
        services.swayosd.enable = true;
        programs.wleave.enable = true;

        services.wpaperd = {
          enable = true;
          settings.default = {
            path = "${config.xdg.userDirs.pictures}/wallpaper.jpg";
            mode = "center";
          };
        };

        # Lock after 10 minutes idle and before sleep
        programs.swaylock.enable = true;
        services.swayidle = {
          enable = true;
          timeouts = [
            {
              timeout = 600;
              command = "${swaylock} -f";
            }
            {
              timeout = 601;
              command = "${lib.getExe pkgs.niri} msg action power-off-monitors";
            }
          ];
          events = {
            before-sleep = "${swaylock} -f";
            lock = "${swaylock} -f";
          };
        };
      };
  };
}
