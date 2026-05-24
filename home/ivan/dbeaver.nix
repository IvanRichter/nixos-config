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
  mssqlConnectionId = "ao-exter-sqlserver";
  mssqlConnectionName = "Kentico";
  mssqlDatabaseHost = "185.193.67.134";
  mssqlDatabasePort = "65343";
  mssqlDatabaseName = "PROD_12_Replica";
  mssqlDatabaseUser = "AO3";
  mssqlDriverId = "microsoft-local";
  mssqlSecretName = "kentico-db-replica-ao3-password";
  mssqlRenderedFile = "${stateDir}/data-sources-ao-exter.json";
  mariadbDriverJar = "${pkgs.mariadb-connector-java}/share/java/mariadb-java-client.jar";
  mssqlDriverVersion = "13.4.0.jre11";
  mssqlDriverJar = pkgs.fetchurl {
    url = "https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${mssqlDriverVersion}/mssql-jdbc-${mssqlDriverVersion}.jar";
    hash = "sha256-429SN8EmeYPluI3CFp9rnX5Q7O7G3ByjEBjjh34Ur2Y=";
  };
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
  mssqlDataSourcesTemplate = {
    folders = { };
    connections.${mssqlConnectionId} = {
      provider = "sqlserver";
      driver = mssqlDriverId;
      name = mssqlConnectionName;
      "save-password" = true;
      "show-system-objects" = true;
      configuration = {
        host = mssqlDatabaseHost;
        port = mssqlDatabasePort;
        database = mssqlDatabaseName;
        url = "jdbc:sqlserver://${mssqlDatabaseHost}:${mssqlDatabasePort};database=${mssqlDatabaseName}";
        user = mssqlDatabaseUser;
        password = placeholder;
        configurationType = "MANUAL";
        type = "dev";
      };
    };
  };
  mssqlDataSourcesTemplateJson = builtins.toJSON mssqlDataSourcesTemplate;
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
  mssqlDriverCache = pkgs.runCommandLocal "dbeaver-mssql-driver-cache" { } ''
    set -euo pipefail

    mkdir -p "$out"
    ln -s ${mssqlDriverJar} "$out/mssql-jdbc-${mssqlDriverVersion}.jar"
  '';

  dbeaverSetup = pkgs.writeShellScriptBin "dbeaver-setup" ''
        set -euo pipefail

        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        state_dir="$state_home/dbeaver"
        placeholder="${placeholder}"

        render_connection() {
          local label="$1"
          local template_file="$2"
          local config_file="$3"
          local secret_name="$4"
          local project="$5"
          local connection_id="$6"
          local desired_template="$7"
          local secret
          local tmp_config

          secret="$(${pkgs.google-cloud-sdk}/bin/gcloud secrets versions access latest \
            --secret="$secret_name" \
            --project="$project" \
            | tr -d '\n')"

          if [ -z "$secret" ]; then
            echo "dbeaver-setup: fetched secret is empty for $label" >&2
            exit 1
          fi

          if [ ! -f "$template_file" ]; then
            echo "dbeaver-setup: template not found for $label; run home-manager switch first" >&2
            exit 1
          fi

          tmp_config="$(mktemp)"

          CONNECTION_LABEL="$label" \
            TEMPLATE_FILE="$template_file" \
            OUTPUT_FILE="$tmp_config" \
            SECRET="$secret" \
            PLACEHOLDER="$placeholder" \
            CONNECTION_ID="$connection_id" \
            DESIRED_TEMPLATE="$desired_template" \
            ${pkgs.python3}/bin/python3 <<'PY'
    import json
    import os
    import sys
    from pathlib import Path

    connection_label = os.environ["CONNECTION_LABEL"]
    template_path = Path(os.environ["TEMPLATE_FILE"])
    output_path = Path(os.environ["OUTPUT_FILE"])
    placeholder = os.environ["PLACEHOLDER"]
    connection_id = os.environ["CONNECTION_ID"]
    desired_template = json.loads(os.environ["DESIRED_TEMPLATE"])
    desired_connection = desired_template["connections"][connection_id]
    desired_configuration = desired_connection["configuration"]

    template_raw = template_path.read_text()
    if placeholder not in template_raw:
        print(f"dbeaver-setup: placeholder missing from template for {connection_label}", file=sys.stderr)
        sys.exit(1)

    template = json.loads(template_raw)
    connections = template.get("connections")

    if not isinstance(connections, dict):
        print(f"dbeaver-setup: malformed template for {connection_label}, missing key: 'connections'", file=sys.stderr)
        sys.exit(1)

    if connection_id in connections:
        connection = connections[connection_id]
    elif len(connections) == 1:
        _, connection = connections.popitem()
        connections[connection_id] = connection
    else:
        print(f"dbeaver-setup: malformed template for {connection_label}, missing key: '{connection_id}'", file=sys.stderr)
        sys.exit(1)

    if not isinstance(connection, dict):
        print(f"dbeaver-setup: malformed template for {connection_label}, invalid connection: '{connection_id}'", file=sys.stderr)
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
        }

        render_connection \
          "Gibbor" \
          "$state_dir/data-sources-gibbor.template.json" \
          "$state_dir/data-sources-gibbor.json" \
          "gibbor-db-test-an-reader-password" \
          "he-platform-prd" \
          "${connectionId}" \
          '${dataSourcesTemplateJson}'

        render_connection \
          "${mssqlConnectionName}" \
          "$state_dir/data-sources-ao-exter.template.json" \
          "$state_dir/data-sources-ao-exter.json" \
          "${mssqlSecretName}" \
          "he-platform-prd" \
          "${mssqlConnectionId}" \
          '${mssqlDataSourcesTemplateJson}'
  '';
in
{
  home.packages = [
    dbeaverSetup
    pkgs.mariadb-connector-java
  ];

  xdg.dataFile."DBeaverData/workspace6/General/.dbeaver/data-sources-gibbor.json".source =
    config.lib.file.mkOutOfStoreSymlink renderedFile;
  xdg.dataFile."DBeaverData/workspace6/General/.dbeaver/data-sources-ao-exter.json".source =
    config.lib.file.mkOutOfStoreSymlink mssqlRenderedFile;

  # DBeaver's bundled MariaDB driver definition resolves a versioned Maven cache entry
  # Get cache filename from DBeaver's own plugin metadata so it stays in sync
  xdg.dataFile."DBeaverData/drivers/maven/maven-central/org.mariadb.jdbc" = {
    source = mariadbDriverCache;
    recursive = true;
  };
  xdg.dataFile."DBeaverData/drivers/maven/maven-central/com.microsoft.sqlserver" = {
    source = mssqlDriverCache;
    recursive = true;
  };

  home.activation.dbeaverConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -euo pipefail

        state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
        data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
        state_dir="$state_home/dbeaver"
        gibbor_template_file="$state_dir/data-sources-gibbor.template.json"
        gibbor_config_file="$state_dir/data-sources-gibbor.json"
        mssql_template_file="$state_dir/data-sources-ao-exter.template.json"
        mssql_config_file="$state_dir/data-sources-ao-exter.json"
        drivers_config_dir="$data_home/DBeaverData/workspace6/.metadata/.config"
        drivers_config_file="$drivers_config_dir/drivers.xml"
        core_prefs_dir="$data_home/DBeaverData/workspace6/.metadata/.plugins/org.eclipse.core.runtime/.settings"
        core_prefs_file="$core_prefs_dir/org.jkiss.dbeaver.core.prefs"

        install -d -m 700 "$state_dir"
        install -d -m 700 "$drivers_config_dir"
        install -d -m 700 "$core_prefs_dir"

        write_template() {
          local template_json="$1"
          local template_file="$2"
          local config_file="$3"
          local tmp_template

          tmp_template="$(mktemp)"
          printf '%s\n' "$template_json" > "$tmp_template"
          ${pkgs.python3}/bin/python3 -m json.tool "$tmp_template" "$template_file"
          chmod 600 "$template_file"
          rm -f "$tmp_template"

          if [ ! -f "$config_file" ]; then
            install -m 600 "$template_file" "$config_file"
          fi
        }

        write_template '${dataSourcesTemplateJson}' "$gibbor_template_file" "$gibbor_config_file"
        write_template '${mssqlDataSourcesTemplateJson}' "$mssql_template_file" "$mssql_config_file"

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
          DRIVERS_HOME="$data_home/DBeaverData/drivers" \
          DRIVER_VERSION="$driver_version" \
          MSSQL_DRIVER_ID="${mssqlDriverId}" \
          MSSQL_DRIVER_VERSION="${mssqlDriverVersion}" \
          ${pkgs.python3}/bin/python3 <<'PY'
    import os
    import xml.etree.ElementTree as ET
    from pathlib import Path

    drivers_config_file = Path(os.environ["DRIVERS_CONFIG_FILE"])
    drivers_home = os.environ["DRIVERS_HOME"]
    driver_version = os.environ["DRIVER_VERSION"]
    mssql_driver_id = os.environ["MSSQL_DRIVER_ID"]
    mssql_driver_version = os.environ["MSSQL_DRIVER_VERSION"]
    driver_cache_path = (
        f"{drivers_home}/maven/maven-central/org.mariadb.jdbc/"
        f"mariadb-java-client-{driver_version}.jar"
    )
    mssql_driver_cache_path = (
        f"{drivers_home}/maven/maven-central/com.microsoft.sqlserver/"
        f"mssql-jdbc-{mssql_driver_version}.jar"
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

    provider = None
    for candidate in root.findall("provider"):
        if candidate.get("id") == "sqlserver":
            provider = candidate
            break

    if provider is None:
        provider = ET.SubElement(root, "provider", { "id": "sqlserver" })

    for candidate in list(provider.findall("driver")):
        if candidate.get("id") != "microsoft":
            continue

        library_paths = {library.get("path") for library in candidate.findall("library")}
        if (
            "maven:/com.microsoft.sqlserver:mssql-jdbc:RELEASE" in library_paths
            and mssql_driver_cache_path in library_paths
        ):
            provider.remove(candidate)

    driver = None
    for candidate in provider.findall("driver"):
        if candidate.get("id") == mssql_driver_id:
            driver = candidate
            break

    driver_attrs = {
        "id": mssql_driver_id,
        "categories": "sql",
        "name": "SQL Server (local)",
        "class": "com.microsoft.sqlserver.jdbc.SQLServerDriver",
        "url": "jdbc:sqlserver://{host}[:{port}][;databaseName={database}]",
        "port": "1433",
        "defaultDatabase": "master",
        "description": "Microsoft JDBC Driver for SQL Server from the local Nix-provided jar",
        "custom": "true",
    }

    if driver is None:
        driver = ET.SubElement(provider, "driver", driver_attrs)
    else:
        driver.attrib.clear()
        driver.attrib.update(driver_attrs)
        for child in list(driver):
            driver.remove(child)

    ET.SubElement(driver, "library", {
        "type": "jar",
        "path": mssql_driver_cache_path,
        "custom": "true",
        "version": mssql_driver_version,
    })

    ET.indent(tree, space="  ")
    tree.write(drivers_config_file, encoding="UTF-8", xml_declaration=True)
    PY

        chmod 600 "$drivers_config_file"

        CORE_PREFS_FILE="$core_prefs_file" \
          MSSQL_DRIVER_JAR="$data_home/DBeaverData/drivers/maven/maven-central/com.microsoft.sqlserver/mssql-jdbc-${mssqlDriverVersion}.jar" \
          ${pkgs.python3}/bin/python3 <<'PY'
    import os
    from pathlib import Path

    prefs_file = Path(os.environ["CORE_PREFS_FILE"])
    driver_jar = os.environ["MSSQL_DRIVER_JAR"]
    key = "ui.drivers.global.libraries"

    lines = []
    if prefs_file.exists():
        lines = prefs_file.read_text().splitlines()

    prefs = {}
    order = []
    for line in lines:
        if "=" in line:
            name, value = line.split("=", 1)
            prefs[name] = value
            order.append(name)

    libraries = [item for item in prefs.get(key, "").split("|") if item and item != driver_jar]
    if libraries:
        prefs[key] = "|".join(libraries)
    else:
        prefs.pop(key, None)

    if "eclipse.preferences.version" not in prefs:
        order.insert(0, "eclipse.preferences.version")
        prefs["eclipse.preferences.version"] = "1"

    seen = set()
    output = []
    for name in order:
        if name in seen or name not in prefs:
            continue
        seen.add(name)
        output.append(f"{name}={prefs[name]}")

    prefs_file.write_text("\n".join(output) + "\n")
    PY

        chmod 600 "$core_prefs_file"
  '';
}
