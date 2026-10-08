final: prev: {
  cosmic-viewer = prev.cosmic-viewer.overrideAttrs (old: {
    # Use nixpkgs libheif for .heif and .heic support
    postPatch = (old.postPatch or "") + ''
      substituteInPlace Cargo.toml \
        --replace-fail '"embedded-libheif",' ""
    '';

    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.pkg-config ];
    buildInputs = (old.buildInputs or [ ]) ++ [ final.libheif ];
  });
}
