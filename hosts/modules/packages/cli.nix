{ pkgs }:
with pkgs;
[
  # Network / HTTP
  wget
  curl
  xh
  gip

  # Editors
  micro-full

  # Archives
  unzip
  zip

  # File navigation
  broot
  yazi
  tree
  eza
  zoxide
  fd
  skim

  # File/system utilities
  lsof
  file
  usbutils
  evtest
  bat
  ripgrep
  sd
  dust
  ast-grep
  tokei

  # JSON processing
  jaq

  # YAML processing
  yq-go

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
