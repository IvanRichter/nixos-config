_final: prev:
let
  pname = "orca-ide";
  version = "1.4.280";

  asset =
    {
      aarch64-linux = {
        name = "orca-linux-arm64.AppImage";
        hash = "sha256-NNsHbb9RyJ8Bpz2572oXxCu5kSTpXeGX71efLN2fquY=";
      };
      x86_64-linux = {
        name = "orca-linux.AppImage";
        hash = "sha256-f6TZdb3RUXh7sSU3kIRk+HaV7MPxwmz1UyIO6G08BsI=";
      };
    }
    .${prev.stdenv.hostPlatform.system};

  src = prev.fetchurl {
    url = "https://github.com/stablyai/orca/releases/download/v${version}/${asset.name}";
    inherit (asset) hash;
  };

  contents = prev.appimageTools.extract { inherit pname version src; };
in
{
  orca-ide = prev.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${contents}/usr/share/icons $out/share
    '';

    meta = {
      description = "Agent IDE for running coding agents in parallel worktrees";
      homepage = "https://github.com/stablyai/orca";
      license = prev.lib.licenses.mit;
      sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = pname;
    };
  };
}
