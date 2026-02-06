{ config, pkgs, ... }:

{
  imports = [
    ./packages/utils.nix
  ];

  environment.systemPackages =
    (import ./packages/browsers.nix { inherit pkgs; })
    ++ (import ./packages/ai.nix { inherit pkgs; })
    ++ (import ./packages/cli.nix { inherit pkgs; })
    ++ (import ./packages/comms.nix { inherit pkgs; })
    ++ (import ./packages/development.nix { inherit pkgs; })
    ++ (import ./packages/eid.nix { inherit pkgs; })
    ++ (import ./packages/office.nix { inherit pkgs; })
    ++ (import ./packages/video.nix { inherit pkgs; })
    ++ (import ./packages/graphics-apps.nix { inherit pkgs; });
}
