{ den, inputs, ... }:

{
  den.aspects.tabularis.nixpkgs-overlays = _: {
    tabularis = import "${inputs.self}/overlays/development/tabularis.nix";
  };

  den.aspects.tabularis.homeManager =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    let
      stateDir = "${config.xdg.stateHome}/tabularis";
      connectionsFile = "${stateDir}/connections.json";
      connections = [
        {
          id = "gibbor-mariadb";
          name = "Gibbor";
          secretName = "gibbor-db-test-an-reader-password";
          params = {
            driver = "mysql";
            host = "www.gibbor.eu";
            port = 3306;
            username = "an-reader";
            database = [
              "igibbor_test_cz"
              "happyend_cz"
              "happyend_sk"
              "igibbor_test_pl"
              "igibbor_test_sk"
              "information_schema"
            ];
            ssl_mode = "verify_ca";
            ssl_ca = "${stateDir}/gibbor-ca.pem";
            ssh_enabled = false;
            save_in_keychain = true;
          };
        }
        {
          id = "ao-exter-sqlserver";
          name = "Kentico";
          secretName = "kentico-db-replica-ao3-password";
          params = {
            driver = "sqlserver";
            host = "185.193.67.134";
            port = 65343;
            username = "AO3";
            database = "PROD_12_Replica";
            # Kentico uses a self-signed certificate, require encrypted transport
            ssl_mode = "require";
            ssh_enabled = false;
            save_in_keychain = true;
          };
        }
      ];
      desiredConnectionsJson = builtins.toJSON (
        map (connection: builtins.removeAttrs connection [ "secretName" ]) connections
      );

      tabularisSetup = pkgs.writeShellApplication {
        name = "tabularis-setup";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.google-cloud-sdk
          pkgs.libsecret
          pkgs.openssl
          pkgs.python3
        ];
        text = ''
          umask 077

          config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
          connections_file="$config_home/tabularis/connections.json"

          if [[ ! -f $connections_file ]]; then
            echo "tabularis-setup: connections config not found; run home-manager switch first" >&2
            exit 1
          fi

          CONNECTIONS_FILE="$connections_file" \
            DESIRED_CONNECTIONS=${lib.escapeShellArg desiredConnectionsJson} \
            python3 <<'PY'
          import json
          import os
          import sys
          from pathlib import Path

          path = Path(os.environ["CONNECTIONS_FILE"])
          desired_connections = json.loads(os.environ["DESIRED_CONNECTIONS"])

          try:
              data = json.loads(path.read_text(encoding="utf-8"))
          except (OSError, json.JSONDecodeError) as error:
              sys.exit(f"tabularis-setup: cannot read {path}: {error}")

          match data:
              case list() as connections:
                  pass
              case {"connections": list() as connections}:
                  pass
              case _:
                  sys.exit("tabularis-setup: malformed connections config")

          existing_ids = {
              connection.get("id")
              for connection in connections
              if isinstance(connection, dict)
          }
          for desired in desired_connections:
              if desired["id"] not in existing_ids:
                  sys.exit(
                      f"tabularis-setup: configured connection is missing: {desired['id']}"
                  )
          PY

          state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
          state_dir="$state_home/tabularis"
          install -d -m 700 "$state_dir"

          ca_tmp="''${ mktemp "$state_dir/.gibbor-ca.XXXXXX";}"
          trap 'rm -f -- "$ca_tmp"' EXIT

          # This CA also signs the test server's certificate - no client key needed
          gcloud secrets versions access latest \
            --project=he-dlh-prd \
            --secret=gibbor-db-prd-backup-ca \
            --out-file="$ca_tmp"
          openssl x509 -in "$ca_tmp" -noout
          chmod 600 "$ca_tmp"
          mv -f "$ca_tmp" "$state_dir/gibbor-ca.pem"
          trap - EXIT

          store_password() {
            local connection_id="$1"
            local label="$2"
            local secret_name="$3"
            local secret

            secret="''${ gcloud secrets versions access latest \
              --secret="$secret_name" \
              --project=he-platform-prd;}"
            secret="''${secret//$'\n'/}"

            if [[ -z $secret ]]; then
              echo "tabularis-setup: fetched secret is empty for $label" >&2
              exit 1
            fi

            if ! printf '%s' "$secret" |
              secret-tool store \
                --label="Tabularis: $label" \
                service tabularis \
                username "$connection_id:db" \
                target default \
                application rust-keyring; then
              unset secret
              echo "tabularis-setup: could not store the $label password in the keyring" >&2
              exit 1
            fi

            unset secret

            if ! secret-tool lookup \
              service tabularis \
              username "$connection_id:db" \
              target default \
              >/dev/null; then
              echo "tabularis-setup: keyring verification failed for $label" >&2
              exit 1
            fi
          }

          ${lib.concatMapStringsSep "\n" (connection: ''
            store_password ${
              lib.escapeShellArgs [
                connection.id
                connection.name
                connection.secretName
              ]
            }
          '') connections}

          echo "Tabularis is ready."
        '';
      };
    in
    {
      home.packages = [
        pkgs.tabularis
        tabularisSetup
      ];

      xdg.configFile."tabularis/connections.json".source =
        config.lib.file.mkOutOfStoreSymlink connectionsFile;

      # Discovery requires real dirs, HM links the individual files
      xdg.dataFile."tabularis/plugins/drivers/sqlserver" = {
        source = "${pkgs.tabularis-sqlserver-plugin}/share/tabularis/plugins/sqlserver";
        recursive = true;
      };

      home.activation.tabularisConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        state_dir="$state_home/tabularis"
        connections_file="$state_dir/connections.json"

        install -d -m 700 "$state_dir"

        connections_tmp="''${ mktemp "$state_dir/.connections.XXXXXX";}"
        trap 'rm -f -- "$connections_tmp"' EXIT

        CONNECTIONS_FILE="$connections_file" \
          CONNECTIONS_OUTPUT="$connections_tmp" \
          DESIRED_CONNECTIONS=${lib.escapeShellArg desiredConnectionsJson} \
          ${lib.getExe pkgs.python3} <<'PY'
        import json
        import os
        import sys
        from pathlib import Path

        connections_path = Path(os.environ["CONNECTIONS_FILE"])
        connections_output = Path(os.environ["CONNECTIONS_OUTPUT"])
        desired_connections = json.loads(os.environ["DESIRED_CONNECTIONS"])

        try:
            data = json.loads(connections_path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            data = {}
        except (OSError, json.JSONDecodeError) as error:
            sys.exit(f"tabularis activation: cannot read {connections_path}: {error}")

        match data:
            case list():
                data = {"groups": [], "connections": data}
            case dict():
                pass
            case _:
                sys.exit("tabularis activation: connections config must be an object or array")

        connections = data.setdefault("connections", [])
        if not isinstance(connections, list):
            sys.exit("tabularis activation: 'connections' must be an array")
        data.setdefault("groups", [])

        for desired in desired_connections:
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

                merged = existing | desired | {"params": existing_params | desired["params"]}
                connections[existing_index] = merged

            merged["params"].pop("password", None)
            merged["params"].pop("ssh_password", None)
            merged["params"].pop("ssh_key_passphrase", None)

        connections_output.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        connections_output.chmod(0o600)
        connections_output.move(connections_path)
        PY

        trap - EXIT
      '';
    };
}
