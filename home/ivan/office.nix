{ pkgs, lib, ... }:
{
  xdg.mimeApps.enable = true;

  # Make ONLYOFFICE the default app for .docx, .xlsx, and .pptx
  xdg.mimeApps.defaultApplications = {
    "application/vnd.openxmlformats-officedocument.wordprocessingml.document" = [
      "onlyoffice-desktopeditors.desktop"
    ];
    "application/vnd.openxmlformats-officedocument.presentationml.presentation" = [
      "onlyoffice-desktopeditors.desktop"
    ];
    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = [
      "onlyoffice-desktopeditors.desktop"
    ];
  };

  # Set Modern Dark theme and enable GPU acceleration
  home.activation.onlyofficeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python - <<'PY'
    import base64
    import json
    import os
    import re
    import xml.etree.ElementTree as ET
    from pathlib import Path

    home = Path(os.environ.get("HOME", "/home/ivan"))

    # Update DesktopEditors.conf (Qt settings)
    conf_path = home / ".config/onlyoffice/DesktopEditors.conf"
    conf_path.parent.mkdir(parents=True, exist_ok=True)
    text = conf_path.read_text() if conf_path.exists() else "[General]\n"
    lines = text.splitlines()

    appdata_b64 = None
    for line in lines:
      if line.startswith("appdata="):
        m = re.match(r'appdata="?(?:@ByteArray\(([^)]+)\))"?', line)
        if m:
          appdata_b64 = m.group(1)
          break

    data = {}
    if appdata_b64:
      try:
        data = json.loads(base64.b64decode(appdata_b64).decode("utf-8"))
      except Exception:
        data = {}

    data.setdefault("username", os.environ.get("USER", ""))
    data["uitheme"] = "theme-night"
    data["usegpu"] = True

    encoded = base64.b64encode(
      json.dumps(data, separators=(",", ":")).encode("utf-8")
    ).decode("utf-8")
    new_appdata_line = f'appdata="@ByteArray({encoded})"'

    has_general = any(line == "[General]" for line in lines)
    if not has_general:
      out_lines = ["[General]", "UITheme=theme-night", new_appdata_line, ""] + lines
    else:
      out_lines = []
      in_general = False
      seen_ui = False
      seen_app = False

      for line in lines:
        if line.startswith("[") and line.endswith("]"):
          if in_general:
            if not seen_ui:
              out_lines.append("UITheme=theme-night")
              seen_ui = True
            if not seen_app:
              out_lines.append(new_appdata_line)
              seen_app = True
          in_general = (line == "[General]")
          out_lines.append(line)
          continue

        if in_general and line.startswith("UITheme="):
          out_lines.append("UITheme=theme-night")
          seen_ui = True
          continue
        if in_general and line.startswith("appdata="):
          out_lines.append(new_appdata_line)
          seen_app = True
          continue

        out_lines.append(line)

      if in_general:
        if not seen_ui:
          out_lines.append("UITheme=theme-night")
        if not seen_app:
          out_lines.append(new_appdata_line)

    conf_path.write_text("\n".join(out_lines).rstrip() + "\n")

    # Update settings.xml for GPU toggle
    settings_path = home / ".local/share/onlyoffice/desktopeditors/data/settings.xml"
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    try:
      root = ET.parse(settings_path).getroot()
    except Exception:
      root = ET.Element("Settings")

    disable_gpu = root.find("disable-gpu")
    if disable_gpu is None:
      disable_gpu = ET.SubElement(root, "disable-gpu")
    disable_gpu.text = "0"

    settings_path.write_text(ET.tostring(root, encoding="unicode"))
    PY
  '';
}
