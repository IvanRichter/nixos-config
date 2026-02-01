final: prev:

let
  lib = prev.lib;
  isDesktop = prev.stdenv.hostPlatform.system == "x86_64-linux";
in
if !isDesktop then
  { }
else
  let
    rustFlags = lib.concatStringsSep " " [
      "-C target-cpu=znver5"
      "-C target-feature=+avx512f,+avx512bw,+avx512dq,+avx512vl,+avx512cd"
    ];

    mergeFlags =
      old:
      lib.concatStringsSep " " (
        lib.filter (s: s != "") [
          (old.RUSTFLAGS or "")
          rustFlags
        ]
      );

    rustOverrides = old: {
      RUSTFLAGS = mergeFlags old;
      CARGO_PROFILE_RELEASE_LTO = "fat";
      CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
      CARGO_PROFILE_RELEASE_OPT_LEVEL = "3";
    };
  in
  {
    zellij = prev.zellij.overrideAttrs (old: rustOverrides old);
  }
