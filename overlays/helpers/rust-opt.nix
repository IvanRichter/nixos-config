{ lib, pkgs }:

pkg:
pkg.overrideAttrs (old: {
  RUSTFLAGS = lib.concatStringsSep " " [
    (old.RUSTFLAGS or "")
    "-C target-cpu=znver5"
    "-C link-arg=-Wl,-O2"
    "-C link-arg=-B${pkgs.wild}/bin"
  ];

  CARGO_PROFILE_RELEASE_LTO = "fat";
  CARGO_PROFILE_RELEASE_CODEGEN_UNITS = "1";
  CARGO_PROFILE_RELEASE_OPT_LEVEL = "3";
  CARGO_PROFILE_RELEASE_STRIP = "symbols";

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.wild ];
})
