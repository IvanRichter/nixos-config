{ ... }:
{
  xdg.configFile = {
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
