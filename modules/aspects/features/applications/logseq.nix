{ den, ... }:

{
  den.aspects.logseq.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.logseq_2 ];
    };
}
