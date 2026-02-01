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
    cFlags = lib.concatStringsSep " " [
      "-O3"
      "-march=znver5"
      "-mavx512f"
      "-mavx512bw"
      "-mavx512dq"
      "-mavx512vl"
      "-mavx512cd"
    ];
  in
  {
    fish = prev.fish.overrideAttrs (old: {
      RUSTFLAGS = lib.concatStringsSep " " (
        lib.filter (s: s != "") [
          (old.RUSTFLAGS or "")
          rustFlags
        ]
      );
      CARGO_PROFILE_RELEASE_LTO = "fat";
      CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
      CARGO_PROFILE_RELEASE_OPT_LEVEL = "3";
      NIX_CFLAGS_COMPILE = lib.concatStringsSep " " (
        lib.filter (s: s != "") [
          (old.NIX_CFLAGS_COMPILE or "")
          cFlags
        ]
      );
    });
  }
