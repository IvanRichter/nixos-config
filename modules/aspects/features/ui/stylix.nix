{
  den,
  inputs,
  ...
}:

{
  den.aspects.stylix = {
    nixos =
      { pkgs, ... }:

      let
        tokyoNight = builtins.toFile "tokyo-night.yaml" ''
          system: "base16"
          name: "Tokyo Night"
          variant: "dark"
          palette:
            base00: "#1a1b26"
            base01: "#16161e"
            base02: "#2f3549"
            base03: "#444b6a"
            base04: "#787c99"
            base05: "#a9b1d6"
            base06: "#cbccd1"
            base07: "#d5d6db"
            base08: "#f7768e"
            base09: "#ff9e64"
            base0A: "#e0af68"
            base0B: "#9ece6a"
            base0C: "#7dcfff"
            base0D: "#7aa2f7"
            base0E: "#bb9af7"
            base0F: "#db4b4b"
        '';
      in
      {
        imports = [ inputs.stylix.nixosModules.stylix ];

        stylix = {
          enable = true;
          polarity = "dark";

          base16Scheme = tokyoNight;

          opacity = {
            desktop = 0.7;
            popups = 0.7;
            terminal = 0.7;
          };

          cursor = {
            package = pkgs.simp1e-cursors;
            name = "Simp1e-Tokyo-Night";
            size = 24;
          };

          icons = {
            enable = true;
            package = pkgs.cosmic-icons;
            dark = "Cosmic";
            light = "Cosmic";
          };

          fonts = {
            serif = {
              package = pkgs.noto-fonts;
              name = "Noto Serif";
            };
            sansSerif = {
              package = pkgs.roboto;
              name = "Roboto";
            };
            monospace = {
              package = pkgs.nerd-fonts.meslo-lg;
              name = "MesloLGS Nerd Font Mono";
            };
            emoji = {
              package = pkgs.noto-fonts-color-emoji;
              name = "Noto Color Emoji";
            };
            sizes = {
              terminal = 13;
              popups = 13;
            };
          };
        };
      };

    homeManager =
      { ... }:

      {
        stylix.targets = {
          qt.standardDialogs = "xdgdesktopportal";
          starship.enable = true;
          kitty.enable = true;
          vscode.enable = false;
        };

      };
  };
}
