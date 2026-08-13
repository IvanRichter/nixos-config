{ den, ... }:

{
  den.aspects.graphics-apps.nixos = { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      gimp
      fontforge-gtk
      graphite
      glaxnimate
      drawio
      upscaler
    ];
  };
}
