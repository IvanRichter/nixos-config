{ config, ... }:

{
  xdg.configFile."macchina/macchina.toml".text = ''
    theme = "Oganesson"

    show = [
      "Host",
      "Kernel",
      "Battery",
      "OperatingSystem",
      "DesktopEnvironment",
      "WindowManager",
      "Distribution",
      "Terminal",
      "Shell",
      "Packages",
      "Uptime",
      "Memory",
      "Machine",
      "LocalIP",
      "Backlight",
      "Resolution",
      "ProcessorLoad",
      "Processor",
      "GPU",
      "DiskSpace"
    ]
  '';

  xdg.configFile."macchina/themes/Oganesson.toml".text = ''
    # Oganesson

    spacing            = 6
    padding            = 0
    hide_ascii         = false
    prefer_small_ascii = false
    separator          = ""
    key_color          = "${config.lib.stylix.colors.withHashtag.base0A}"
    separator_color    = "Yellow"

    [palette]
    type    = "Full"
    glyph   = "██"
    visible = true

    # [bar]
    # glyph           = "ߋ"
    # symbol_open     = '['
    # symbol_close    = ']'
    # visible         = true
    # hide_delimiters = false

    [box]
    title           = " System Information "
    border          = "plain"
    visible         = true

    [box.inner_margin]
    x               = 3
    y               = 2

    [custom_ascii]
    color           = "${config.lib.stylix.colors.withHashtag.base0D}"
    path            = "~/.config/macchina/ascii/nixos-logo.ans"

    [randomize]
    key_color       = false
    separator_color = false
    # pool            = ""

    [keys]
    host            = "User@Hostname"
    kernel          = "Kernel"
    battery         = "Battery Info"
    os              = "Operating System"
    de              = "Desktop Environment"
    wm              = "Window Manager"
    distro          = "Distribution"
    terminal        = "Terminal Emulator"
    shell           = "Shell"
    packages        = "Packages (mgr)"
    uptime          = "Uptime"
    memory          = "Memory"
    machine         = "Machine"
    local_ip        = "Local IP"
    backlight       = "Brightness"
    resolution      = "Resolution"
    cpu_load        = "CPU Load"
    cpu             = "Processor (cores)"
    gpu             = "Graphics Processor"
    disk_space      = "Disk Space"
  '';

  xdg.configFile."macchina/ascii/nixos-logo.ans".source = ./nixos-logo.ans;

}
