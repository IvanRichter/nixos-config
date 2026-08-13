{
  den,
  inputs,
  ...
}:

{
  den.aspects.nix.nixos = {
    imports = [ inputs.nix-index-database.nixosModules.nix-index ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    programs.nh.enable = true;

    programs.nix-index.enable = true;
    programs.nix-index.enableFishIntegration = true;
    programs.command-not-found.enable = false;
    programs.nix-index-database.comma.enable = true;
  };
}
