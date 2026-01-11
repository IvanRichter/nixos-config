{ config, ... }:

{
  programs.rio = {
    enable = true;
    settings = {
      cursor = {
        shape = "beam";
      };
      "confirm-before-quit" = false;
      window.opacity = config.stylix.opacity.terminal;
      window.blur = true;
      fonts = {
        family = config.stylix.fonts.monospace.name;
        size = config.stylix.fonts.sizes.terminal;
        emoji = {
          family = config.stylix.fonts.emoji.name;
        };
      };
      colors = {
        selection-background = config.lib.stylix.colors.withHashtag.base03;
        selection-foreground = config.lib.stylix.colors.withHashtag.base05;
      };
      renderer = {
        performance = "High";
        backend = "Vulkan";
      };
    };
  };
}
