{ den, ... }:

{
  perSystem =
    { pkgs, ... }:
    {
      packages = den.lib.nh.denPackages {
        fromFlake = true;
        fromPath = "/home/ivan/nixos-config";
      } pkgs;
    };
}
