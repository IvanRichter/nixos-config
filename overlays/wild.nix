final: prev:

let
  lib = prev.lib;
  hasWild = prev ? wild-unwrapped;
in
if !hasWild then
  { }
else
{
    # Applied after wild.overlays.default to enable plugin support in wild-linker
    wild-unwrapped = prev.wild-unwrapped.overrideAttrs (old: {
      buildPhase =
        let
          base = old.buildPhase or "";
        in
        if lib.hasInfix "--features plugins" base then
          base
        else
          lib.replaceStrings
            [ "cargo build --profile release -p wild-linker" ]
            [ "cargo build --profile release -p wild-linker --features plugins" ]
            base;

      cargoBuildCommand =
        let
          base = old.cargoBuildCommand or "cargo build --profile release -p wild-linker";
        in
        if lib.hasInfix "--features plugins" base then base else "${base} --features plugins";

      # CPU tuning
      RUSTFLAGS = lib.concatStringsSep " " [
        (old.RUSTFLAGS or "")
        "-C target-cpu=znver5"
      ];

      # Optimization
      CARGO_PROFILE_RELEASE_LTO = "fat";
      CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
      CARGO_PROFILE_RELEASE_OPT_LEVEL = "3";
      CARGO_PROFILE_RELEASE_STRIP = "symbols";

      meta = old.meta // {
        description = "${old.meta.description} (plugins feature enabled)";
      };
    });
  }
