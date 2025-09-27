{ pkgs }:

let
  dataform = pkgs.writeShellApplication {
    name = "dataform";
    runtimeInputs = [ pkgs.nodejs_24 ];
    text = ''
      exec npx -y @dataform/cli@latest "$@"
    '';
  };
in

with pkgs; [
  # Programming languages & runtimes
  nodejs_24
  corepack_24
  rustup
  python3

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

  # IDEs
  vscode

  # Terminal
  wezterm
]
