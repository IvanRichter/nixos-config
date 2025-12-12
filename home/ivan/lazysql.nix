{ config, pkgs, lib, ... }:

let
  placeholder = "__LAZYSQL_PASSWORD__";
  empty = "''";

  lazysqlSetup = pkgs.writeShellScriptBin "lazysql-setup" ''
    set -euo pipefail

    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
    state_dir="$state_home/lazysql"
    config_file="$state_dir/config.toml"
    placeholder="${placeholder}"

    secret="$(${pkgs.google-cloud-sdk}/bin/gcloud secrets versions access latest \
      --secret=gibbor-db-test-an-reader-pw \
      --project=he-platform-prd \
      | tr -d '\n')"

    if [ -z "$secret" ]; then
      echo "lazysql-setup: fetched secret is empty" >&2
      exit 1
    fi

    if [ ! -f "$config_file" ]; then
      echo "lazysql-setup: config not found; run home-manager switch first" >&2
      exit 1
    fi

    tmp_config="$(mktemp)"
    cp "$config_file" "$tmp_config"
    chmod 600 "$tmp_config"

    SECRET="$secret" perl -0pi -e 's/__LAZYSQL_PASSWORD__/$ENV{SECRET}/g' "$tmp_config"

    if grep -q "$placeholder" "$tmp_config"; then
      echo "lazysql-setup: placeholder still present after substitution" >&2
      rm -f "$tmp_config"
      exit 1
    fi

    install -m 600 "$tmp_config" "$config_file"
    rm -f "$tmp_config"
  '';
in {
  home.packages = [
    lazysqlSetup
    pkgs.lazysql
  ];

  xdg.configFile."lazysql/config.toml".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.stateHome}/lazysql/config.toml";

  home.activation.lazysqlConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -euo pipefail

    state_home="''${XDG_STATE_HOME:-$HOME/.local/state}"
    state_dir="$state_home/lazysql"
    config_file="$state_dir/config.toml"
    placeholder="${placeholder}"

    if [ ! -f "$config_file" ]; then
      install -d -m 700 "$state_dir"
      cat > "$config_file" <<EOF
ConfigFile = '/home/ivan/.config/lazysql/config.toml'

[application]
DefaultPageSize = 300
DisableSidebar = false
SidebarOverlay = false
MaxQueryHistoryPerConnection = 100

[[database]]
Name = 'Gibbor Test CZ'
URL = 'mysql://an-reader:${placeholder}@www.gibbor.eu:3306/igibbor_test_cz'
Provider = 'mysql'
Username = ${empty}
Password = ${empty}
Hostname = ${empty}
Port = ${empty}
DBName = 'igibbor_test_cz'
URLParams = ${empty}
Commands = []
EOF
      chmod 600 "$config_file"
    fi
  '';
}
