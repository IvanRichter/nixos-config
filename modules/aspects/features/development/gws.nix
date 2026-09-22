{ den, ... }:

{
  den.aspects.gws.homeManager =
    { lib, pkgs, ... }:

    let
      project = "he-platform-prd";
      secret = "gws-oauth-client";
      scopes = [
        "https://www.googleapis.com/auth/drive"
        "https://www.googleapis.com/auth/spreadsheets"
        "https://www.googleapis.com/auth/documents"
        "https://www.googleapis.com/auth/presentations"
      ];

      gwsSetup = pkgs.writeShellApplication {
        name = "gws-setup";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.google-cloud-sdk
          pkgs.gws
          pkgs.jq
        ];
        text = ''
          if [ "$#" -gt 0 ]; then
            case "$1" in
              -h|--help)
                echo "Usage: gws-setup"
                echo "Fetch ${secret} from ${project} and authorize gws with your Google account."
                echo "Uses ~/.config/gws unless GOOGLE_WORKSPACE_CLI_CONFIG_DIR is set."
                echo "Uses isolated HE gcloud credentials and leaves ADC unchanged."
                exit 0
                ;;
              *)
                echo "gws-setup: unexpected argument: $1" >&2
                exit 1
                ;;
            esac
          fi

          for override in GOOGLE_WORKSPACE_CLI_TOKEN GOOGLE_WORKSPACE_CLI_CREDENTIALS_FILE \
            GOOGLE_WORKSPACE_CLI_CLIENT_ID GOOGLE_WORKSPACE_CLI_CLIENT_SECRET; do
            if [[ -v "$override" ]]; then
              echo "gws-setup: unset $override while configuring the saved HE login" >&2
              exit 1
            fi
          done

          config_home="''${XDG_CONFIG_HOME:-$HOME/.config}"
          export CLOUDSDK_CONFIG="''${HE_CLOUDSDK_CONFIG:-$config_home/gcloud-happyend}"
          unset CLOUDSDK_CORE_ACCOUNT
          export CLOUDSDK_CORE_PROJECT=${lib.escapeShellArg project}
          export CLOUDSDK_BILLING_QUOTA_PROJECT=${lib.escapeShellArg project}
          export GOOGLE_CLOUD_PROJECT=${lib.escapeShellArg project}
          export GOOGLE_CLOUD_QUOTA_PROJECT=${lib.escapeShellArg project}
          export GOOGLE_WORKSPACE_CLI_CONFIG_DIR="''${GOOGLE_WORKSPACE_CLI_CONFIG_DIR:-$HOME/.config/gws}"
          export GOOGLE_WORKSPACE_PROJECT_ID=${lib.escapeShellArg project}
          client_file="$GOOGLE_WORKSPACE_CLI_CONFIG_DIR/client_secret.json"

          confirm_login() {
            local answer
            if [ ! -t 0 ]; then
              echo "gws-setup: authentication is needed; run gws-setup in an interactive terminal" >&2
              return 1
            fi
            read -r -p "$1 [Y/n] " answer || return 1
            case "$answer" in
              ""|y|Y|yes|Yes|YES) return 0 ;;
              *) return 1 ;;
            esac
          }

          valid_client() {
            jq -e --arg project ${lib.escapeShellArg project} '
              .installed
              | .project_id == $project
                and (.client_id | type == "string" and length > 0)
                and (.client_secret | type == "string" and length > 0)
                and .auth_uri == "https://accounts.google.com/o/oauth2/auth"
                and .token_uri == "https://oauth2.googleapis.com/token"
            ' "$1" >/dev/null 2>&1
          }

          if [ -L "$client_file" ] || { [ -e "$client_file" ] && ! valid_client "$client_file"; }; then
            echo "gws-setup: existing client configuration was preserved; select a separate GOOGLE_WORKSPACE_CLI_CONFIG_DIR" >&2
            exit 1
          fi

          umask 077
          install -d -m 700 "$CLOUDSDK_CONFIG" "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR"

          if ! gcloud auth print-access-token >/dev/null 2>&1; then
            confirm_login "Sign in to Google Cloud to access the gws client?" || exit 1
            gcloud auth login --force --project=${lib.escapeShellArg project}
          fi

          setup_dir="$(mktemp -d "$GOOGLE_WORKSPACE_CLI_CONFIG_DIR/.setup.XXXXXX")"
          trap 'rm -rf "$setup_dir"' EXIT
          client_tmp="$setup_dir/client_secret.json"

          gcloud secrets versions access latest \
            --secret=${lib.escapeShellArg secret} \
            --project=${lib.escapeShellArg project} \
            --out-file="$client_tmp" >/dev/null

          if ! valid_client "$client_tmp"; then
            echo "gws-setup: the secret must contain a Desktop OAuth client JSON for ${project}" >&2
            exit 1
          fi

          if [ -f "$client_file" ] && ! jq -e -s \
            '.[0].installed.client_id == .[1].installed.client_id' \
            "$client_file" "$client_tmp" >/dev/null 2>&1; then
            echo "gws-setup: an existing different OAuth client was preserved; select a separate GOOGLE_WORKSPACE_CLI_CONFIG_DIR" >&2
            exit 1
          fi

          chmod 600 "$client_tmp"
          mv -f "$client_tmp" "$client_file"
          echo "Shared gws client configured in $GOOGLE_WORKSPACE_CLI_CONFIG_DIR."

          authenticated() {
            gws auth status >"$setup_dir/auth-status.json" 2>/dev/null \
              && jq -e \
                --arg project ${lib.escapeShellArg project} \
                --argjson scopes ${lib.escapeShellArg (builtins.toJSON scopes)} '
                  .token_valid == true and .project_id == $project
                  and (.user | type == "string" and length > 0)
                  and (($scopes - (.scopes // [])) | length == 0)
                ' "$setup_dir/auth-status.json" >/dev/null 2>&1
          }

          if ! authenticated; then
            confirm_login "Authorize gws for Drive, Sheets, Docs, and Slides?" || exit 1
            gws auth login --scopes ${lib.escapeShellArg (lib.concatStringsSep "," scopes)}
            if ! authenticated; then
              echo "gws-setup: could not verify the saved login and all four requested Workspace scopes" >&2
              exit 1
            fi
          fi

          gws_account="$(jq -r '.user' "$setup_dir/auth-status.json")"
          echo "gws is ready for $gws_account in ${project}."
        '';
      };
    in
    {
      home.packages = [
        pkgs.gws
        gwsSetup
      ];
    };
}
