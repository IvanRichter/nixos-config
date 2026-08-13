{ den, ... }:

{
  den.aspects.tabularis.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    let
      connectionId = "gibbor-mariadb";
      stateDir = "${config.xdg.stateHome}/tabularis";
      connectionsFile = "${stateDir}/connections.json";
      desiredConnection = {
        id = connectionId;
        name = "Gibbor";
        params = {
          driver = "mysql";
          host = "www.gibbor.eu";
          port = 3306;
          username = "an-reader";
          database = "igibbor_test_cz";
          ssl_mode = "disable";
          ssh_enabled = false;
          save_in_keychain = true;
        };
      };
      desiredConnectionJson = builtins.toJSON desiredConnection;

      tabularisSetup = pkgs.writeShellScriptBin "tabularis-setup" ''
        set -euo pipefail
        umask 077

        config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
        connections_file="$config_home/tabularis/connections.json"

        if [ ! -f "$connections_file" ]; then
          echo "tabularis-setup: connections config not found; run home-manager switch first" >&2
          exit 1
        fi

        CONNECTIONS_FILE="$connections_file" \
          CONNECTION_ID="${connectionId}" \
          ${pkgs.python3}/bin/python3 <<'PY'
        import json
        import os
        import sys
        from pathlib import Path

        path = Path(os.environ["CONNECTIONS_FILE"])
        connection_id = os.environ["CONNECTION_ID"]

        try:
            data = json.loads(path.read_text())
        except (OSError, json.JSONDecodeError) as error:
            print(f"tabularis-setup: cannot read {path}: {error}", file=sys.stderr)
            sys.exit(1)

        if isinstance(data, list):
            connections = data
        elif isinstance(data, dict):
            connections = data.get("connections")
        else:
            connections = None

        if not isinstance(connections, list):
            print("tabularis-setup: malformed connections config", file=sys.stderr)
            sys.exit(1)

        if not any(
            isinstance(connection, dict) and connection.get("id") == connection_id
            for connection in connections
        ):
            print(
                f"tabularis-setup: configured connection is missing: {connection_id}",
                file=sys.stderr,
            )
            sys.exit(1)
        PY

        secret="$(${pkgs.google-cloud-sdk}/bin/gcloud secrets versions access latest \
          --secret=gibbor-db-test-an-reader-password \
          --project=he-platform-prd \
          | tr -d '\n')"

        if [ -z "$secret" ]; then
          echo "tabularis-setup: fetched secret is empty for Gibbor" >&2
          exit 1
        fi

        if ! printf '%s' "$secret" \
          | ${pkgs.libsecret}/bin/secret-tool store \
            --label="Tabularis: Gibbor" \
            service tabularis \
            username "${connectionId}:db" \
            target default \
            application rust-keyring
        then
          unset secret
          echo "tabularis-setup: could not store the Gibbor password in the keyring" >&2
          exit 1
        fi

        unset secret

        if ! ${pkgs.libsecret}/bin/secret-tool lookup \
          service tabularis \
          username "${connectionId}:db" \
          target default \
          >/dev/null
        then
          echo "tabularis-setup: keyring verification failed for Gibbor" >&2
          exit 1
        fi

        echo "Tabularis is ready."
      '';
    in
    {
      home.packages = [
        pkgs.tabularis
        tabularisSetup
      ];

      xdg.configFile."tabularis/connections.json".source =
        config.lib.file.mkOutOfStoreSymlink connectionsFile;

      home.activation.tabularisConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        state_dir="$state_home/tabularis"
        connections_file="$state_dir/connections.json"

        install -d -m 700 "$state_dir"

        connections_tmp="$(mktemp "$state_dir/.connections.XXXXXX")"
        cleanup() {
          rm -f "$connections_tmp"
        }
        trap cleanup EXIT

        CONNECTIONS_FILE="$connections_file" \
          CONNECTIONS_OUTPUT="$connections_tmp" \
          DESIRED_CONNECTION='${desiredConnectionJson}' \
          ${pkgs.python3}/bin/python3 <<'PY'
        import json
        import os
        import sys
        from pathlib import Path

        connections_path = Path(os.environ["CONNECTIONS_FILE"])
        connections_output = Path(os.environ["CONNECTIONS_OUTPUT"])
        desired = json.loads(os.environ["DESIRED_CONNECTION"])

        if connections_path.exists():
            try:
                data = json.loads(connections_path.read_text())
            except (OSError, json.JSONDecodeError) as error:
                print(
                    f"tabularis activation: cannot read {connections_path}: {error}",
                    file=sys.stderr,
                )
                sys.exit(1)
        else:
            data = {}

        if isinstance(data, list):
            data = {"groups": [], "connections": data}
        if not isinstance(data, dict):
            print(
                "tabularis activation: connections config must be an object or array",
                file=sys.stderr,
            )
            sys.exit(1)

        connections = data.setdefault("connections", [])
        if not isinstance(connections, list):
            print("tabularis activation: 'connections' must be an array", file=sys.stderr)
            sys.exit(1)
        data.setdefault("groups", [])

        existing_index = next(
            (
                index
                for index, connection in enumerate(connections)
                if isinstance(connection, dict) and connection.get("id") == desired["id"]
            ),
            None,
        )

        if existing_index is None:
            merged = desired
            connections.append(merged)
        else:
            existing = connections[existing_index]
            existing_params = existing.get("params", {})
            if not isinstance(existing_params, dict):
                existing_params = {}

            merged = dict(existing)
            merged_params = dict(existing_params)
            merged_params.update(desired["params"])
            merged.update({key: value for key, value in desired.items() if key != "params"})
            merged["params"] = merged_params
            connections[existing_index] = merged

        merged["params"].pop("password", None)
        merged["params"].pop("ssh_password", None)
        merged["params"].pop("ssh_key_passphrase", None)

        connections_output.write_text(json.dumps(data, indent=2) + "\n")
        PY

        chmod 600 "$connections_tmp"
        mv "$connections_tmp" "$connections_file"
        trap - EXIT
      '';
    };
}
