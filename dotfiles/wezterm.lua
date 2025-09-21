local wezterm = require('wezterm')
local config = {}

config.color_scheme = 'Tokyo Night'
config.font = wezterm.font_with_fallback({ 'JetBrains Mono', 'Noto Sans Mono' })
config.font_size = 12.5
config.default_cursor_style = 'SteadyBar'

config.enable_tab_bar = true
config.window_decorations = 'TITLE|RESIZE'

config.window_background_opacity = 0.8
config.text_background_opacity = 1.0 

config.initial_cols = 128
config.initial_rows = 32

return config
