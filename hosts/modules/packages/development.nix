{ pkgs }:

with pkgs; [
  # Programming languages & runtimes
  nodejs_20
  rustup
  python3
  pnpm

  # Build tools & compilers
  gcc
  gnumake
  pkg-config
  openssl

  # Cloud SDKs & dev tools
  google-cloud-sdk
  terraform

  # IDEs
  vscode

  # Terminal
  ghostty
]