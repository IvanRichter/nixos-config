{ pkgs, lib, ... }:

let
  xfreerdpBin = lib.getExe' pkgs.freerdp "xfreerdp";

  rdpOpen = pkgs.writeShellScriptBin "rdp-open" ''
    set -euo pipefail

    # Silence multimedia logs
    export QT_LOGGING_RULES="qt.multimedia.*=false"
    export GSK_RENDERER=gl  # quiet GTK4/Vulkan swapchain warnings on Wayland/NVIDIA

    arg="''${1:-}"
    if [ -z "''${arg}" ]; then
      if command -v zenity >/dev/null 2>&1 && { [ -n "''${DISPLAY:-}" ] || [ -n "''${WAYLAND_DISPLAY:-}" ]; }; then
        zenity --error --title="RDP opener" --text="No .RDP file provided."
      else
        echo "No .RDP file provided." 1>&2
      fi
      exit 1
    fi

    # Normalize file:// URL to path and URL-decode
    urldecode() { local data="''${1//+/ }"; printf '%b' "''${data//%/\\x}"; }
    if [[ "''${arg}" =~ ^file:// ]]; then
      file="$(urldecode "''${arg#file://}")"
    else
      file="''${arg}"
    fi

    if [ ! -f "''${file}" ]; then
      if command -v zenity >/dev/null 2>&1 && { [ -n "''${DISPLAY:-}" ] || [ -n "''${WAYLAND_DISPLAY:-}" ]; }; then
        zenity --error --title="RDP opener" --text="RDP file not found:\n''${file}"
      else
        echo "RDP file not found: ''${file}" 1>&2
      fi
      exit 1
    fi

    # Extract fields from .rdp, strip CRs
    get_rdp_field() {
      local key="''${1:?}"
      grep -m1 -E "^''${key}:s:" "''${file}" | sed -E "s/^''${key}:s:(.*)$/\\1/" | tr -d '\r' || true
    }

    username="$(get_rdp_field username)"
    domain_from_file="$(get_rdp_field domain)"

    domain=""
    user=""
    if [[ -n "''${username}" && "''${username}" == *\\* ]]; then
      domain="''${username%%\\*}"
      user="''${username#*\\}"
    else
      user="''${username}"
      domain="''${domain_from_file}"
    fi

    has_gui=false
    if command -v zenity >/dev/null 2>&1 && { [ -n "''${DISPLAY:-}" ] || [ -n "''${WAYLAND_DISPLAY:-}" ]; }; then
      has_gui=true
    fi

    if $has_gui; then
      if [ -z "''${user}" ]; then
        user="$(zenity --entry --title="RDP username" --text="Enter username" || true)"
      fi
      pw="$(zenity --password --title="Password for ''${user:-<enter it>}" || true)"
    else
      if [ -z "''${user}" ]; then
        read -rp "Username: " user
      fi
      read -rsp "Password for ''${user:-<enter it>}: " pw; echo
    fi

    if [ -z "''${pw}" ]; then
      $has_gui && zenity --error --title="RDP opener" --text="Empty password. Aborting." || echo "Empty password. Aborting." 1>&2
      exit 1
    fi

    # Build args
    args=()
    [ -n "''${user}" ] && args+=(/u:"''${user}")
    [ -n "''${domain}" ] && args+=(/d:"''${domain}")
    args+=(/p:"''${pw}")

    # Heads-up: /p puts the password in the process list. If that offends your security sensibilities,
    # wire up a keyring and fetch here, or switch to a stdin-based flow. For now we go for convenience.

    log="/tmp/rdp-$RANDOM-$(date +%s).log"

    exec "${xfreerdpBin}" "''${file}" \
      "''${args[@]}" \
      /sec:nla /cert:ignore /dynamic-resolution +clipboard /sound:sys:pulse \
      /log-level:INFO >/dev/null 2>>"''${log}"
  '';

  rdpDesktop = pkgs.makeDesktopItem {
    name = "rdp-open";
    desktopName = "RDP (FreeRDP)";
    # %u so file:// URLs from file managers are passed intact
    exec = "rdp-open %u";
    icon = "computer";
    mimeTypes = [ "application/x-rdp" "application/rdp" ];
    categories = [ "Network" "RemoteAccess" ];
    terminal = false;
    startupNotify = false;
  };
in
{
  environment.systemPackages = [
    pkgs.freerdp
    pkgs.zenity
    rdpOpen
    rdpDesktop
  ];
}
