{
  config,
  pkgs,
  lib,
  ...
}:
{
  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    # Web pages and schemes
    "text/html" = [ "vivaldi-stable.desktop" ];
    "application/xhtml+xml" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/ftp" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/about" = [ "vivaldi-stable.desktop" ];
    "x-scheme-handler/unknown" = [ "vivaldi-stable.desktop" ];

    # Common file extensions
    "application/x-extension-htm" = [ "vivaldi-stable.desktop" ];
    "application/x-extension-html" = [ "vivaldi-stable.desktop" ];
    "application/x-extension-shtml" = [ "vivaldi-stable.desktop" ];
    "application/x-extension-xhtml" = [ "vivaldi-stable.desktop" ];

    # PDFs in browser
    "application/pdf" = [ "vivaldi-stable.desktop" ];

    # XML/SVG
    "application/xml" = [ "vivaldi-stable.desktop" ];
    "text/xml" = [ "vivaldi-stable.desktop" ];
    "image/svg+xml" = [ "vivaldi-stable.desktop" ];
  };

  # Apply a COSMIC-matched Vivaldi theme when the profile exists.
  home.activation.vivaldiTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python - <<'PY'
    import json
    import os
    from pathlib import Path

    home = Path(os.environ.get("HOME", "/home/ivan"))

    theme_id = "AnrikuCosmic"

    def update_prefs(prefs_path: Path) -> None:
      try:
        data = json.loads(prefs_path.read_text())
      except Exception:
        return

      vivaldi = data.setdefault("vivaldi", {})
      themes = vivaldi.setdefault("themes", {})
      theme_settings = vivaldi.setdefault("theme", {})
      schedule = theme_settings.setdefault("schedule", {})

      theme = {
        "engineVersion": 1,
        "version": 1,
        "id": theme_id,
        "name": "Anriku Cosmic",
        "accentFromPage": False,
        "accentOnWindow": False,
        "accentSaturationLimit": 1,
        "alpha": 1,
        "blur": 0,
        "colorAccentBg": "#000000",
        "colorBg": "#1e1e1e",
        "colorFg": "#d6d6d6",
        "colorHighlightBg": "#4af4fd",
        "colorWindowBg": "#000000",
        "contrast": 0,
        "dimBlurred": False,
        "preferSystemAccent": False,
        "radius": 10,
        "simpleScrollbar": True,
        "transparencyTabBar": False,
        "transparencyTabs": True,
        "url": "",
      }
      user_themes = themes.get("user", [])
      if not isinstance(user_themes, list):
        user_themes = []

      user_themes = [
        t for t in user_themes
        if not isinstance(t, dict) or t.get("id") != theme_id
      ]
      user_themes.append(theme)

      themes["user"] = user_themes
      themes["current"] = theme_id
      themes["current_private"] = theme_id

      # Disable schedule override and pin OS schedule to this theme anyway.
      schedule["enabled"] = 0
      schedule.setdefault("o_s", {})
      schedule["o_s"]["dark"] = theme_id
      schedule["o_s"]["light"] = theme_id
      theme_settings["private_window"] = theme_id

      prefs_path.write_text(json.dumps(data, indent=2))

    base = home / ".config/vivaldi"
    if not base.exists():
      raise SystemExit(0)

    for prefs_path in base.glob("*/Preferences"):
      update_prefs(prefs_path)
    PY
  '';
}
