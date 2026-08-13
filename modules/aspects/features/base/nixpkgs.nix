{ den, inputs, ... }:

{
  # Home Manager uses the host's pkgs instance, so keep all overlays together
  # on the host-side aspect shared by every workstation concern.
  den.aspects.nixpkgs.nixos.nixpkgs = {
    config.allowUnfree = true;
    overlays = import ../../../../overlays ++ [
      inputs.rust-overlay.overlays.default
      inputs.nix-vscode-extensions.overlays.default
    ];
  };
}
