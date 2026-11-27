{ den, ... }:

{
  den.aspects.ironbar = {
    # Battery
    nixos.services.upower.enable = true;

    homeManager =
      {
        config,
        host,
        lib,
        osConfig,
        pkgs,
        ...
      }:
      let
        isLaptop = host.hasAspect den.aspects.laptop;
        hasNvidia = host.hasAspect den.aspects.nvidia;
        nvidiaSmi = lib.getExe' osConfig.hardware.nvidia.package.bin "nvidia-smi";
        target = config.wayland.systemd.target;
        colors = config.lib.stylix.colors.withHashtag;
        inherit (config.stylix) fonts;

        awk = lib.getExe pkgs.gawk;
        bluetoothctl = lib.getExe' pkgs.bluez "bluetoothctl";
        coreutils = "${pkgs.coreutils}/bin";
        grep = lib.getExe pkgs.gnugrep;
        ironbar = lib.getExe pkgs.ironbar;
        nmcli = lib.getExe' pkgs.networkmanager "nmcli";
        nmConnectionEditor = lib.getExe' pkgs.networkmanagerapplet "nm-connection-editor";
        pwvucontrol = lib.getExe pkgs.pwvucontrol;
        swayncClient = "${config.services.swaync.package}/bin/swaync-client";
        swayosdClient = "${config.services.swayosd.package}/bin/swayosd-client";
        wleave = lib.getExe config.programs.wleave.package;

        bluetoothStatus = pkgs.writeShellScript "ironbar-bluetooth" ''
          if ${bluetoothctl} show 2>/dev/null | ${grep} -q 'Powered: yes'; then
            echo "󰂯 On"
          else
            echo "󰂲 Off"
          fi
        '';

        # Toggles flip their ironvar at once - the poller doesn't toouch a var until its toggle settles
        pendingFile = name: "$XDG_RUNTIME_DIR/ironbar-${name}-pending";

        bluetoothToggle = pkgs.writeShellScript "ironbar-bluetooth-toggle" ''
          ${coreutils}/touch "${pendingFile "bluetooth"}"
          if ${bluetoothctl} show | ${grep} -q 'Powered: yes'; then
            ${ironbar} var set bluetooth "󰂲 Off"
            ${bluetoothctl} power off
          else
            ${ironbar} var set bluetooth "󰂯 On"
            ${bluetoothctl} power on
          fi
          ${coreutils}/rm -f "${pendingFile "bluetooth"}"
        '';

        togglePoller = pkgs.writeShellScript "ironbar-toggle-poller" ''
          settling() {
            [ -e "$1" ] &&
              [ $(( $(${coreutils}/date +%s) - $(${coreutils}/stat -c %Y "$1") )) -lt 15 ]
          }
          while true; do
            settling "${pendingFile "bluetooth"}" ||
              ${ironbar} var set bluetooth "$(${bluetoothStatus})" >/dev/null 2>&1
            settling "${pendingFile "wifi"}" ||
              ${ironbar} var set wifi "$(${wifiStatus})" >/dev/null 2>&1
            ${coreutils}/sleep 2
          done
        '';

        notificationStatus = pkgs.writeShellScript "ironbar-notifications" ''
          while true; do
            ${swayncClient} --subscribe | while IFS= read -r event; do
              printf '%s\n' "$event" | ${lib.getExe pkgs.jaq} -r '
                if .dnd then "󰂛"
                elif .count > 0 then "󰂚 \(.count)"
                else "󰂜" end'
            done
            sleep 1
          done
        '';

        networkStatus = pkgs.writeShellScript "ironbar-network" ''
          ${nmcli} -t -f TYPE,STATE,CONNECTION device | ${awk} -F: '
            $2 == "connected" && $1 == "ethernet" { print "󰈀 Wired"; found = 1; exit }
            $2 == "connected" && $1 == "wifi" { print "󰖩"; found = 1; exit }
            END { if (!found) print "󰤮 Offline" }
          '
        '';

        networkDetails = pkgs.writeShellScript "ironbar-network-details" ''
          device=$(${nmcli} -t -f DEVICE,TYPE,STATE device | ${awk} -F: '
            $3 == "connected" && ($2 == "ethernet" || $2 == "wifi") { print $1; exit }
          ')
          if [ -z "$device" ]; then
            echo "Not connected"
            exit
          fi
          connection=$(${nmcli} -g GENERAL.CONNECTION device show "$device")
          address=$(${nmcli} -g IP4.ADDRESS device show "$device" | ${coreutils}/cut -d'|' -f1)
          printf '%s\n%s · %s\n' "$connection" "$device" "''${address:-no IPv4}"
        '';

        wifiStatus = pkgs.writeShellScript "ironbar-wifi" ''
          if [ "$(${nmcli} radio wifi)" = enabled ]; then
            echo "󰖩 Wi-Fi on"
          else
            echo "󰖪 Wi-Fi off"
          fi
        '';

        wifiToggle = pkgs.writeShellScript "ironbar-wifi-toggle" ''
          ${coreutils}/touch "${pendingFile "wifi"}"
          if [ "$(${nmcli} radio wifi)" = enabled ]; then
            ${ironbar} var set wifi "󰖪 Wi-Fi off"
            ${nmcli} radio wifi off
          else
            ${ironbar} var set wifi "󰖩 Wi-Fi on"
            ${nmcli} radio wifi on
          fi
          ${coreutils}/rm -f "${pendingFile "wifi"}"
        '';

        batteryLevels = [
          {
            percent = 10;
            icon = "󰁺";
            charging = "󰢜";
          }
          {
            percent = 20;
            icon = "󰁻";
            charging = "󰂆";
          }
          {
            percent = 30;
            icon = "󰁼";
            charging = "󰂇";
          }
          {
            percent = 40;
            icon = "󰁽";
            charging = "󰂈";
          }
          {
            percent = 50;
            icon = "󰁾";
            charging = "󰢝";
          }
          {
            percent = 60;
            icon = "󰁿";
            charging = "󰂉";
          }
          {
            percent = 70;
            icon = "󰂀";
            charging = "󰢞";
          }
          {
            percent = 80;
            icon = "󰂁";
            charging = "󰂊";
          }
          {
            percent = 90;
            icon = "󰂂";
            charging = "󰂋";
          }
          {
            percent = 100;
            icon = "󰁹";
            charging = "󰂅";
          }
        ];

        batteryProfiles = lib.listToAttrs (
          lib.concatMap (level: [
            {
              name = "p${toString level.percent}";
              value = {
                when = {
                  inherit (level) percent;
                  charging = false;
                };
                format = "${level.icon} {percentage}%";
              };
            }
            {
              name = "p${toString level.percent}-charging";
              value = {
                when = {
                  inherit (level) percent;
                  charging = true;
                };
                format = "${level.charging} {percentage}%";
              };
            }
          ]) batteryLevels
        );

        pill = "alpha(${colors.base00}, ${toString config.stylix.opacity.desktop})";

        accents = {
          title = colors.base0E;
          inhibit = colors.base0A;
          memory = colors.base0C;
          cpu = colors.base0E;
          gpu = colors.base0F;
          temp = colors.base09;
          volume = colors.base0D;
          network = colors.base0C;
          bluetooth = colors.base0D;
          battery = colors.base0B;
          notifications = colors.base0E;
          clock = colors.base0A;
          power = colors.base08;
        };

        # Pills with accent on hover
        clickable = [
          "inhibit"
          "volume"
          "network"
          "bluetooth"
          "notifications"
          "clock"
          "power"
        ];

        pillColors = lib.concatStrings (
          lib.mapAttrsToList (
            class: color:
            ''
              #bar .${class} { color: ${color}; }
              .popup.popup-${class}, #popup-${class} { border-color: ${color}; }
            ''
            + lib.optionalString (lib.elem class clickable) ''
              #bar .${class} { transition: all 0.3s ease-in-out; }
              #bar .${class}:hover { background-color: alpha(${color}, 0.3); }
            ''
          ) accents
        );

        barBase = {
          position = "top";
          popup_autohide = true;
          popup_gap = 8;
          height = 37;
          start = [
            { type = "workspaces"; }
            {
              type = "focused";
              class = "title";
              show_icon = false;
              truncate = {
                mode = "end";
                max_length = 40;
              };
            }
          ];
          center = [ ];
        };

        # Only the laptop needs nm-applet's Wi-Fi menu
        statusModules =
          lib.optional isLaptop { type = "tray"; }
          ++ [
            {
              type = "inhibit";
              durations = [ "inf" ];
              on_click_right = "toggle";
              format_on = "󰅶";
              format_off = "󰛊";
            }
            {
              type = "sys_info";
              class = "cpu";
              interval.cpu = 2;
              format = [ "CPU {cpu_percent:1.0}%" ];
            }
          ]
          ++ lib.optional hasNvidia {
            type = "script";
            class = "gpu";
            mode = "poll";
            interval = 2000;
            cmd = "printf 'GPU %s%%' \"$(${nvidiaSmi} --query-gpu=utilization.gpu --format=csv,noheader,nounits)\"";
          }
          ++ [
            {
              type = "sys_info";
              class = "memory";
              interval.memory = 5;
              format = [ "RAM {memory_percent:1.0}%" ];
            }
            {
              type = "sys_info";
              class = "temp";
              interval.temps = 5;
              format = [ "TEMP {temp_c:1.0}°C" ];
            }
            {
              type = "volume";
              format = "{icon} {percentage}%";
              max_volume = 100;
              icons = {
                volume_high = "󰕾";
                volume_medium = "󰖀";
                volume_low = "󰕿";
                muted = "󰝟";
              };
              on_click_right = pwvucontrol;
              on_scroll_up = "${swayosdClient} --output-volume raise";
              on_scroll_down = "${swayosdClient} --output-volume lower";
            }
            {
              type = "custom";
              name = "network";
              class = "network";
              bar = [
                {
                  type = "button";
                  label = "{{5000:${networkStatus}}}";
                  on_click = "popup:toggle";
                }
              ];
              popup = [
                {
                  type = "box";
                  orientation = "vertical";
                  widgets = [
                    {
                      type = "label";
                      class = "network-details";
                      label = "{{5000:${networkDetails}}}";
                    }
                    {
                      type = "button";
                      label = "#wifi";
                      on_click = "!${wifiToggle}";
                    }
                    {
                      type = "button";
                      label = "Edit connections";
                      on_click = "!${nmConnectionEditor}";
                    }
                  ];
                }
              ];
            }
            {
              type = "label";
              class = "bluetooth";
              label = "#bluetooth";
              on_click_left = "${bluetoothToggle}";
            }
          ]
          ++ lib.optional isLaptop {
            type = "battery";
            show_icon = false;
            format = "󰁹 {percentage}%";
            profiles = batteryProfiles;
          }
          ++ [
            {
              type = "script";
              class = "notifications";
              mode = "watch";
              cmd = "${notificationStatus}";
              on_click_left = "${swayncClient} -t -sw";
              on_click_right = "${swayncClient} -d -sw";
            }
            {
              type = "clock";
              justify = "center";
              format_popup = "%-I:%M:%S %p";
              format = "<span foreground='${colors.base0A}'>%-I:%M %p</span>\n<span foreground='${colors.base0B}' size='x-small'>%a %d %b</span>";
            }
            {
              type = "label";
              class = "power";
              label = "󰐥";
              on_click_left = wleave;
            }
          ];

        # Other monitors get only workspaces and the window title
        ironbarConfig = barBase // {
          ironvar_defaults = {
            bluetooth = "󰂯";
            wifi = "󰖩 Wi-Fi";
          };
          end = [ ];
          monitors = {
            "Acer Technologies - XZ342CU P" = barBase // {
              end = statusModules;
            };
            "eDP-1" = barBase // {
              end = statusModules;
            };
          };
        };

        ironbarStyle = ''
          * {
            font-family: "MesloLGS Nerd Font Propo", "${fonts.monospace.name}";
            font-weight: bold;
            font-size: 13px;
          }

          .background {
            background-color: transparent;
          }

          #bar {
            padding: 0 4px;
            background-color: ${pill};
          }

          #bar button {
            margin: 0;
            padding: 0;
            min-height: 0;
            min-width: 0;
            border: none;
            outline: none;
            box-shadow: none;
            background: none;
            color: inherit;
          }

          #bar .widget {
            margin: 3px;
            padding: 0 10px;
            border: 2px solid currentColor;
            border-radius: 10px;
            background-color: ${pill};
            color: ${colors.base05};
          }

          #bar .widget.workspaces {
            margin: 0;
            padding: 0;
            border: none;
            background-color: transparent;
          }

          #bar .workspaces .item {
            margin: 3px;
            padding: 0 10px;
            border: 2px solid ${colors.base0C};
            border-radius: 10px;
            background-color: ${pill};
            color: ${colors.base0C};
            transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1);
          }

          #bar .workspaces .item:hover {
            background-color: alpha(${colors.base0C}, 0.25);
          }

          #bar .workspaces .item.focused {
            padding: 0 18px;
            background-color: ${colors.base0C};
            color: ${colors.base00};
          }

          #bar .workspaces .item.urgent {
            border-color: ${colors.base08};
            background-color: ${colors.base08};
            color: ${colors.base00};
          }

          ${pillColors}

          /* Hide GTK popovers' frame so .popup is the visible edge */
          popover,
          popover > contents,
          popover > arrow {
            padding: 0;
            border: none;
            box-shadow: none;
            background: none;
          }

          popover > contents {
            border-radius: 10px;
          }

          /* Dropdown lists inside a popup are also popovers */
          .popup popover > contents {
            padding: 4px;
            border: 2px solid ${colors.base02};
            background-color: ${colors.base00};
          }

          .popup-volume popover > contents {
            border-color: ${accents.volume};
          }

          .popup {
            padding: 16px;
            border-radius: 10px;
            border: 2px solid ${colors.base0E};
            background-color: ${colors.base00};
            color: ${colors.base05};
          }

          .popup-clock .calendar-clock {
            margin-bottom: 8px;
            font-size: 18px;
            color: ${accents.clock};
          }

          .popup-clock calendar,
          .popup-clock calendar > header,
          .popup-clock calendar > header > button {
            padding: 0;
            border: none;
            box-shadow: none;
            background: none;
          }

          .popup-clock calendar {
            color: ${colors.base05};
          }

          .popup-clock calendar > header > button,
          .popup-clock calendar > grid > label.today {
            color: ${accents.clock};
          }

          .popup-clock calendar > grid > label.day-name {
            color: ${colors.base04};
          }

          .popup-clock calendar > grid > label.day-number {
            padding: 4px;
            border-radius: 8px;
          }

          .popup-clock calendar > grid > label.day-number.other-month {
            color: ${colors.base03};
          }

          .popup-clock calendar > grid > label.day-number:selected {
            background-color: ${accents.clock};
            color: ${colors.base00};
          }

          #popup-network .network-details {
            margin-bottom: 4px;
          }

          #popup-network button {
            margin-top: 8px;
            padding: 4px 12px;
            border: 2px solid ${accents.network};
            border-radius: 10px;
            box-shadow: none;
            background: none;
            color: ${accents.network};
            transition: all 0.3s ease-in-out;
          }

          #popup-network button:hover {
            background-color: alpha(${accents.network}, 0.3);
          }

          tooltip.background {
            border-radius: 10px;
            background-color: alpha(${colors.base00}, 0.9);
          }

          tooltip * {
            padding: 4px;
            background-color: transparent;
            color: ${colors.base05};
          }
        '';
      in
      {
        xdg.configFile = {
          "ironbar/config.json".text = builtins.toJSON ironbarConfig;
          "ironbar/style.css".text = ironbarStyle;
        };

        # Match the bar
        services.swaync.style = lib.mkAfter ''
          .control-center {
            border: 2px solid ${accents.notifications};
            border-radius: 10px;
          }

          .notification.low,
          .notification.normal,
          .notification.critical {
            border-width: 2px;
            border-radius: 10px;
          }

          .notification.normal {
            border-color: ${accents.notifications};
          }

          .notification-row .notification-background .notification {
            background: ${colors.base00};
          }

          .notification-row .notification-background .notification .notification-default-action,
          .notification-row .notification-background .notification .notification-default-action:hover,
          .notification-row .notification-background .notification .notification-default-action .notification-content {
            border: none;
            box-shadow: none;
            background: transparent;
          }

          .widget-title > button {
            border: 2px solid ${accents.notifications};
            border-radius: 10px;
            box-shadow: none;
            background: none;
            color: ${accents.notifications};
          }

          .widget-title > button:hover {
            background: alpha(${accents.notifications}, 0.3);
          }

          .widget-dnd > switch {
            border: 2px solid ${accents.notifications};
            border-radius: 12px;
            box-shadow: none;
            background: none;
          }

          .widget-dnd > switch:checked {
            background: ${accents.notifications};
          }

          .widget-dnd > switch slider {
            border: none;
            box-shadow: none;
            background: ${colors.base05};
          }
        '';

        systemd.user.services.ironbar = {
          Unit = {
            Description = "Ironbar";
            PartOf = [ target ];
            After = [ target ];
            X-Restart-Triggers = [
              config.xdg.configFile."ironbar/config.json".source
              config.xdg.configFile."ironbar/style.css".source
            ];
          };
          Service = {
            ExecStart = ironbar;
            Restart = "on-failure";
          };
          Install.WantedBy = [ target ];
        };

        systemd.user.services.ironbar-toggles = {
          Unit = {
            Description = "Bluetooth and Wi-Fi state for the bar";
            PartOf = [ "ironbar.service" ];
            After = [ "ironbar.service" ];
          };
          Service = {
            ExecStart = togglePoller;
            Restart = "on-failure";
          };
          Install.WantedBy = [ "ironbar.service" ];
        };
      };
  };
}
