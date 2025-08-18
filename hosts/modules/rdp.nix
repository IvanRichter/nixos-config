{ pkgs, ... }:

let
  rdpOpen = pkgs.writeShellScriptBin "rdp-open" ''
    set -euo pipefail
    
    # Shut up the Qt pipewire spam
    export QT_LOGGING_RULES="qt.multimedia.*=false"

    arg="''${1:-}"
    if [ -z "''${arg}" ]; then
      if command -v kdialog >/dev/null 2>&1; then
        kdialog --error "No .RDP file provided."
      fi
      exit 1
    fi

    # Normalize file:// URL from KDE to a real path and URL-decode
    urldecode() { local data="''${1//+/ }"; printf '%b' "''${data//%/\\x}"; }
    if [[ "''${arg}" =~ ^file:// ]]; then
      file="$(urldecode "''${arg#file://}")"
    else
      file="''${arg}"
    fi

    if [ ! -f "''${file}" ]; then
      command -v kdialog >/dev/null 2>&1 && kdialog --error "RDP file not found: ''${file}"
      exit 1
    fi

    # Extract fields from .rdp, strip Windows CRs
    get_rdp_field() {
      local key="''${1:?}"
      grep -m1 -E "^''${key}:s:" "''${file}" | sed -E "s/^''${key}:s:(.*)$/\\1/" | tr -d '\r' || true
    }

    username="$(get_rdp_field username)"
    domain_from_file="$(get_rdp_field domain)"

    # If username contains DOMAIN\user, split it. Otherwise keep as-is and use domain_from_file if present.
    domain=""
    user=""
    if [[ -n "''${username}" && "''${username}" == *\\* ]]; then
      domain="''${username%%\\*}"
      user="''${username#*\\}"
    else
      user="''${username}"
      domain="''${domain_from_file}"
    fi

    # Prompt if missing
    if command -v kdialog >/dev/null 2>&1; then
      if [ -z "''${user}" ]; then
        user="$(kdialog --inputbox "RDP username:" "" || true)"
      fi
      pw="$(kdialog --password "Password for ''${user:-<enter it>}" || true)"
    else
      if [ -z "''${user}" ]; then
        read -rp "Username: " user
      fi
      read -rsp "Password: " pw; echo
    fi

    # NLA dies on empty password → bail loud
    if [ -z "''${pw}" ]; then
      command -v kdialog >/dev/null 2>&1 && kdialog --error "Empty password. Aborting."
      exit 1
    fi

    # Build args without backslash escapes (use /u and /d separately)
    args=()
    [ -n "''${user}" ] && args+=(/u:"''${user}")
    [ -n "''${domain}" ] && args+=(/d:"''${domain}")
    args+=(/p:"''${pw}")

    # Log stderr so GUI clicks don’t fail silently
    log="/tmp/rdp-$RANDOM-$(date +%s).log"

    exec ${pkgs.freerdp}/bin/xfreerdp "''${file}" \
      "''${args[@]}" \
      /sec:nla /cert:ignore /dynamic-resolution +clipboard /sound:sys:pulse \
      /log-level:INFO >/dev/null 2>>"''${log}"
  '';

  rdpDesktop = pkgs.makeDesktopItem {
    name = "rdp-open";
    desktopName = "RDP (FreeRDP)";
    exec = "rdp-open %f";
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
    pkgs.kdePackages.kdialog
    rdpOpen
    rdpDesktop
  ];
}
