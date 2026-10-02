_final: prev: {
  rigel = prev.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "rigel";
    version = "1.23.2";

    src = prev.fetchurl {
      url = "https://github.com/rigelminer/rigel/releases/download/${finalAttrs.version}/rigel-${finalAttrs.version}-linux.tar.gz";
      hash = "sha256-6uSS/7ZK60q0un5mYxVnmEox1a2x71R72mYBruF5Pw0=";
    };

    nativeBuildInputs = [ prev.makeWrapper ];

    # Rigel checks its own executable and rejects autoPatchelf changes
    # Mount its expected loader privately while keeping the binary unchanged
    dontPatchELF = true;
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;
    preferLocalBuild = true;
    allowSubstitutes = false;

    installPhase = ''
      runHook preInstall
      install -Dm755 rigel "$out/libexec/rigel"
      makeWrapper ${prev.lib.getExe prev.bubblewrap} "$out/bin/rigel" \
        --add-flags "--unshare-user --die-with-parent --dev-bind / / --tmpfs /lib64" \
        --add-flags "--ro-bind ${prev.stdenv.cc.bintools.dynamicLinker} /lib64/ld-linux-x86-64.so.2" \
        --add-flags "--setenv LD_LIBRARY_PATH ${prev.addDriverRunpath.driverLink}/lib:${
          prev.lib.makeLibraryPath [ prev.stdenv.cc.cc.lib ]
        }" \
        --add-flags "-- $out/libexec/rigel"
      install -Dm644 README.md "$out/share/doc/rigel/README.md"
      runHook postInstall
    '';

    meta = {
      description = "Proprietary NVIDIA GPU miner with the upstream developer fee";
      homepage = "https://github.com/rigelminer/rigel";
      license = prev.lib.licenses.unfree;
      platforms = [ "x86_64-linux" ];
      sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
      mainProgram = "rigel";
    };
  });
}
