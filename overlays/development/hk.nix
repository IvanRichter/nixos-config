final: prev: {
  hk =
    if prev.lib.versionAtLeast prev.hk.version "2.8.0" then
      prev.hk
    else
      prev.hk.overrideAttrs (
        finalAttrs: old: {
          version = "2.8.0";
          src = final.fetchFromGitHub {
            owner = "jdx";
            repo = "hk";
            tag = "v${finalAttrs.version}";
            hash = "sha256-swKjqQwTHKM88bTa6HloJsRtj9JoeWFE+WwjvjlcP7E=";
          };
          cargoHash = "sha256-VG0foVC3NHKgJcVF25bnC81114g50U4mZUgEnYMsSTQ=";
          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname version src;
            hash = finalAttrs.cargoHash;
          };

          nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
            final.pkl
            final.python3
          ];

          # Generate metadata and Pkl modules omitted from the source archive
          preBuild = (old.preBuild or "") + ''
            python3 scripts/gen_builtins.py
          '';
          env = (old.env or { }) // {
            HK_REQUIRE_EMBEDDED_PKL = "1";

            # Requried by Reqwest
            SSL_CERT_FILE = "${final.cacert}/etc/ssl/certs/ca-bundle.crt";
          };

          # Tests need writable caches and a Git checkout
          preCheck = (old.preCheck or "") + ''
            export XDG_CACHE_HOME="$TMPDIR/hk-cache"
            export XDG_CONFIG_HOME="$TMPDIR/hk-config"
            mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
            git init --quiet
          '';
          checkFlags = [ ];

          # Give ELF fixups a fresh inode
          preFixup =
            (old.preFixup or "")
            + final.lib.optionalString final.stdenv.hostPlatform.isLinux ''
              cp "$out/bin/hk" "$out/bin/.hk-fixup"
              mv "$out/bin/.hk-fixup" "$out/bin/hk"
            '';
        }
      );
}
