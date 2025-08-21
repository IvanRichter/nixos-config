{ pkgs }:

with pkgs; [
  # Programming languages & runtimes
  nodejs_24
  rustup
  python3
  pnpm

  # Build tools & compilers
  gcc
  gnumake
  pkg-config
  openssl

  # Dev tools
  google-cloud-sdk
  terraform
  pulumi-bin

  # IDEs
  vscode

  # Terminal
  ghostty
]