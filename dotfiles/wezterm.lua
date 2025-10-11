local wezterm = require('wezterm')
local act = wezterm.action
local config = {}

config.color_scheme = 'Tokyo Night'
config.font = wezterm.font_with_fallback({ 'JetBrains Mono', 'Noto Sans Mono' })
config.font_size = 12.5
config.default_cursor_style = 'SteadyBar'

config.enable_tab_bar = true
config.window_decorations = 'TITLE|RESIZE'

config.enable_wayland = true
config.window_background_opacity = 0.8
config.text_background_opacity = 1.0

config.initial_cols = 128
config.initial_rows = 32

config.keys = {
  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo('Clipboard') },
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom('Clipboard') },
}

config.mouse_bindings = {
  -- avoid passing the Down event to apps that capture the mouse
  { event = { Down = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.Nop },
  -- finalize selection and copy to clipboard
  { event = { Up   = { streak = 1, button = 'Left' } }, mods = 'NONE', action = act.CompleteSelection 'Clipboard' },
}

return config
