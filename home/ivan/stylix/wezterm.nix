{ ... }:

{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require('wezterm')
      local act = wezterm.action

      return {
        default_cursor_style = 'SteadyBar',
        enable_tab_bar = true,
        window_decorations = 'TITLE|RESIZE',
        enable_wayland = true,
        text_background_opacity = 1.0,

        initial_cols = 128,
        initial_rows = 32,

        keys = {
          { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
          { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },
        },

        mouse_bindings = {
          -- avoid passing the Down event to apps that capture the mouse
          { event = { Down = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.Nop },
          -- finalize selection and copy to clipboard
          { event = { Up   = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.CompleteSelection 'Clipboard' },
        },
      }
    '';
  };
}
