final: prev: {
  vivaldi = final.lib.makeOverridable (
    args:
    (prev.vivaldi.override args).overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ final.pciutils ];

      postInstall = (old.postInstall or "") + ''
        patchelf --add-rpath "${final.lib.getLib final.pciutils}/lib" \
          "$out/opt/vivaldi/vivaldi-bin"
      '';
    })
  ) { };
}
