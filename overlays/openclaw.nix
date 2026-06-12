_final: prev:
let
  storeDirConfig = ''pnpm config set store-dir $storePath'';
  pnpmFetchConfig = ''
    pnpm config set store-dir $storePath
    pnpm config set fetch-timeout 1200000
    pnpm config set fetch-retries 10
    pnpm config set fetch-retry-maxtimeout 120000
    pnpm config set network-concurrency 4
  '';
in
{
  openclaw = prev.openclaw.overrideAttrs (old: {
    pnpmDeps = old.pnpmDeps.overrideAttrs (depsOld: {
      installPhase =
        assert prev.lib.hasInfix storeDirConfig depsOld.installPhase;
        builtins.replaceStrings [ storeDirConfig ] [ pnpmFetchConfig ] depsOld.installPhase;
    });
  });
}
