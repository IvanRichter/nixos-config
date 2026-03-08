{ lib, pkgs }:

pkg:
pkg.overrideAttrs (old: {
  NIX_CFLAGS_COMPILE = lib.concatStringsSep " " [
    (old.NIX_CFLAGS_COMPILE or "")
    "-march=znver5"
    "-O3"
    "-flto=auto"
  ];

  NIX_CFLAGS_LINK = lib.concatStringsSep " " [
    (old.NIX_CFLAGS_LINK or "")
    "-Wl,-O2"
    "-B${pkgs.wild}/bin"
  ];

  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.wild ];
})
