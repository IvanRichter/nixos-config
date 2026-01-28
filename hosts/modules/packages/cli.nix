{ pkgs }:
with pkgs;
[
  # Network / HTTP
  wget
  curl
  xh

  # Version control
  git

  # Editors
  micro-full

  # Archives
  unzip
  zip

  # File navigation
  broot
  tree
  eza
  zoxide
  fd

  # File/system utilities
  lsof
  file
  usbutils
  evtest
  bat
  ripgrep
  dust

  # JSON processing
  jaq

  # Nix tooling
  nix-output-monitor
  nixfmt

  # System info
  macchina
  bottom

  # Clipboard
  wl-clipboard-rs

  # DNS
  doggo
]
