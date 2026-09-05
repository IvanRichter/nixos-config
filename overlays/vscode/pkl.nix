final: prev: {
  vscode-extensions = prev.vscode-extensions // {
    pkl = (prev.vscode-extensions.pkl or { }) // {
      pkl-vscode =
        let
          version = "0.23.0";
          javaPath = "${final.temurin-jre-bin-25}/bin/java";
          pklPath = "${final.pkl}/bin/pkl";
        in
        final.vscode-utils.buildVscodeExtension {
          pname = "pkl-vscode";
          inherit version;
          src = final.fetchurl {
            url = "https://github.com/apple/pkl-vscode/releases/download/${version}/pkl-vscode-${version}.vsix";
            hash = "sha256-HIPSiXWw0Ggv28hgvw+EGjcUfvH4/UVKZurI+33vWs8=";
          };
          vscodeExtPublisher = "Pkl";
          vscodeExtName = "pkl-vscode";
          vscodeExtUniqueId = "Pkl.pkl-vscode";

          nativeBuildInputs = [
            final.jq
            final.moreutils
          ];

          preInstall = ''
            jq --exit-status '
              .contributes.configuration.properties."pkl.cli.path" and
              .contributes.configuration.properties."pkl.lsp.java.path"
            ' package.json >/dev/null

            jq \
              --arg javaPath "${javaPath}" \
              --arg pklPath "${pklPath}" \
              '
                .contributes.configuration.properties."pkl.cli.path".default = $pklPath |
                .contributes.configuration.properties."pkl.lsp.java.path".default = $javaPath
              ' package.json | sponge package.json
          '';
        };
    };
  };
}
