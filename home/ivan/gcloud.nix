{ lib, pkgs, ... }:

let
  defaultConfig = "anriku";
  configs = {
    anriku = {
      core.project = "anriku-public-prd";
      run.region = "europe-west1";
      compute.region = "europe-west1";
    };
    happyend = {
      core.project = "he-dlh-prd";
      run.region = "europe-west1";
      compute.region = "europe-west1";
    };
  };
in
{
  home.activation.gcloudConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] (''
    set -euo pipefail

    gcloud_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/gcloud"
    configs_dir="$gcloud_dir/configurations"
    install -d -m 700 "$configs_dir"

    export GCLOUD_MANAGED_CONFIGS=${lib.escapeShellArg (builtins.toJSON configs)}
    export GCLOUD_DEFAULT_CONFIG=${lib.escapeShellArg defaultConfig}

    ${pkgs.python3}/bin/python3 <<'PY'
    import configparser
    import json
    import os
    import pathlib
    import tempfile

    configs = json.loads(os.environ["GCLOUD_MANAGED_CONFIGS"])
    gcloud_dir = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", os.path.join(os.environ["HOME"], ".config"))) / "gcloud"
    configs_dir = gcloud_dir / "configurations"
    configs_dir.mkdir(mode=0o700, parents=True, exist_ok=True)

    for name, sections in configs.items():
        config_path = configs_dir / f"config_{name}"
        parser = configparser.RawConfigParser()
        parser.optionxform = str

        if config_path.exists():
            parser.read(config_path)

        for section, properties in sections.items():
            if not parser.has_section(section):
                parser.add_section(section)
            for key, value in properties.items():
                parser.set(section, key, value)

        with tempfile.NamedTemporaryFile("w", dir=configs_dir, delete=False) as tmp:
            parser.write(tmp)
            temp_path = pathlib.Path(tmp.name)

        os.chmod(temp_path, 0o600)
        temp_path.replace(config_path)
        os.chmod(config_path, 0o600)

    active_config = gcloud_dir / "active_config"
    if not active_config.exists():
        active_config.write_text(os.environ["GCLOUD_DEFAULT_CONFIG"] + "\n")
        os.chmod(active_config, 0o600)
    PY
  '');
}
