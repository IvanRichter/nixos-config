{ pkgs, lib, ... }:

let
  rdpOpen = pkgs.writeShellScriptBin "rdp-open" ''
    set -euo pipefail
    export GSK_RENDERER="''${GSK_RENDERER:-ngl}"

    # Accept a path or file:// URL
    arg="''${1:-}"
    [ -n "''${arg}" ] || { echo "Usage: rdp-open <file.rdp>"; exit 1; }
    case "''${arg}" in
      file://*) file="$(printf '%s' "''${arg}" | sed -E 's#^file://##')";;
      *)        file="''${arg}";;
    esac

    # Prefer Wayland client on Wayland
    if [ "''${RDP_FORCE_X11:-0}" = "1" ]; then
      client=xfreerdp
    elif [ -n "''${WAYLAND_DISPLAY:-}" ] && command -v sdl-freerdp3 >/dev/null 2>&1; then
      client=sdl-freerdp3
    else
      client=xfreerdp
    fi

    # -- HiDPI check via DRM (max width across connectors) --
    panel_width_from_drm() {
      local max=0 line w
      for f in /sys/class/drm/*/modes; do
        [ -r "$f" ] || continue
        while IFS= read -r line; do
          case "$line" in
            *x*)
              w="''${line%%x*}"
              if [ -n "''${w}" ] && [ "''${w}" -gt "''${max}" ] 2>/dev/null; then
                max="''${w}"
              fi
              ;;
          esac
        done < "$f"
      done
      echo "''${max}"
    }

    min_width="''${RDP_HIDPI_MIN_WIDTH:-2560}"
    force_zoom=0
    w="$(panel_width_from_drm)"
    [ "''${w}" -ge "''${min_width}" ] 2>/dev/null && force_zoom=1
    [ "''${NO_AUTO_HIDPI:-0}" = "1" ] && force_zoom=0

    # Clipboard + dynamic res + local drive mapping for reliable file transfer
    base_flags=(/sec:nla /cert:ignore +clipboard /dynamic-resolution)
    drive_flags=()
    if [ "''${RDP_NO_DRIVES:-0}" != "1" ]; then
      drive_flags+=(/drive:home,"''${HOME}")          # \\tsclient\home
      [ -n "''${RDP_SHARE_DIR:-}" ] && drive_flags+=(/drive:shared,"''${RDP_SHARE_DIR}")
    fi

    # Scaling flags with overrides
    scale_flags=()
    case "''${RDP_MODE:-scale}" in
      smart)
        scale_flags=(/smart-sizing)
        [ -n "''${RDP_SMART_SIZE:-}" ] && scale_flags+=("/size:''${RDP_SMART_SIZE}")  # e.g. 1920x1200
        # smart-sizing fights dynamic-resolution; drop it here
        base_flags=(/sec:nla /cert:ignore +clipboard)
        ;;
      *)
        if [ -n "''${RDP_SCALE_DISPLAY-}''${RDP_SCALE_DESKTOP-}''${RDP_SCALE_DEVICE-}" ]; then
          [ -n "''${RDP_SCALE_DISPLAY-}" ] && scale_flags+=("/scale:''${RDP_SCALE_DISPLAY}")
          [ -n "''${RDP_SCALE_DESKTOP-}" ] && scale_flags+=("/scale-desktop:''${RDP_SCALE_DESKTOP}")
          [ -n "''${RDP_SCALE_DEVICE-}" ] && scale_flags+=("/scale-device:''${RDP_SCALE_DEVICE}")
        elif [ "''${force_zoom}" = "1" ]; then
          scale_flags=(/scale:180 /scale-desktop:200 /scale-device:180)
        fi
        ;;
    esac

    [ "''${RDP_DEBUG:-0}" = "1" ] && {
      echo "client=$client width=$w force_zoom=$force_zoom mode=''${RDP_MODE:-scale}"
      printf 'flags:'; printf ' %q' "''${base_flags[@]}" "''${drive_flags[@]}" "''${scale_flags[@]}"; echo
    }

    exec "$client" "''${file}" \
      "''${base_flags[@]}" \
      "''${drive_flags[@]}" \
      "''${scale_flags[@]}" \
      /sound:sys:pulse
  '';
in
{
  xdg.enable = lib.mkDefault true;

  home.packages = [
    pkgs.freerdp
    pkgs.shared-mime-info
    pkgs.desktop-file-utils
    rdpOpen
  ];

  # Desktop for FreeRDP with flags
  xdg.desktopEntries."rdp-open" = {
    name = "RDP (FreeRDP)";
    exec = "${rdpOpen}/bin/rdp-open %u";
    icon = "computer";
    type = "Application";
    categories = [ "Network" "RemoteAccess" ];
    mimeType = [ "application/x-rdp" "application/rdp" ];
    terminal = false;
  };

  # *.rdp mime-info
  home.file.".local/share/mime/packages/rdp.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
      <mime-type type="application/x-rdp">
        <comment>Remote Desktop Protocol</comment>
        <glob pattern="*.rdp"/>
      </mime-type>
      <mime-type type="application/rdp">
        <comment>Remote Desktop Protocol</comment>
        <glob pattern="*.rdp"/>
      </mime-type>
    </mime-info>
  '';

  # Make rdp-open the default handler for RDP files
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/x-rdp" = [ "rdp-open.desktop" ];
    "application/rdp"   = [ "rdp-open.desktop" ];
  };

  # Rebuild the MIME + desktop caches on activation
  home.activation.refreshXdgDBs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.shared-mime-info}/bin/update-mime-database "$HOME/.local/share/mime" || true
    ${pkgs.desktop-file-utils}/bin/update-desktop-database "$HOME/.local/share/applications" || true
  '';

  # Hard-create the desktop file
  home.file.".local/share/applications/rdp-open.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=RDP (FreeRDP)
    Exec=${rdpOpen}/bin/rdp-open %u
    Icon=computer
    Categories=Network;RemoteAccess;
    MimeType=application/x-rdp;application/rdp;
    Terminal=false
  '';
}
