{ pkgs, ... }:

let
  oneDarkProNightFlat = builtins.toFile "one-dark-pro-night-flat.yaml" ''
    system: "base16"
    name: "One Dark Pro Night Flat"
    variant: "dark"
    palette:
      base00: "#16191d"
      base01: "#1e2227"
      base02: "#2c313c"
      base03: "#5c6370"
      base04: "#7f848e"
      base05: "#abb2bf"
      base06: "#d7dae0"
      base07: "#ffffff"
      base08: "#e06c75"
      base09: "#d19a66"
      base0A: "#e5c07b"
      base0B: "#98c379"
      base0C: "#56b6c2"
      base0D: "#61afef"
      base0E: "#c678dd"
      base0F: "#f44747"
  '';
in
{
  stylix = {
    enable = true;
    polarity = "dark";

    # Use inlined One Dark Pro Night Flat scheme
    base16Scheme = oneDarkProNightFlat;

    opacity.terminal = 0.8;

    fonts = {
      serif = {
        name = "Noto Serif";
      };
      sansSerif = {
        name = "Roboto";
      };
      monospace = {
        name = "MesloLGS Nerd Font Mono";
      };
      emoji = {
        name = "Noto Color Emoji";
      };
      sizes = {
        terminal = 16;
        popups = 16;
      };
    };
  };
}
