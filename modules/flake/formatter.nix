{ inputs, ... }:

{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { system, ... }:
    {
      formatter = inputs.nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
