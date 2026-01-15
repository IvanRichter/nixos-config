{ ... }:

{
  stylix.targets = {
    starship.enable = true;
    rio.enable = true;
    vscode.enable = false;
  };

  imports = [
    ./stylix/starship.nix
    ./stylix/rio.nix
  ];
}
