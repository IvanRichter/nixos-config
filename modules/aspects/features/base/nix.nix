{
  den,
  inputs,
  ...
}:

{
  den.aspects.nix.nixos = { host, ... }: {
    imports = [ inputs.nix-index-database.nixosModules.nix-index ];

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    programs.nh = {
      enable = true;
      flake = "/home/ivan/nixos-config#${host.name}";

      # Keep recent rollbacks and one direnv root per project
      clean = {
        enable = true;
        extraArgs = "--keep 5 --keep-since 7d --keep-one";
      };
    };

    nix.optimise.automatic = true;

    # Drop stale nh result roots and other leftovers
    boot.tmp.cleanOnBoot = true;

    programs.nix-index.enable = true;
    programs.nix-index.enableFishIntegration = true;
    programs.command-not-found.enable = false;
    programs.nix-index-database.comma.enable = true;
  };
}
