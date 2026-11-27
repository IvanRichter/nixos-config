{ den, ... }:

{
  den.aspects.kitty.homeManager =
    { config, lib, ... }:

    {
      programs.kitty = {
        enable = true;
        settings = {
          shell = "zellij attach -c";
          cursor_shape = "beam";
          cursor_trail = 3;
          cursor_trail_decay = "0.08 0.3";
          repaint_delay = 6;
          confirm_os_window_close = 0;
          hide_window_decorations = "yes";
          background_blur = 1;
        };
        # Brighter "bright black"
        extraConfig = lib.mkAfter ''
          color8 ${config.lib.stylix.colors.withHashtag.base04}
        '';
      };

      # Terminal for desktop entries like yazi
      xdg.terminal-exec = {
        enable = true;
        settings.default = [ "kitty.desktop" ];
      };
    };
}
