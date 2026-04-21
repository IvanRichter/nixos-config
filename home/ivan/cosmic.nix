{ lib, osConfig, ... }:
let
  isLaptop = osConfig.networking.hostName == "mbp-nixos";
  rightWingApplets =
    [
      "io.github.cosmic_utils.sysinfo-applet"
    ]
    ++ lib.optionals isLaptop [
      "com.system76.CosmicAppletBattery"
    ]
    ++ [
      "com.system76.CosmicAppletTime"
      "io.github.cosmic_utils.weather-applet"
      "com.system76.CosmicAppletInputSources"
      "com.system76.CosmicAppletTiling"
      "com.system76.CosmicAppletAudio"
      "com.system76.CosmicAppletNetwork"
      "com.system76.CosmicAppletBluetooth"
      "com.system76.CosmicAppletStatusArea"
      "com.system76.CosmicAppletPower"
    ];
in
{
  xdg.configFile = {
    "cosmic/com.system76.CosmicPanel/v1/entries".text = ''
      [
          "Panel",
      ]
    '';

    "cosmic/com.system76.CosmicPanel.Panel/v1/plugins_center".text = ''
      Some([])
    '';

    "cosmic/com.system76.CosmicPanel.Panel/v1/plugins_wings".text = ''
      Some(([
          "com.system76.CosmicAppletWorkspaces",
          "net.tropicbliss.CosmicExtAppletCaffeine",
      ], [
${lib.concatMapStringsSep "\n" (applet: "          \"${applet}\",") rightWingApplets}
      ]))
    '';

    "cosmic/com.system76.CosmicPanel.Dock/v1/plugins_center".text = ''
      Some([])
    '';

    "cosmic/com.system76.CosmicPanel.Dock/v1/plugins_wings".text = "None";

    "cosmic/io.github.cosmic-utils.cosmic-ext-applet-sysinfo/v1/include_swap_in_ram".text = "true";

    "cosmic/io.github.cosmic_utils.weather-applet/v1/use_ip_location".text = "true";

    "cosmic/com.system76.CosmicTk/v1/interface_font".text = ''
      (
          family: "Roboto",
          weight: Normal,
          stretch: Normal,
          style: Normal,
      )
    '';

    "cosmic/com.system76.CosmicTk/v1/monospace_font".text = ''
      (
          family: "MesloLGS Nerd Font Mono",
          weight: Normal,
          stretch: Normal,
          style: Normal,
      )
    '';

    "cosmic/com.system76.CosmicComp/v1/input_default".text = ''
      (
          state: Enabled,
          acceleration: Some((
              profile: Some(Flat),
              speed: 0.0,
          )),
          scroll_config: Some((
              natural_scroll: Some(false),
          )),
      )
    '';

    "cosmic/com.system76.CosmicComp/v1/workspaces".text = ''
      (
          workspace_mode: Global,
          workspace_layout: Vertical,
          action_on_typing: None,
      )
    '';

    "cosmic/com.system76.CosmicComp/v1/input_touchpad".text = ''
      (
          state: Enabled,
          acceleration: Some((
              profile: Some(Flat),
              speed: -0.1028,
          )),
          click_method: Some(Clickfinger),
          scroll_config: Some((
              method: Some(TwoFinger),
              natural_scroll: Some(false),
              scroll_button: None,
              scroll_factor: Some(0.5),
          )),
          tap_config: Some((
              enabled: false,
              button_map: Some(LeftRightMiddle),
              drag: true,
              drag_lock: false,
          )),
      )
    '';

    "cosmic/com.system76.CosmicTheme.Mode/v1/auto_switch".text = "false";
    "cosmic/com.system76.CosmicTheme.Mode/v1/is_dark".text = "true";
    # #4af4fd
    "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/accent".text = ''
      Some((
          red: 0.2901961,
          green: 0.9568627,
          blue: 0.9921569,
      ))
    '';
    # #000000
    "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/bg_color".text = ''
      Some((
          red: 0.0,
          green: 0.0,
          blue: 0.0,
          alpha: 1.0,
      ))
    '';
    # #121212
    "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/primary_container_bg".text = ''
      Some((
          red: 0.0705882,
          green: 0.0705882,
          blue: 0.0705882,
          alpha: 1.0,
      ))
    '';
    # #121212
    "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/secondary_container_bg".text = ''
      Some((
          red: 0.0705882,
          green: 0.0705882,
          blue: 0.0705882,
          alpha: 1.0,
      ))
    '';
    # #1e1e1e
    "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/neutral_tint".text = ''
      Some((
          red: 0.1176471,
          green: 0.1176471,
          blue: 0.1176471,
      ))
    '';
    # #d6d6d6
    "cosmic/com.system76.CosmicTheme.Dark.Builder/v1/text_tint".text = ''
      Some((
          red: 0.8392157,
          green: 0.8392157,
          blue: 0.8392157,
      ))
    '';
  };
}
