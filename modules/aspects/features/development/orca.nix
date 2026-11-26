{ inputs, ... }:

{
  den.aspects.orca = {
    nixpkgs-overlays = _: {
      orca-ide = import "${inputs.self}/overlays/development/orca-ide.nix";
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.orca-ide ];
      };
  };
}
