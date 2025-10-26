{ config, pkgs, ... }: {
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  programs.nix-index.enable = true;
  programs.nix-index.enableFishIntegration = true;
  programs.command-not-found.enable = false;      
  programs.nix-index-database.comma.enable = true;
}