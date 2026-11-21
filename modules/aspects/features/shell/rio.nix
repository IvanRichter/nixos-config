{ den, ... }:

{
  den.aspects.rio.homeManager =
    { config, lib, ... }:

    {
      programs.rio = {
        enable = true;
        settings = {
          colors.light-black = lib.mkForce config.lib.stylix.colors.withHashtag.base04;
          cursor = {
            shape = "beam";
          };
          "confirm-before-quit" = false;
          window.blur = true;
          window.decorations = "Disabled";
          fonts = {
            "use-drawable-chars" = true;
          };
          navigation = {
            mode = "Plain";
          };
          renderer = {
            performance = "High";
            backend = "Vulkan";
          };
          shell = {
            program = "zellij";
            args = [
              "attach"
              "-c"
            ];
          };
        };
      };
    };
}
