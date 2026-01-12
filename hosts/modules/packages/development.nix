{ pkgs }:

let
  dataform = pkgs.writeShellApplication {
    name = "dataform";
    runtimeInputs = [ pkgs.nodejs_24 ];
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
  nodejs_25
  corepack
  rustToolchain
  (python3.withPackages (pythonPackages: [
    pythonPackages.ipykernel
    pythonPackages.jupyter
    pythonPackages.bigquery-magics
  ]))

  # Build tools & compilers
  gcc
  gnumake
  pkg-config
  openssl

  # Dev tools
  google-cloud-sdk
  google-cloud-sql-proxy
  terraform
  pulumi-bin
  dbmate
  vulkan-tools
  libva-utils
  mesa-demos
  dataform
  lazysql
  gh
]
