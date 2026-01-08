{ config, pkgs, ... }:

{
  environment.systemPackages =
    (import ./packages/browsers.nix { inherit pkgs; })
    ++ (import ./packages/cli.nix { inherit pkgs; })
    ++ (import ./packages/comms.nix { inherit pkgs; })
    ++ (import ./packages/development.nix { inherit pkgs; })
    ++ (import ./packages/eid.nix { inherit pkgs; })
    ++ (import ./packages/utils.nix { inherit pkgs; })
    ++ (import ./packages/graphics-apps.nix { inherit pkgs; });
}
