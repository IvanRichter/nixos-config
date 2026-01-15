{ ... }:

{
  programs.rio = {
    enable = true;
    settings = {
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
}
