{
  config,
  lib,
  pkgs,
  ...
}:

let
  codeBin = "${config.programs.vscode.package}/bin/code";
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [
      "clippy"
      "rust-src"
      "rustfmt"
    ];
  };

  # Extensions in nixpkgs
  nixpkgsExtensions = with pkgs.vscode-extensions; [
    astro-build.astro-vscode
    jeff-hykin.better-nix-syntax
    bradlc.vscode-tailwindcss
    catppuccin.catppuccin-vsc-icons
    docker.docker
    eamodio.gitlens
    esbenp.prettier-vscode
    github.copilot
    github.copilot-chat
    hashicorp.terraform
    jnoortheen.nix-ide
    mads-hartmann.bash-ide-vscode
    ms-azuretools.vscode-containers
    ms-azuretools.vscode-docker
    mechatroner.rainbow-csv
    oderwat.indent-rainbow
    ms-vscode-remote.remote-containers
    ritwickdey.liveserver
    rust-lang.rust-analyzer
    shd101wyy.markdown-preview-enhanced
    tamasfe.even-better-toml
    timonwong.shellcheck
    unifiedjs.vscode-mdx
    usernamehw.errorlens
    vue.volar
    wgsl-analyzer.wgsl-analyzer
    ms-python.python
    ms-toolsai.jupyter
    ms-python.vscode-pylance
    golang.go
    zhuangtongfa.material-theme
  ];

  # Marketplace-only extensions
  marketplaceExtensions = [
    "adrianwilczynski.alpine-js-intellisense"
    "ashishalex.dataform-lsp-vscode"
    "bruno-api-client.bruno"
    "dustypomerleau.rust-syntax"
    "googlecloudtools.cloudcode"
    "macabeus.vscode-fluent"
    "openai.chatgpt"
    "risingstack.astro-alpinejs-syntax-highlight"
    "sqlfluff.vscode-sqlfluff"
  ];

in
{
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;

    # Let the fallback CLI write to the extensions dir
    mutableExtensionsDir = true;

    profiles.default = {
      extensions = nixpkgsExtensions;

      userSettings = {
        "telemetry.telemetryLevel" = "off";
        "security.workspace.trust.untrustedFiles" = "open";
        "terminal.integrated.fontFamily" = "MesloLGS Nerd Font";
        "terminal.integrated.defaultProfile.linux" = "fish";
        "terminal.integrated.gpuAcceleration" = "on";
        "terminal.integrated.cursorBlinking" = true;
        "terminal.integrated.shellIntegration.enabled" = false;
        "terminal.integrated.enableImages" = false;
        "terminal.integrated.smoothScrolling" = false;
        "terminal.integrated.fastScrollSensitivity" = 5;
        "terminal.integrated.profiles.linux" = {
          fish = {
            path = "/run/current-system/sw/bin/fish";
          };
        };

        "vscode-dataform-tools.formattingCli" = "sqlfluff";
        "vscode-dataform-tools.sqlfluffConfigPath" = "./.sqlfluff";
        "workbench.iconTheme" = "catppuccin-macchiato";
        "workbench.sideBar.location" = "right";
        "workbench.editor.closeOnFileDelete" = true;
        "vsicons.dontShowNewVersionMessage" = true;

        "files.associations" = {
          "cloudbuild.yaml" = "yaml";
          "*.bash" = "shellscript";
          "*.sh" = "shellscript";
        };

        "search.useIgnoreFiles" = true;
        "search.useGlobalIgnoreFiles" = true;
        "search.showLineNumbers" = true;
        "search.smartCase" = true;
        "search.exclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
          "**/dist/**" = true;
          "**/.direnv/**" = true;
        };
        "files.watcherExclude" = {
          "**/.git/objects/**" = true;
          "**/.git/subtree-cache/**" = true;
          "**/node_modules/**" = true;
          "**/target/**" = true;
          "**/dist/**" = true;
          "**/.direnv/**" = true;
        };

        "github.copilot.nextEditSuggestions.enabled" = true;
        "cloudcode.project" = "happy-end-data-warehouse";
        "cloudcode.beta.bigqueryRegion" = "eu";

        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.formatOnSave" = true;
        "editor.cursorBlinking" = "phase";
        "editor.cursorSmoothCaretAnimation" = "on";
        "editor.inlayHints.enabled" = "offUnlessPressed";
        "indentRainbow.indicatorStyle" = "light";
        "typescript.updateImportsOnFileMove.enabled" = "always";
        "[nix]" = {
          "editor.defaultFormatter" = "jnoortheen.nix-ide";
        };
        "[sql]" = {
          "editor.defaultFormatter" = "sqlfluff.vscode-sqlfluff";
          "editor.formatOnSave" = true;
        };
        "[sqlx]" = {
          "editor.defaultFormatter" = "ashishalex.dataform-lsp-vscode";
          "editor.formatOnSave" = true;
        };
        "[rust]" = {
          "editor.defaultFormatter" = "rust-lang.rust-analyzer";
          "editor.formatOnSave" = true;
        };
        "rust-analyzer.checkOnSave" = false;
        "rust-analyzer.cargo.buildScripts.enable" = false;
        "rust-analyzer.cargo.targetDir" = "${config.xdg.cacheHome}/rust-analyzer/target";
        "rust-analyzer.procMacro.enable" = false;
        "rust-analyzer.rustfmt.overrideCommand" = [
          "${rustToolchain}/bin/rustfmt"
          "--edition"
          "2024"
        ];
        "nix.formatterPath" = "${pkgs.nixfmt}/bin/nixfmt";
        "editor.fontFamily" =
          "'JetBrainsMono Nerd Font', 'MesloLGS Nerd Font', 'Droid Sans Mono', 'monospace'";
        "workbench.colorTheme" = "One Dark Pro Night Flat";

        "extensions.autoUpdate" = true;
        "extensions.autoCheckUpdates" = true;

        "geminicodeassist.enableTelemetry" = false;

        "vscode-dataform-tools.gcpProjectId" = "he-dlh-prd";
        "vscode-dataform-tools.gcpLocation" = "europe-west1";
        "vscode-dataform-tools.currencyFoDryRunCost" = "EUR";
      };
    };
  };

  # Install marketplace-only extensions if missing
  home.activation.vscodeFallbackExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    set -eu

    INSTALLED="$(${codeBin} --list-extensions || true)"

    for ext in ${lib.concatStringsSep " " (map lib.escapeShellArg marketplaceExtensions)}; do
      if ! echo "$INSTALLED" | grep -qx "$ext"; then
        echo "Installing VS Code marketplace extension: $ext"
        ${codeBin} --install-extension "$ext"
      else
        echo "VS Code extension already installed: $ext"
      fi
    done
  '';
}
