{ pkgs }:

let
  dataform = pkgs.writeShellApplication {
    name = "dataform";
    runtimeInputs = [ pkgs.nodejs_latest ];
    text = ''
      exec npx -y @dataform/cli@latest "$@"
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
  nodejs_latest
  pnpm
  rustToolchain
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

  # Git & version control
  git
  delta
  gh
  git-filter-repo
  ghgrab

  # Databases & SQL
  dbmate
  lazysql
  dbeaver-bin
  sqlfluff
  dataform

  # Graphics & GPU
  vulkan-tools
  libva-utils
  mesa-demos

  # Compression
  brotli

  # Utilities
  bruno
  nix-your-shell
]
