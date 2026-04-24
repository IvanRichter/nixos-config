{
  config,
  pkgs,
  lib,
  ...
}:

let
  connectionId = "gibbor-mariadb";
  connectionName = "Gibbor";
  databaseHost = "www.gibbor.eu";
  databasePort = "3306";
  databaseName = "igibbor_test_cz";
  databaseUser = "an-reader";
  placeholder = "__DBEAVER_PASSWORD__";
  stateDir = "${config.xdg.stateHome}/dbeaver";
  renderedFile = "${stateDir}/data-sources-gibbor.json";
  mariadbDriverJar = "${pkgs.mariadb-connector-java}/share/java/mariadb-java-client.jar";
  dataSourcesTemplate = {
    folders = { };
    connections.${connectionId} = {
      provider = "mysql";
      driver = "mariaDB";
      name = connectionName;
      "save-password" = true;
      "show-system-objects" = true;
      configuration = {
        host = databaseHost;
        port = databasePort;
        database = databaseName;
        url = "jdbc:mariadb://${databaseHost}:${databasePort}/${databaseName}";
        user = databaseUser;
        password = placeholder;
        configurationType = "MANUAL";
        type = "dev";
      };
    };
  };
  dataSourcesTemplateJson = builtins.toJSON dataSourcesTemplate;
  mariadbDriverCache =
    pkgs.runCommandLocal "dbeaver-mariadb-driver-cache"
      {
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
            set -euo pipefail

            plugin_jar="$(find ${pkgs.dbeaver-bin}/opt/dbeaver/plugins -maxdepth 1 -name 'org.jkiss.dbeaver.ext.mysql_*.jar' | head -n1)"

            if [ -z "$plugin_jar" ]; then
              echo "dbeaver-mariadb-driver-cache: MariaDB plugin jar not found" >&2
              exit 1
            fi

            version="$(${pkgs.unzip}/bin/unzip -p "$plugin_jar" plugin.xml \
              | ${pkgs.python3}/bin/python3 -c '
        import re
        import sys

        match = re.search(
            r"path=\"maven:/org\.mariadb\.jdbc:mariadb-java-client:RELEASE\[([^\]]+)\]\"",
            sys.stdin.read(),
        )

        if match:
            print(match.group(1))
        ')"

            if [ -z "$version" ]; then
              echo "dbeaver-mariadb-driver-cache: MariaDB cache version not found in plugin metadata" >&2
              exit 1
            fi

            mkdir -p "$out"
            ln -s ${mariadbDriverJar} "$out/mariadb-java-client-$version.jar"
      '';

  dbeaverSetup = pkgs.writeShellScriptBin "dbeaver-setup" ''
        set -euo pipefail

        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        state_dir="$state_home/dbeaver"
        template_file="$state_dir/data-sources-gibbor.template.json"
        config_file="$state_dir/data-sources-gibbor.json"
        placeholder="${placeholder}"

        secret="$(${pkgs.google-cloud-sdk}/bin/gcloud secrets versions access latest \
          --secret=gibbor-test-db-an-reader-password \
          --project=he-platform-prd \
          | tr -d '\n')"

        if [ -z "$secret" ]; then
          echo "dbeaver-setup: fetched secret is empty" >&2
          exit 1
        fi

        if [ ! -f "$template_file" ]; then
          echo "dbeaver-setup: template not found; run home-manager switch first" >&2
          exit 1
        fi

        tmp_config="$(mktemp)"

        TEMPLATE_FILE="$template_file" \
          OUTPUT_FILE="$tmp_config" \
          SECRET="$secret" \
          PLACEHOLDER="$placeholder" \
          CONNECTION_ID="${connectionId}" \
          DESIRED_TEMPLATE='${dataSourcesTemplateJson}' \
          ${pkgs.python3}/bin/python3 <<'PY'
    import json
    import os
    import sys
    from pathlib import Path

    template_path = Path(os.environ["TEMPLATE_FILE"])
    output_path = Path(os.environ["OUTPUT_FILE"])
    placeholder = os.environ["PLACEHOLDER"]
    connection_id = os.environ["CONNECTION_ID"]
    desired_template = json.loads(os.environ["DESIRED_TEMPLATE"])
    desired_connection = desired_template["connections"][connection_id]
    desired_configuration = desired_connection["configuration"]

    template_raw = template_path.read_text()
    if placeholder not in template_raw:
        print("dbeaver-setup: placeholder missing from template", file=sys.stderr)
        sys.exit(1)

    template = json.loads(template_raw)
    connections = template.get("connections")

    if not isinstance(connections, dict):
        print("dbeaver-setup: malformed template, missing key: 'connections'", file=sys.stderr)
        sys.exit(1)

    if connection_id in connections:
        connection = connections[connection_id]
    elif len(connections) == 1:
        _, connection = connections.popitem()
        connections[connection_id] = connection
    else:
        print(f"dbeaver-setup: malformed template, missing key: '{connection_id}'", file=sys.stderr)
        sys.exit(1)

    if not isinstance(connection, dict):
        print(f"dbeaver-setup: malformed template, invalid connection: '{connection_id}'", file=sys.stderr)
        sys.exit(1)

    configuration = connection.get("configuration")
    if not isinstance(configuration, dict):
        configuration = {}

    connection.update({k: v for k, v in desired_connection.items() if k != "configuration"})
    configuration.update(desired_configuration)
    configuration["password"] = os.environ["SECRET"]
    connection["configuration"] = configuration

    output_path.write_text(json.dumps(template, indent=2) + "\n")
    PY

        chmod 600 "$tmp_config"
        install -m 600 "$tmp_config" "$config_file"
        rm -f "$tmp_config"
  '';
in
{
  home.packages = [
    dbeaverSetup
    pkgs.mariadb-connector-java
  ];

  xdg.dataFile."DBeaverData/workspace6/General/.dbeaver/data-sources-gibbor.json".source =
    config.lib.file.mkOutOfStoreSymlink renderedFile;

  # DBeaver's bundled MariaDB driver definition resolves a versioned Maven cache entry
  # Get cache filename from DBeaver's own plugin metadata so it stays in sync
  xdg.dataFile."DBeaverData/drivers/maven/maven-central/org.mariadb.jdbc" = {
    source = mariadbDriverCache;
    recursive = true;
  };

  home.activation.dbeaverConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
        state_dir="$state_home/dbeaver"
        template_file="$state_dir/data-sources-gibbor.template.json"
        config_file="$state_dir/data-sources-gibbor.json"
        drivers_config_dir="$data_home/DBeaverData/workspace6/.metadata/.config"
        drivers_config_file="$drivers_config_dir/drivers.xml"

        install -d -m 700 "$state_dir"
        install -d -m 700 "$drivers_config_dir"

        tmp_template="$(mktemp)"
        cat > "$tmp_template" <<'EOF'
    ${dataSourcesTemplateJson}
    EOF
        ${pkgs.python3}/bin/python3 -m json.tool "$tmp_template" "$template_file"
        chmod 600 "$template_file"
        rm -f "$tmp_template"

        if [ ! -f "$config_file" ]; then
          install -m 600 "$template_file" "$config_file"
        fi

        driver_version="$(${pkgs.unzip}/bin/unzip -p "$(find ${pkgs.dbeaver-bin}/opt/dbeaver/plugins -maxdepth 1 -name 'org.jkiss.dbeaver.ext.mysql_*.jar' | head -n1)" plugin.xml \
          | ${pkgs.python3}/bin/python3 -c '
    import re
    import sys

    match = re.search(
        r"path=\"maven:/org\.mariadb\.jdbc:mariadb-java-client:RELEASE\[([^\]]+)\]\"",
        sys.stdin.read(),
    )

    if match:
        print(match.group(1))
    ')"

        if [ -z "$driver_version" ]; then
          echo "dbeaver activation: MariaDB driver version not found in plugin metadata" >&2
          exit 1
        fi

        DRIVERS_CONFIG_FILE="$drivers_config_file" \
          DRIVER_VERSION="$driver_version" \
          ${pkgs.python3}/bin/python3 <<'PY'
    import os
    import xml.etree.ElementTree as ET
    from pathlib import Path

    drivers_config_file = Path(os.environ["DRIVERS_CONFIG_FILE"])
    driver_version = os.environ["DRIVER_VERSION"]
    driver_cache_path = (
        "''${drivers_home}/maven/maven-central/org.mariadb.jdbc/"
        f"mariadb-java-client-{driver_version}.jar"
    )

    if drivers_config_file.exists():
        tree = ET.parse(drivers_config_file)
        root = tree.getroot()
    else:
        root = ET.Element("drivers")
        tree = ET.ElementTree(root)

    provider = None
    for candidate in root.findall("provider"):
        if candidate.get("id") == "mysql":
            provider = candidate
            break

    if provider is None:
        provider = ET.SubElement(root, "provider", { "id": "mysql" })

    driver = None
    for candidate in provider.findall("driver"):
        if candidate.get("id") == "mariaDB":
            driver = candidate
            break

    driver_attrs = {
        "id": "mariaDB",
        "categories": "sql",
        "name": "MariaDB",
        "class": "org.mariadb.jdbc.Driver",
        "url": "jdbc:mariadb://{host}[:{port}]/[{database}]",
        "port": "3306",
        "defaultUser": "root",
        "description": "MariaDB JDBC driver",
        "custom": "false",
    }

    if driver is None:
        driver = ET.SubElement(provider, "driver", driver_attrs)
    else:
        driver.attrib.clear()
        driver.attrib.update(driver_attrs)
        for child in list(driver):
            driver.remove(child)

    library = ET.SubElement(driver, "library", {
        "type": "jar",
        "path": "maven:/org.mariadb.jdbc:mariadb-java-client:RELEASE",
        "custom": "false",
        "version": driver_version,
    })
    ET.SubElement(library, "file", {
        "id": "org.mariadb.jdbc:mariadb-java-client:RELEASE",
        "version": driver_version,
        "path": driver_cache_path,
    })
    ET.SubElement(driver, "library", {
        "type": "license",
        "path": "licenses/external/lgpl-2.1.txt",
        "custom": "false",
    })

    ET.indent(tree, space="  ")
    tree.write(drivers_config_file, encoding="UTF-8", xml_declaration=True)
    PY

        chmod 600 "$drivers_config_file"
  '';
}
