{ ... }:

{
  stylix.targets = {
    starship.enable = true;
    wezterm.enable = true;
    vscode.enable = false;
  };

  imports = [
    ./stylix/starship.nix
    ./stylix/wezterm.nix
  ];
}
