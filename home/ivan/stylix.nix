{ ... }:

{
  stylix.targets = {
    starship.enable = true;
    rio.enable = false;
    vscode.enable = false;
  };

  imports = [
    ./stylix/starship.nix
    ./stylix/rio.nix
  ];
}
