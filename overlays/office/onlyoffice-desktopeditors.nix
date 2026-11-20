final: prev:
prev.lib.optionalAttrs (prev.stdenv.hostPlatform.system == "aarch64-linux") {
  onlyoffice-desktopeditors =
    if builtins.elem "aarch64-linux" prev.onlyoffice-desktopeditors.meta.platforms then
      prev.onlyoffice-desktopeditors
    else
      (prev.onlyoffice-desktopeditors.override {
        stdenv = prev.stdenv // {
          mkDerivation =
            args:
            (prev.stdenv.mkDerivation args).overrideAttrs (old: {
              src = final.fetchurl {
                url = prev.lib.replaceStrings [ "_amd64.deb" ] [ "_arm64.deb" ] old.src.url;
                hash = "sha256-4XYHfBeXfqL2nJPhCCE4ay9C+qW5I9X5vToS4ZzjsEA=";
              };

              # The arm64 deb ships Wayland plugins without libQt5WaylandClient, the wrapper forces xcb
              postInstall = (old.postInstall or "") + ''
                rm -f "$out"/share/desktopeditors/platforms/libqwayland-*.so
              '';
            });
        };
      }).overrideAttrs
        (old: {
          meta = old.meta // {
            platforms = old.meta.platforms ++ [ "aarch64-linux" ];
          };
        });
}
