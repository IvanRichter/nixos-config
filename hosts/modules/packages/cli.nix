{ pkgs }:
with pkgs;
[
  # Network / HTTP
  wget
  xh
  gip
  gping

  # Editors
  micro-full

  # Archives
  unzip
  zip

  # Document processing
  ghostscript

  # File navigation
  tree
  fd

  # File/system utilities
  lsof
  file
  usbutils
  evtest
  ripgrep
  sd
  dust
  ast-grep
  tokei

  # JSON processing
  jaq
  jf

  # YAML processing
  yq-go

  # Nix tooling
  nix-output-monitor
  nixfmt

  # System info

  # Clipboard
  wl-clipboard-rs

  # DNS
  doggo
]
