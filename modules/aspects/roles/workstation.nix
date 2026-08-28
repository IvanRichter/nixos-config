{ den, ... }:

{
  den.aspects.workstation = {
    includes = with den.aspects; [
      nixpkgs
      nix
      fonts
      graphics
      stylix
      cosmic
      gui
      networking
      monitoring
      docker
      programs
      browsers
      iloader
      utils
      games
      ai
      codex
      cli
      comms
      development
      eid
      video
      graphics-apps
    ];

    nixos.documentation.man.enable = false;
  };
}
