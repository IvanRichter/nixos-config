{ pkgs }:
let
  isX86 = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
in
with pkgs;
[
  # AI coding workflow tools
  beads
  repomix
  rtk

  # Archives, compression, and file movement
  p7zip
  pv

  # Structured data and shell helpers
  jq
  jo
  gron
  miller
  qsv
  csvkit
  htmlq
  jc
  choose
  ripgrep-all
  fzf
  shellcheck
  shfmt
  hyperfine
  just
  entr
  watchexec
  moreutils
  socat
  netcat-openbsd
  sqlite
  jless
  parallel
  inotify-tools
  tealdeer
  dos2unix

  # Network, transport, and low-level debugging
  inetutils
  whois
  nmap
  traceroute
  iperf3
  ltrace

  # Raw byte inspection
  hexyl
  xxd

  # Content conversion, rendering, and syntax-aware inspection
  graphviz
  imagemagick
  pandoc
  poppler-utils
  tree-sitter

  # Local services and large-asset helpers
  postgresql
  redis
]

++ lib.optionals isX86 [
  # Local AI
  lmstudio
]
