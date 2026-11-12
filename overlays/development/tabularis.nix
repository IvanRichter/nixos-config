_final: prev:
let
  lockDependencyLines =
    dependencies: prev.lib.concatMapStrings (name: " \"${name}\",\n") dependencies;

  # Keep the application and vendored dependencies on the same Cargo.lock
  enableNativeTls = ''
    substituteInPlace src-tauri/Cargo.toml \
      --replace-fail '"tls-rustls-ring-native-roots"' '"tls-native-tls"'

    substituteInPlace src-tauri/Cargo.lock \
      --replace-fail $'name = "ndk"\n' ${prev.lib.escapeShellArg ''
        name = "native-tls"
        version = "0.2.18"
        source = "registry+https://github.com/rust-lang/crates.io-index"
        checksum = "465500e14ea162429d264d44189adc38b199b62b1c21eea9f69e4b73cb03bbf2"
        dependencies = [
         "libc",
         "log",
         "openssl",
         "openssl-probe",
         "openssl-sys",
         "schannel",
         "security-framework 3.7.0",
         "security-framework-sys",
         "tempfile",
        ]

        [[package]]
        name = "ndk"
      ''} \
      --replace-fail ${
        prev.lib.escapeShellArg (lockDependencyLines [
          "memchr"
          "once_cell"
          "percent-encoding"
          "rust_decimal"
          "rustls"
          "rustls-native-certs"
        ])
      } ${
        prev.lib.escapeShellArg (lockDependencyLines [
          "memchr"
          "native-tls"
          "once_cell"
          "percent-encoding"
          "rust_decimal"
        ])
      }
  '';
in
prev.lib.optionalAttrs prev.stdenv.hostPlatform.isLinux {
  # Gibbor serves an X.509 v1 certificate that SQLx's rustls backend rejects
  # Use OpenSSL through native-tls
  tabularis = prev.tabularis.overrideAttrs (
    finalAttrs: old: {
      postPatch = (old.postPatch or "") + enableNativeTls;
      cargoHash = "sha256-3i7iz3LzBbLZSN27tUIHya0myuYuiI1F5IN6tWP51/o=";
      cargoDeps = prev.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs)
          pname
          version
          src
          cargoRoot
          ;
        postPatch = enableNativeTls;
        hash = finalAttrs.cargoHash;
      };
    }
  );

  tabularis-sqlserver-plugin = prev.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "tabularis-sqlserver-plugin";
    version = "1.0.1";

    src =
      let
        platform =
          {
            aarch64-linux = {
              arch = "arm64";
              hash = "sha256-CX2p81KgTgri6mOOykKvWv39jh+0Rpa9buZx1bz9yI0=";
            };
            x86_64-linux = {
              arch = "x64";
              hash = "sha256-Dxf7wTfC8ZzeG+ydFgkGVV4/VeBPpEQgfAP+axQV0yY=";
            };
          }
          .${prev.stdenv.hostPlatform.system};
      in
      prev.fetchurl {
        url = "https://github.com/TabularisDB/tabularis-sqlserver-plugin/releases/download/v${finalAttrs.version}/sqlserver-plugin-linux-${platform.arch}.zip";
        inherit (platform) hash;
      };

    nativeBuildInputs = [
      prev.unzip
      prev.autoPatchelfHook
    ];
    buildInputs = [ prev.stdenv.cc.cc.lib ];
    sourceRoot = ".";
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      plugin_dir="$out/share/tabularis/plugins/sqlserver"
      mkdir -p "$plugin_dir"
      cp -r .tabularium sqlserver-plugin ui explain assets "$plugin_dir/"
      chmod +x "$plugin_dir/sqlserver-plugin"
      runHook postInstall
    '';

    doInstallCheck = prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform;
    nativeInstallCheckInputs = [ prev.python3 ];
    installCheckPhase = ''
      runHook preInstallCheck
      PLUGIN="$out/share/tabularis/plugins/sqlserver/sqlserver-plugin" python3 <<'PY'
      import json
      import os
      import subprocess

      requests = [
          {"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"settings": {}}},
          {"jsonrpc": "2.0", "id": 2, "method": "shutdown", "params": {}},
      ]
      result = subprocess.run(
          [os.environ["PLUGIN"]],
          input="".join(json.dumps(request) + "\n" for request in requests),
          encoding="utf-8",
          capture_output=True,
          check=True,
          timeout=10,
      )
      responses = [json.loads(line) for line in result.stdout.splitlines()]
      assert sorted(response["id"] for response in responses) == [1, 2], responses
      assert all("result" in response and "error" not in response for response in responses), responses
      PY
      runHook postInstallCheck
    '';

    meta = {
      description = "Microsoft SQL Server driver plugin for Tabularis";
      homepage = "https://github.com/TabularisDB/tabularis-sqlserver-plugin";
      license = prev.lib.licenses.asl20;
      sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
      platforms = [
        "aarch64-linux"
        "x86_64-linux"
      ];
    };
  });
}
