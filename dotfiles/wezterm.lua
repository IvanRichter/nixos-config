local wezterm = require("wezterm")
local config = {}

config.color_scheme = "Tokyo Night"
config.font = wezterm.font_with_fallback({ "JetBrains Mono", "Noto Sans Mono" })
config.font_size = 12.5

config.enable_tab_bar = true
config.window_decorations = "TITLE|RESIZE"

config.window_background_opacity = 0.85
config.text_background_opacity = 1.0 
config.kde_window_background_blur = true

return config
