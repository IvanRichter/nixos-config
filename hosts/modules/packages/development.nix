{ pkgs }:

let
  dataform = pkgs.writeShellApplication {
    name = "dataform";
    runtimeInputs = [ pkgs.bun ];
    text = ''
      exec bunx @dataform/cli@latest "$@"
    '';
  };
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "clippy"
      "rust-src"
      "rustfmt"
    ];
  };
in

with pkgs;
[
  # Programming languages & runtimes
  pnpm
  bun
  rustToolchain
  cargo-nextest
  cargo-outdated
  cargo-edit
  (python314.withPackages (pythonPackages: [
    pythonPackages.ipykernel
    pythonPackages.jupyter
    pythonPackages.bigquery-magics
  ]))

  # Build tools & compilers
  gcc
  gnumake
  pkg-config
  openssl

  # Cloud & infra
  google-cloud-sdk
  google-cloud-sql-proxy
  terraform
  pulumi-bin
  gws
  ansible

  # Git & version control
  git-filter-repo
  ghgrab
  pinact

  # Databases & SQL
  dbmate
  sqlfluff
  dataform

  # Graphics & GPU
  mesa-demos

  # Compression
  brotli

  # Utilities
  bruno
]
